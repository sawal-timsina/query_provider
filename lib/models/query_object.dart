class BaseQueryObject<T extends dynamic> {
  final T? data;
  final bool isLoading;
  final bool isError;

  BaseQueryObject({this.data, required this.isLoading, required this.isError});
}

class Query<T extends dynamic> extends BaseQueryObject<T> {
  final bool isFetching;

  Query({
    super.data,
    required super.isLoading,
    required super.isError,
    required this.isFetching,
  });
}

class InfiniteQuery<T> extends Query<List<T>> {
  InfiniteQuery({
    super.data,
    required super.isLoading,
    required super.isError,
    required super.isFetching,
  });
}

class MutationObject<T extends dynamic> extends BaseQueryObject<T> {
  final bool isSuccess;

  MutationObject({
    super.data,
    required super.isLoading,
    required super.isError,
    required this.isSuccess,
  });
}
