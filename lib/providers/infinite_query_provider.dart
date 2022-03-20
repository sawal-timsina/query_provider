import '../behaviours/infinite_query_behaviour.dart';
import '../models/params.dart';
import '../models/query_context.dart';
import 'base_query_provider.dart';

class InfiniteQueryProvider<T extends dynamic>
    extends BaseQueryProvider<List<T>> {
  InfiniteQueryParams? infiniteQueryParams;

  InfiniteQueryProvider(
    String query,
    Future<dynamic> Function({QueryContext context}) queryFn, {
    Params? params,
    bool fetchOnMount = true,
    bool enabled = true,
    void Function(List<T> data)? onSuccess,
    void Function(Exception error)? onError,
    dynamic Function(Map<String, dynamic>)? select,
    dynamic Function(T lastPage)? getNextPageParam,
  }) : super(
          InfiniteQueryBehaviour<T>(getNextPageParam),
          query,
          queryFn,
          params: params,
          fetchOnMount: fetchOnMount,
          onSuccess: onSuccess,
          onError: onError,
          select: select,
          enabled: enabled,
        ) {
    (behaviour as InfiniteQueryBehaviour).onNextPageParams = (queryObject) {
      infiniteQueryParams = queryObject;
    };
  }

  Future fetchNextPage() async {
    final _nextPageParams = infiniteQueryParams?.nextPageParams;
    final queryKey = infiniteQueryParams?.queryKey;
    final _behaviour = (behaviour as InfiniteQueryBehaviour);

    if (_nextPageParams != null && queryKey != null) {
      final contains =
          _behaviour.paramsList[queryKey]?.contains(_nextPageParams) ?? false;
      if (!contains) {
        final _paramsList = _behaviour.paramsList[queryKey] ?? [];
        _paramsList.add(_nextPageParams);
        _behaviour.paramsList[queryKey] = _paramsList;
      }
    }

    return await fetch(
      queryContext: QueryContext(
        queryKey: [],
        pageParam: infiniteQueryParams?.nextPageParams,
      ),
    );
  }
}
