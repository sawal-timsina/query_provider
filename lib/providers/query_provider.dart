import 'package:flutter/widgets.dart'
    show AsyncSnapshot, ConnectionState, Key, StreamBuilder, debugPrint;
import 'package:get_it/get_it.dart' show GetIt;
import 'package:rxdart/rxdart.dart' show BehaviorSubject, ValueStream;

import '../behaviours/behaviour.dart' show Behaviour, BehaviourContext;
import '../behaviours/infinite_query_behaviour.dart'
    show InfiniteQueryBehaviour, InfiniteQueryParams;
import '../behaviours/query_behaviour.dart' show QueryBehaviour;
import '../converters/converter_not_found.dart';
import '../models/params.dart' show Params;
import '../models/query_context.dart' show QueryContext;
import '../models/query_object.dart' show BaseQueryObject, InfiniteQuery, Query;
import '../providers/base_provider.dart' show BaseProvider;
import '../types.dart' show BroadcastType, QueryFunction;
import '../utils/cache_manager.dart' show CacheManager;
import 'base_provider.dart' show BaseProvider;

class _BaseQueryProvider<QueryType extends BaseQueryObject, Res extends dynamic,
    Data extends dynamic> implements BaseProvider {
  final CacheManager _cacheManager = GetIt.instance.get<CacheManager>();
  late final Behaviour<QueryType, Res, Data> _behaviour;

  String _queryKey = "";
  bool _enabled = true;

  late final String _query;
  late Params? _params;

  late final BehaviorSubject<QueryType> _data;

  ValueStream<QueryType> get dataStream => _data.stream;

  Data? get data => _data.value.data;

  bool get hasValue => _data.hasValue;

  bool get isLoading => _data.value.isLoading;

  bool get isError => _data.value.isError;

  final QueryFunction<Res> _queryFn;

  dynamic Function(Res)? select;

  void Function(Data data)? onSuccess;
  void Function(dynamic error)? onError;

  _BaseQueryProvider(
    this._behaviour,
    this._query,
    this._queryFn, {
    Params? params,
    bool fetchOnMount = true,
    this.onSuccess,
    this.onError,
    this.select,
    bool enabled = true,
  }) {
    _enabled = enabled;
    _params = params;
    _setQueryKey(params);

    dynamic cacheData;
    if (_cacheManager.containsKey(_queryKey)) {
      cacheData = _behaviour.parseData(_cacheManager.get(_queryKey));
    }

    _data = BehaviorSubject.seeded(_behaviour.getNewData(
      isLoading: false,
      isError: false,
      data: cacheData,
      type: BroadcastType.initial,
    ));

    if (fetchOnMount) {
      _fetch();
    }
  }

  void _setQueryKey(Params? params) =>
      _queryKey = [_query, params?.toJson()].toString();

  @override
  Future refetch() {
    return _fetch(forceRefresh: true);
  }

  Future _fetch({bool forceRefresh = false, QueryContext? queryContext}) async {
    if (_enabled) {
      final queryKey = _queryKey;
      final hasCacheValue = _cacheManager.containsKey(queryKey);
      final forceRefresh_ = forceRefresh ? true : !hasCacheValue;
      if (!forceRefresh_) {
        try {
          final cacheData = _behaviour.parseData(_cacheManager.get(queryKey));

          _data.add(
            _behaviour.getNewData(
                isLoading: false,
                isError: false,
                data: cacheData,
                type: BroadcastType.cache),
          );
        } catch (e) {
          debugPrint(
              e is ConverterNotFountException ? e.message : e.toString());
        }
      } else {
        _data.add(
          _behaviour.getNewData(
              isLoading: !hasCacheValue,
              isError: false,
              data: null,
              type: BroadcastType.forceRefresh),
        );
      }

      try {
        final query = _query;
        final paramsC = params?.clone();
        final parsedData = await _behaviour.onFetch(BehaviourContext<Res, Data>(
            _queryFn,
            queryKey,
            QueryContext(
              queryKey: [query, paramsC],
              pageParam: queryContext?.pageParam,
            ),
            select,
            data,
            forceRefresh_));

        _data.add(
          _behaviour.getNewData(
              isLoading: false,
              isError: false,
              data: parsedData,
              type: BroadcastType.fetched),
        );
        _cacheManager.set(queryKey, parsedData);

        if (onSuccess != null) onSuccess!(parsedData!);
      } catch (e) {
        _data.add(
          _behaviour.getNewData(
              isLoading: false,
              isError: true,
              data: null,
              type: BroadcastType.error),
        );
        debugPrint(e is ConverterNotFountException ? e.message : e.toString());

        if (onError != null) onError!(e);
      }
    }
  }

  @override
  Future<bool> clearCache() {
    if (_queryKey.isNotEmpty) {
      return _cacheManager.remove(_queryKey);
    }
    return Future<bool>(() => false);
  }

  @override
  void revalidateCache() async {
    if (await clearCache()) {
      refetch();
    }
  }

  set enabled(bool enabled) {
    _enabled = enabled;
    _fetch();
  }

  Params? get params => _params;

  set params(Params? params) {
    if (params == _params) {
      return;
    }
    _params = params;
    _setQueryKey(params);

    _fetch();
  }
}

class QueryProvider<Res extends dynamic, ResData extends dynamic>
    extends _BaseQueryProvider<Query<ResData>, Res, ResData> {
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
  }) : super(QueryBehaviour<Res, ResData>(), query, queryFn);
}

class InfiniteQueryProvider<Res extends dynamic, ResData extends dynamic>
    extends _BaseQueryProvider<InfiniteQuery<ResData>, Res, List<ResData>> {
  bool get isFetching => _data.value.isFetching;

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
    dynamic Function(ResData lastPage)? getNextPageParam,
  }) : super(InfiniteQueryBehaviour<Res, ResData>(getNextPageParam), query,
            queryFn) {
    (_behaviour as InfiniteQueryBehaviour).onNextPageParams = (queryObject) {
      _infiniteQueryParams = queryObject;
    };
  }

  bool get hasNextPage => _infiniteQueryParams?.hasNextPage ?? false;

  Future fetchNextPage() async {
    (_behaviour as InfiniteQueryBehaviour).addNewParams(_infiniteQueryParams);

    return await _fetch(
      queryContext: QueryContext(
        queryKey: [],
        pageParam: _infiniteQueryParams?.nextPageParams,
      ),
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
