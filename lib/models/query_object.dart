class BaseQueryObject<T extends dynamic> {
  T? data;
  bool isLoading;
  bool isError;

  BaseQueryObject({this.data, required this.isLoading, required this.isError});
}

class QueryObject<T extends dynamic> extends BaseQueryObject<T> {
  bool isFetching;

  QueryObject({
    T? data,
    required bool isLoading,
    required bool isError,
    required this.isFetching,
  }) : super(isLoading: isLoading, data: data, isError: isError);
}

class MutationObject<T extends dynamic> extends BaseQueryObject<T> {
  bool isSuccess;

  MutationObject({
    T? data,
    required bool isLoading,
    required bool isError,
    required this.isSuccess,
  }) : super(isLoading: isLoading, data: data, isError: isError);
}
