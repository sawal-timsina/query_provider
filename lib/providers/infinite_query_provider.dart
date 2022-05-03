import '../behaviours/infinite_query_behaviour.dart';
import '../models/params.dart';
import '../models/query_context.dart';
import '../types.dart' show QueryFunction;
import 'base_query_provider.dart';

class InfiniteQueryProvider<Res extends dynamic, Data extends dynamic>
    extends BaseQueryProvider<Res, List<Data>> {
  InfiniteQueryProvider(
    String query,
    QueryFunction<Res> queryFn, {
    Params? params,
    bool fetchOnMount = true,
    bool enabled = true,
    void Function(List<Data> data)? onSuccess,
    void Function(Exception error)? onError,
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
        );

  Future fetchNextPage() async {
    final _behaviour = (behaviour as InfiniteQueryBehaviour);
    final _nextPageParams = _behaviour.infiniteQueryParams?.nextPageParams;
    final queryKey = _behaviour.infiniteQueryParams?.queryKey;

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
        pageParam: _behaviour.infiniteQueryParams?.nextPageParams,
      ),
    );
  }
}
