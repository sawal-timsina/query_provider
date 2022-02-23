import '../converters/converter.dart';
import '../models/query_context.dart';
import '../query_client_provider.dart';

class BehaviourContext<T> {
  final Future Function({QueryContext context}) queryFn;
  final QueryContext queryContext;
  final String queryKey;
  final Function(Map<String, dynamic> p1)? select;
  final T? cacheData;
  final bool forceRefresh;

  BehaviourContext(this.queryFn, this.queryKey, this.queryContext, this.select,
      this.cacheData, this.forceRefresh);
}

abstract class Behaviour<T extends dynamic> {
  final ResponseConverter converter = getItQuery.get<ResponseConverter>();

  T parseCacheData(dynamic data);

  Future<T> onFetch(BehaviourContext<T> context);
}
