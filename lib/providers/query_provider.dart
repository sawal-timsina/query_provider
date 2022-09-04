import 'package:flutter/widgets.dart'
    show AsyncSnapshot, ConnectionState, Key, StreamBuilder, debugPrint;
import 'package:get_it/get_it.dart' show GetIt;
import 'package:rxdart/rxdart.dart' show BehaviorSubject, ValueStream;

import '../behaviours/behaviour.dart' show Behaviour, BehaviourContext;
import '../behaviours/infinite_query_behaviour.dart'
    show InfiniteQueryBehaviour, InfiniteQueryParams;
import '../behaviours/query_behaviour.dart' show QueryBehaviour;
import '../converters/converter_not_found.dart';
import '../models/meta.dart';
import '../models/params.dart' show Params;
import '../models/query_context.dart' show QueryContext;
import '../models/query_object.dart' show BaseQueryObject, InfiniteQuery, Query;
import '../providers/base_provider.dart' show BaseProvider;
import '../types.dart' show QueryFunction;
import '../utils/cache_manager.dart' show CacheManager;

abstract class _BaseQueryProvider<
    QueryMeta extends BaseQueryMeta,
    QueryType extends BaseQueryObject,
    Res extends dynamic,
    Data extends dynamic> {
  final CacheManager _cacheManager = GetIt.instance.get<CacheManager>();
  late final Behaviour<QueryMeta, QueryType, Res, Data> _behaviour;

  String _queryKey = "";
  bool _enabled = true;

  late final String _query;
  late Params? _params;

  late final BehaviorSubject<QueryType> _data;

  ValueStream<QueryType> get stream => _data.stream;

  Data? get data => stream.value.data;

  bool get hasValue => _data.hasValue;

  bool get isLoading => _data.value.isLoading;

  bool get isError => _data.value.isError;

  bool get _hasCacheValue => _cacheManager.containsKey(_queryKey);

  final QueryFunction<Res> _queryFn;

  dynamic Function(Res)? _select;

  void Function(Data data)? onSuccess;
  void Function(Exception error)? onError;

  // meta get function
  late final QueryMeta Function(QueryMeta? meta) _onInit;
  late final QueryMeta Function(QueryMeta? meta) _onCache;
  late final QueryMeta Function(QueryMeta? meta) _onForceRefresh;
  late final QueryMeta Function(QueryMeta? meta) _onFetched;
  late final QueryMeta Function(QueryMeta? meta) _onError;

  _BaseQueryProvider(
    this._behaviour,
    this._query,
    this._queryFn, {
    Params? params,
    bool fetchOnMount = true,
    this.onSuccess,
    this.onError,
    Function(Res)? select,
    bool enabled = true,
    QueryMeta? meta,
    required QueryMeta Function(QueryMeta? meta) onInit,
    required QueryMeta Function(QueryMeta? meta) onCache,
    required QueryMeta Function(QueryMeta? meta) onForceRefresh,
    required QueryMeta Function(QueryMeta? meta) onFetched,
    required QueryMeta Function(QueryMeta? meta) onErrorM,
  }) {
    _select = select;

    // meta function
    _onInit = onInit;
    _onCache = onCache;
    _onForceRefresh = onForceRefresh;
    _onFetched = onFetched;
    _onError = onErrorM;

    _enabled = enabled;
    _params = params;
    _setQueryKey(params);

    dynamic cacheData;
    if (_hasCacheValue) {
      cacheData = _behaviour.parseData(_cacheManager.get(_queryKey));
    }

    _data = BehaviorSubject.seeded(_behaviour.getNewData(
      isLoading: cacheData == null,
      isError: false,
      data: cacheData,
      meta: _onInit(meta),
    ));

    if (fetchOnMount) {
      _fetch(readFromCache: false);
    }
  }

  void _setQueryKey(Params? params) =>
      _queryKey = [_query, params?.toJson()].toString();

  Future refetch() {
    return _fetch(forceRefresh: true);
  }

  Future _fetch({
    bool forceRefresh = false,
    bool readFromCache = true,
    QueryContext? queryContext,
    QueryMeta? meta,
  }) async {
    if (_enabled) {
      final queryKey = _queryKey;
      final forceRefresh_ = forceRefresh ? forceRefresh : !_hasCacheValue;
      if (!forceRefresh_ && readFromCache) {
        try {
          final cacheData = _behaviour.parseData(_cacheManager.get(queryKey));

          _data.add(
            _behaviour.getNewData(
                isLoading: false,
                isError: false,
                data: cacheData,
                meta: _onCache(meta)),
          );
        } catch (e) {
          debugPrint(
              e is ConverterNotFountException ? e.message : e.toString());
        }
      } else {
        _data.add(
          _behaviour.getNewData(
              isLoading: !_hasCacheValue,
              isError: false,
              data: hasValue ? data : null,
              meta: _onForceRefresh(meta)),
        );
      }

      try {
        final query = _query;
        final paramsC = params?.clone();
        final parsedData = await _behaviour.onFetch(
          BehaviourContext<Res, Data>(
            _queryFn,
            queryKey,
            QueryContext(
              queryKey: [query, paramsC],
              pageParam: queryContext?.pageParam,
            ),
            _select,
            data,
            forceRefresh_,
          ),
        );

        // no need to add data to stream if key has been changed
        if (queryKey == _queryKey) {
          _data.add(
            _behaviour.getNewData(
                isLoading: false,
                isError: false,
                data: parsedData,
                meta: _onFetched(meta)),
          );
        }
        _cacheManager.set(queryKey, parsedData);
        if (onSuccess != null) onSuccess!(parsedData!);
        // TODO :: add params to query cache
      } on Exception catch (e) {
        _data.add(
          _behaviour.getNewData(
            isLoading: false,
            isError: true,
            data: hasValue ? data : null,
            meta: _onError(meta),
          ),
        );
        debugPrint(e is ConverterNotFountException ? e.message : e.toString());

        if (onError != null) onError!(e);
      }
    }
  }

  Future<bool> _clearCache() {
    if (_queryKey.isNotEmpty) {
      _data.add(
        _behaviour.getNewData(
          isLoading: false,
          isError: false,
          data: null,
          meta: _onInit(null),
        ),
      );
      return _cacheManager.remove(_queryKey);
    }
    return Future<bool>(() => false);
  }

  void _revalidateCache() async {
    if (await _clearCache()) {
      refetch();
    }
  }

  bool get enabled => _enabled;

  set enabled(bool enabled) {
    _enabled = enabled;
    _fetch(forceRefresh: _hasCacheValue);
  }

  Params? get params => _params;

  set params(Params? params) {
    if (params == _params) {
      return;
    }
    _params = params;
    _setQueryKey(params);

    _fetch(forceRefresh: false);
  }
}

