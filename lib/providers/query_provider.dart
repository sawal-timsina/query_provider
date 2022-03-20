import '../behaviours/query_behaviour.dart';
import '../models/params.dart';
import '../models/query_context.dart';
import 'base_query_provider.dart';

class QueryProvider<T extends dynamic> extends BaseQueryProvider<T> {
  QueryProvider(
    String query,
    Future<dynamic> Function({QueryContext context}) queryFn, {
    Params? params,
    bool fetchOnMount = true,
    bool enabled = true,
    void Function(T data)? onSuccess,
    void Function(Exception error)? onError,
    dynamic Function(Map<String, dynamic>)? select,
  }) : super(
          QueryBehaviour<T>(),
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
