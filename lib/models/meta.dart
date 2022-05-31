abstract class BaseQueryMeta {
  final bool? isFetching;

  BaseQueryMeta({
    this.isFetching = false,
  });
}

class QueryMeta extends BaseQueryMeta {
  QueryMeta({super.isFetching});
}

class InfinityQueryMeta extends BaseQueryMeta {
  final bool? isFetchingNextPage;

  InfinityQueryMeta({
    super.isFetching,
    this.isFetchingNextPage = false,
  });
}
