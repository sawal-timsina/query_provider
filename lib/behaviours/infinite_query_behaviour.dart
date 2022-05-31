import '../behaviours/behaviour.dart';
import '../models/meta.dart';
import '../models/query_object.dart';

class InfiniteQueryParams {
  final bool hasNextPage;
  final dynamic nextPageParams;
  final String queryKey;

  InfiniteQueryParams(this.hasNextPage, this.nextPageParams, this.queryKey);
}

class InfiniteQueryBehaviour<Res extends dynamic, Data extends dynamic>
    extends Behaviour<InfinityQueryMeta, InfiniteQuery<Data>, Res, List<Data>> {
  final dynamic Function(Data lastPage)? _getNextPageParam;
  void Function(InfiniteQueryParams infiniteQueryParams)? onNextPageParams;

  final Map<String, List> paramsList = {};

  InfiniteQueryBehaviour(this._getNextPageParam);

  @override
  List<Data> parseData(data) {
    return (data as List).map<Data>((e) => converter.convert<Data>(e)).toList();
  }

  List<Data> revalidateData(List<Data> data, List<Data>? previousData,
      {bool forceRefresh = false, required String queryKey}) {
    final List<Data> tdList = forceRefresh ? data : (previousData ?? []);
    final data_ = data.first;
    if (!forceRefresh && data_.isNotEmpty) {
      // TODO :: [1] check if new list's item are already present or not
      bool containsNew = (tdList.isEmpty
          ? false
          : tdList.every((element) {
              if (element is! List) return false;
              return element.every((ee) {
                return data_.contains(ee);
              });
            }));
      // [1]

      if (!containsNew) {
        tdList.add(data_);
      }
    }

    final nextPageParams =
        (_getNextPageParam!(forceRefresh ? tdList.last : data.last) ?? "")
            .toString();
    onNextPageParams!(InfiniteQueryParams(
        nextPageParams.isNotEmpty, nextPageParams, queryKey));
    return tdList;
  }

  @override
  Future<List<Data>> onFetch(BehaviourContext<Res, List<Data>> context) async {
    final queryContext = context.queryContext;
    final queryKey = context.queryKey;
    final res = await context.queryFn(context: queryContext);

    final List<Data> parsedData = [convertor(context.select!(res) ?? res)];
    if (context.forceRefresh && paramsList.containsKey(queryKey)) {
      for (final element in paramsList[queryKey]!) {
        final res =
            await context.queryFn(context: queryContext..pageParam = element);
        parsedData.add(convertor(context.select!(res) ?? res));
      }
    }

    return revalidateData(parsedData, context.cacheData,
        forceRefresh: context.forceRefresh, queryKey: queryKey);
  }

  void addNewParams(InfiniteQueryParams? infiniteQueryParams) {
    final nextPageParams_ = infiniteQueryParams?.nextPageParams;
    final queryKey = infiniteQueryParams?.queryKey;

    if (nextPageParams_ != null && queryKey != null) {
      final contains = paramsList[queryKey]?.contains(nextPageParams_) ?? false;
      if (!contains) {
        final paramsList_ = paramsList[queryKey] ?? [];
        paramsList_.add(nextPageParams_);
        paramsList[queryKey] = paramsList_;
      }
    }
  }

  dynamic convertor(data) {
    return data is Map || data is List ? converter.convert<Data>(data) : data;
  }

  @override
  InfiniteQuery<Data> getNewData({
    List<Data>? data,
    required bool isLoading,
    required bool isError,
    required InfinityQueryMeta meta,
  }) {
    return InfiniteQuery<Data>(
      isError: isError,
      isLoading: isLoading,
      data: data,
      isFetchingNextPage: meta.isFetchingNextPage!,
      isFetching: meta.isFetching!,
    );
  }
}
