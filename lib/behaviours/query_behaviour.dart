import '../behaviours/behaviour.dart';

class QueryBehaviour<Res extends dynamic, Data extends dynamic> extends Behaviour<Res, Data> {
  @override
  Data parseCacheData(data) {
    return converter.convert<Data>(data);
  }

  @override
  Future<Data> onFetch(BehaviourContext<Res, Data> context) async {
    final res = await context.queryFn(context: context.queryContext);
    final data = context.select!(res) ?? res;

    return converter.convert<Data>(data);
  }
}
