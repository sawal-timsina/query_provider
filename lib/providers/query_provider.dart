import '../behaviours/query_behaviour.dart';
import '../models/params.dart';
import '../models/query_context.dart';
import 'base_query_provider.dart';

class QueryProvider<Res extends dynamic, Data extends dynamic> extends BaseQueryProvider<Res, Data> {
  QueryProvider(
    String query,
    Future<Res> Function({QueryContext context}) queryFn, {
    Params? params,
    bool fetchOnMount = true,
    bool enabled = true,
    void Function(Data data)? onSuccess,
    void Function(Exception error)? onError,
    dynamic Function(dynamic)? select,
  }) : super(
          QueryBehaviour<Res, Data>(),
          query,
          queryFn,
          params: params,
          fetchOnMount: fetchOnMount,
          onSuccess: onSuccess,
          onError: onError,
          select: select,
          enabled: enabled,
        );
}
