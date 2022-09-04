import '../behaviours/behaviour.dart';
import '../models/meta.dart';
import '../models/query_object.dart';

class QueryBehaviour<Res extends dynamic, Data extends dynamic>
    extends Behaviour<QueryMeta, Query<Data>, Res, Data> {
  @override
  Data parseData(data) {
    return data is List || data is Map ? converter.convert<Data>(data) : data;
  }

  @override
  Future<Data> onFetch(BehaviourContext<Res, Data> context) async {
    final res = await context.queryFn(context: context.queryContext);
    final data = context.select != null ? context.select!(res) : res;

    return parseData(data);
  }

  @override
  Query<Data> getNewData({
    Data? data,
    required bool isLoading,
    required bool isError,
    required QueryMeta meta,
  }) {
    return Query<Data>(
      isError: isError,
      isLoading: isLoading,
      data: data,
      isFetching: meta.isFetching!,
    );
  }
}
