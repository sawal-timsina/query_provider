import '../behaviours/behaviour.dart';

class QueryBehaviour<Res extends dynamic, Data extends dynamic>
    extends Behaviour<Res, Data> {
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
}
