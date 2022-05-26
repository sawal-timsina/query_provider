import 'models/query_context.dart';

typedef QueryFunction<T> = Future<T> Function({QueryContext context});

typedef MutationFunction<T, D> = Future<T> Function(D? data);

enum BroadcastType {
  initial,
  cache,
  forceRefresh,
  fetched,
  error,
}
