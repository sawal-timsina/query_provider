class _BaseQueryObject<T extends dynamic> {
  T? data;
  bool isLoading;
  bool isError;

  _BaseQueryObject({this.data, required this.isLoading, required this.isError});
}

class QueryObject<T extends dynamic> extends _BaseQueryObject<T> {
  bool isFetching;

  QueryObject({
    super.data,
    required super.isLoading,
    required super.isError,
    required this.isFetching,
  });
}

class MutationObject<T extends dynamic> extends _BaseQueryObject<T> {
  bool isSuccess;

  MutationObject({
    super.data,
    required super.isLoading,
    required super.isError,
    required this.isSuccess,
  });
}
