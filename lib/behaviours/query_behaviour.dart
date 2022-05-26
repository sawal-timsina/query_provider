import '../behaviours/behaviour.dart';
import '../models/query_object.dart';
import '../types.dart';

class QueryBehaviour<Res extends dynamic, Data extends dynamic>
    extends Behaviour<Query<Data>, Res, Data> {
  @override
  Data parseData(data) {
    return data is List || data is Map ? converter.convert<Data>(data) : data;
  }

  @override
  Future<Data> onFetch(BehaviourContext<Res, Data> context) async {
    final res = await context.queryFn(context: context.queryContext);
    final data = context.select!(res) ?? res;

    return parseData(data);
  }

  @override
  Query<Data> getNewData({
    Data? data,
    required bool isLoading,
    required bool isError,
    required BroadcastType type,
  }) {
    return Query<Data>(
      isError: isError,
      isLoading: isLoading,
      data: data,
      isFetching:
          type == BroadcastType.cache || type == BroadcastType.forceRefresh
              ? true
              : false,
    );
  }
}