class QueryProvider<Res extends dynamic, ResData extends dynamic>
    extends _BaseQueryProvider<QueryMeta, Query<ResData>, Res, ResData> {
  bool get isFetching => _data.value.isFetching;

  QueryProvider(
    String query,
    QueryFunction<Res> queryFn, {
    super.params,
    super.fetchOnMount,
    super.enabled,
    super.onSuccess,
    super.onError,
    super.select,
  }) : super(
          QueryBehaviour<Res, ResData>(),
          query,
          queryFn,
          onInit: (meta) => QueryMeta(isFetching: false),
          onCache: (meta) => QueryMeta(isFetching: true),
          onForceRefresh: (meta) => QueryMeta(isFetching: true),
          onFetched: (meta) => QueryMeta(isFetching: false),
          onErrorM: (meta) => QueryMeta(isFetching: false),
        );
}

class InfiniteQueryProvider<Res extends dynamic, ResData extends dynamic>
    extends _BaseQueryProvider<InfinityQueryMeta, InfiniteQuery<ResData>, Res,
        List<ResData>> {
  bool get isFetching => _data.value.isFetching;

  bool get isFetchingNextPage => _data.value.isFetchingNextPage;

  bool get hasNextPage => _infiniteQueryParams?.hasNextPage ?? false;

  InfiniteQueryParams? _infiniteQueryParams;

  InfiniteQueryProvider(
    String query,
    QueryFunction<Res> queryFn, {
    super.params,
    super.fetchOnMount,
    super.enabled,
    super.onSuccess,
    super.onError,
    super.select,
    dynamic Function(ResData lastPage, List<ResData> allPages)?
        getNextPageParam,
  }) : super(
          InfiniteQueryBehaviour<Res, ResData>(getNextPageParam),
          query,
          queryFn,
          onInit: (meta) =>
              InfinityQueryMeta(isFetching: false, isFetchingNextPage: false),
          onCache: (meta) => InfinityQueryMeta(
              isFetching: true,
              isFetchingNextPage: meta?.isFetchingNextPage ?? false),
          onForceRefresh: (meta) => InfinityQueryMeta(
              isFetching: true,
              isFetchingNextPage: meta?.isFetchingNextPage ?? false),
          onFetched: (meta) =>
              InfinityQueryMeta(isFetching: false, isFetchingNextPage: false),
          onErrorM: (meta) =>
              InfinityQueryMeta(isFetching: false, isFetchingNextPage: false),
        ) {
    (_behaviour as InfiniteQueryBehaviour).onNextPageParams = (queryObject) {
      _infiniteQueryParams = queryObject;
    };
  }

  Future fetchNextPage() async {
    (_behaviour as InfiniteQueryBehaviour).addNewParams(_infiniteQueryParams);

    return await _fetch(
      queryContext: QueryContext(
        queryKey: [],
        pageParam: _infiniteQueryParams?.nextPageParams,
      ),
      meta: InfinityQueryMeta(isFetchingNextPage: true),
    );
  }
}

class QueryBuilder<T> extends StreamBuilder<T> {
  const QueryBuilder({
    Key? key,
    required super.builder,
    ValueStream<T>? stream,
  }) : super(key: key, stream: stream);

  @override
  AsyncSnapshot<T> initial() {
    final stream_ = stream as ValueStream;
    return stream_.hasValue
        ? AsyncSnapshot<T>.withData(ConnectionState.none, stream_.value)
        : initialData == null
            ? AsyncSnapshot<T>.nothing()
            : AsyncSnapshot<T>.withData(ConnectionState.none, initialData as T);
  }
}
