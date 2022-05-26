import 'package:get_it/get_it.dart';

import '../converters/converter.dart';
import '../models/query_context.dart';
import '../models/query_object.dart';
import '../types.dart';

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

abstract class Behaviour<QueryType extends BaseQueryObject, Res extends dynamic, Data extends dynamic> {
  final ResponseConverter converter = GetIt.instance.get<ResponseConverter>();

  Data parseData(dynamic data);

  Future<Data> onFetch(BehaviourContext<Res, Data> context);

  QueryType getNewData({
    Data? data,
    required bool isLoading,
    required bool isError,
    required BroadcastType type,
  });
}
