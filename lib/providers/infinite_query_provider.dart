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
        );

  Future fetchNextPage() async {
    (behaviour as InfiniteQueryBehaviour).addNewParams();

    return await fetch(
      queryContext: QueryContext(
        queryKey: [],
        pageParam: behaviour.infiniteQueryParams?.nextPageParams,
      ),
    );
  }
}
