import 'package:flutter/widgets.dart' show debugPrint, protected;
import 'package:rxdart/rxdart.dart' show BehaviorSubject, ValueStream;

import '../behaviours/behaviour.dart';
import '../converters/converter_not_found.dart';
import '../models/params.dart';
import '../models/query_context.dart';
import '../models/query_object.dart';
import '../providers/base_provider.dart';
import '../query_client_provider.dart';
import '../utils/cache_manager.dart';
import 'base_provider.dart';

class BaseQueryProvider<Res extends dynamic, Data extends dynamic> implements BaseProvider {
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

  final Future<Res> Function({QueryContext context}) _queryFn;

  dynamic Function(Res)? select;

  void Function(Data data)? onSuccess;
  void Function(Exception error)? onError;

  BaseQueryProvider(
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

    if (fetchOnMount && _enabled) {
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
      final _forceRefresh =
          forceRefresh ? true : !_cacheManager.containsKey(_queryKey);
      if (!_forceRefresh) {
        try {
          final cacheData =
              _behaviour.parseCacheData(_cacheManager.get(_queryKey));

          _data.add(QueryObject(
            isLoading: false,
            isFetching: true,
            isError: false,
            data: cacheData,
          ));
        } on ConverterNotFountException catch (e) {
          debugPrint(e.message);
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
        final parsedData = await behaviour.onFetch(BehaviourContext<Res, Data>(
            _queryFn,
            _queryKey,
            QueryContext(
              queryKey: [_query, params?.clone()],
              pageParam: queryContext?.pageParam,
            ),
            select,
            data,
            _forceRefresh));

        _data.add(QueryObject(
          isLoading: false,
          isFetching: false,
          isError: false,
          data: parsedData,
        ));
        _cacheManager.set(_queryKey, parsedData);

        if (onSuccess != null) onSuccess!(parsedData!);
      } on Exception catch (e) {
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

  Behaviour get behaviour => _behaviour;

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
