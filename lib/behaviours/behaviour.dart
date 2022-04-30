import '../converters/converter.dart';
import '../models/query_context.dart';
import '../query_client_provider.dart';

class BehaviourContext<Res extends dynamic, Data extends dynamic> {
  final Future Function({QueryContext context}) queryFn;
  final QueryContext queryContext;
  final String queryKey;
  final Function(Res)? select;
  final Data? cacheData;
  final bool forceRefresh;

  BehaviourContext(this.queryFn, this.queryKey, this.queryContext, this.select,
      this.cacheData, this.forceRefresh);
}

abstract class Behaviour<Res extends dynamic, Data extends dynamic> {
  final ResponseConverter converter = getItQuery.get<ResponseConverter>();

  Data parseCacheData(dynamic data);

  Future<Data> onFetch(BehaviourContext<Res, Data> context);
}
