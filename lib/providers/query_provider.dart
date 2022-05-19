import 'package:flutter/widgets.dart' show debugPrint, protected;
import 'package:rxdart/rxdart.dart' show BehaviorSubject, ValueStream;

import '../behaviours/behaviour.dart' show Behaviour, BehaviourContext;
import '../behaviours/infinite_query_behaviour.dart'
    show InfiniteQueryBehaviour, InfiniteQueryParams;
import '../behaviours/query_behaviour.dart' show QueryBehaviour;
import '../converters/converter_not_found.dart' show ConverterNotFountException;
import '../models/params.dart' show Params;
import '../models/query_context.dart' show QueryContext;
import '../models/query_object.dart' show QueryObject;
import '../providers/base_provider.dart' show BaseProvider;
import '../query_client_provider.dart' show getItQuery;
import '../types.dart' show QueryFunction;
import '../utils/cache_manager.dart' show CacheManager;
import 'base_provider.dart' show BaseProvider;

class _BaseQueryProvider<Res extends dynamic, Data extends dynamic>
    implements BaseProvider {
  final CacheManager _cacheManager = getItQuery.get<CacheManager>();
  late final Behaviour _behaviour;

  String _queryKey = "";
  bool _enabled = true;

  late final String _query;
  late Params? _params;

  final BehaviorSubject<QueryObject<Data>> _data = BehaviorSubject();

  ValueStream<QueryObject<Data>> get dataStream => _data.stream;

  Data? get data => _data.value.data;

  bool get hasValue => _data.hasValue;

  bool get isLoading => _data.value.isLoading;

  bool get isFetching => _data.value.isFetching;

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
    _queryKey = [_query, params?.toJson()].toString();

    if (fetchOnMount) {
      fetch();
    }
  }

  @override
  Future refetch() {
    return fetch(forceRefresh: true);
  }

  @protected
  Future fetch({bool forceRefresh = false, QueryContext? queryContext}) async {
    if (_enabled) {
      final forceRefresh_ =
          forceRefresh ? true : !_cacheManager.containsKey(_queryKey);
      if (!forceRefresh_) {
        try {
          final cacheData =
              _behaviour.parseCacheData(_cacheManager.get(_queryKey));

          _data.add(QueryObject(
            isLoading: false,
            isFetching: true,
            isError: false,
            data: cacheData,
          ));
        } catch (e) {
          debugPrint(e is ConverterNotFountException ? e.message : e.toString());
        }
      } else {
        _data.add(QueryObject(
          isLoading: true,
          isFetching: true,
          isError: false,
          data: hasValue ? data : null,
        ));
      }

      try {
        final parsedData = await _behaviour.onFetch(BehaviourContext<Res, Data>(
            _queryFn,
            _queryKey,
            QueryContext(
              queryKey: [_query, params?.clone()],
              pageParam: queryContext?.pageParam,
            ),
            select,
            data,
            forceRefresh_));

        _data.add(QueryObject(
          isLoading: false,
          isFetching: false,
          isError: false,
          data: parsedData,
        ));
        _cacheManager.set(_queryKey, parsedData);

        if (onSuccess != null) onSuccess!(parsedData!);
      } catch (e) {
        _data.add(QueryObject(
          isLoading: false,
          isFetching: false,
          isError: true,
          data: null,
        ));
        debugPrint(e is ConverterNotFountException ? e.message : e.toString());

        if (onError != null) onError!(e);
      }
    }
  }

  @override
  void clearCache() {
    if (_queryKey.isNotEmpty) {
      _cacheManager.remove(_queryKey);
    }
  }

  @override
  void revalidateCache() {
    if (_queryKey.isNotEmpty) {
      _cacheManager.remove(_queryKey);
      refetch();
    }
  }

  set enabled(bool enabled) {
    _enabled = enabled;
    fetch();
  }

  Params? get params => _params;

  set params(Params? params) {
    _params = params;
    _queryKey = [_query, params?.toJson()].toString();

    final cacheData = _cacheManager.containsKey(_queryKey)
        ? _behaviour.parseCacheData(_cacheManager.get(_queryKey))
        : null;

    _data.add(QueryObject(
        isLoading: hasValue ? isLoading : false,
        isFetching: hasValue ? isFetching : false,
        isError: hasValue ? isError : false,
        data: cacheData));
  }
}

class QueryProvider<Res extends dynamic, Data extends dynamic>
    extends _BaseQueryProvider<Res, Data> {
  QueryProvider(
    String query,
    QueryFunction<Res> queryFn, {
    Params? params,
    bool fetchOnMount = true,
    bool enabled = true,
    void Function(Data data)? onSuccess,
    void Function(dynamic error)? onError,
    dynamic Function(Res)? select,
  }) : super(
          QueryBehaviour<Res, Data>(),
          query,
          queryFn,
          params: params,
          fetchOnMount: fetchOnMount,
          onSuccess: onSuccess,
          onError: onError,
          select: select,
          enabled: enabled,
        );
}

class InfiniteQueryProvider<Res extends dynamic, Data extends dynamic>
    extends _BaseQueryProvider<Res, List<Data>> {
  InfiniteQueryParams? _infiniteQueryParams;

  InfiniteQueryProvider(
    String query,
    QueryFunction<Res> queryFn, {
    Params? params,
    bool fetchOnMount = true,
    bool enabled = true,
    void Function(List<Data> data)? onSuccess,
    void Function(dynamic error)? onError,
    dynamic Function(Res)? select,
    dynamic Function(Data lastPage)? getNextPageParam,
  }) : super(
          InfiniteQueryBehaviour<Res, Data>(getNextPageParam),
          query,
          queryFn,
          params: params,
          fetchOnMount: fetchOnMount,
          onSuccess: onSuccess,
          onError: onError,
          select: select,
          enabled: enabled,
        ) {
    (_behaviour as InfiniteQueryBehaviour).onNextPageParams = (queryObject) {
      _infiniteQueryParams = queryObject;
    };
  }

  bool get hasNextPage => _infiniteQueryParams?.hasNextPage ?? false;

  Future fetchNextPage() async {
    (_behaviour as InfiniteQueryBehaviour).addNewParams(_infiniteQueryParams);

    return await fetch(
      queryContext: QueryContext(
        queryKey: [],
        pageParam: _infiniteQueryParams?.nextPageParams,
      ),
    );
  }
}
