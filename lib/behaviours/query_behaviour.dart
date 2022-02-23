import '../behaviours/behaviour.dart';

class QueryBehaviour<T extends dynamic> extends Behaviour<T> {
  @override
  T parseCacheData(data) {
    return converter.convert<T>(data);
  }

  @override
  Future<T> onFetch(BehaviourContext<T> context) async {
    final res = await context.queryFn(context: context.queryContext);
    final data = context.select!(res.data) ?? res.data;

    return converter.convert<T>(data);
  }
}
