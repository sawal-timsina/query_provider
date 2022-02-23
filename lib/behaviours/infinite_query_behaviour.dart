import '../behaviours/behaviour.dart';

class InfiniteQueryParams {
  final bool hasNextPage;
  final dynamic nextPageParams;
  final String queryKey;

  InfiniteQueryParams(this.hasNextPage, this.nextPageParams, this.queryKey);
}

class InfiniteQueryBehaviour<T extends dynamic> extends Behaviour<List<T>> {
  final dynamic Function(T lastPage)? _getNextPageParam;
  void Function(InfiniteQueryParams infiniteQueryParams)? onNextPageParams;

  final Map<String, List> paramsList = {};

  InfiniteQueryBehaviour(this._getNextPageParam);

  @override
  List<T> parseCacheData(data) {
    return (data as List).map<T>((e) => converter.convert<T>(e)).toList();
  }

  List<T> revalidateData(data, previousData,
      {bool forceRefresh = false, required String queryKey}) {
    List<T> tdList = forceRefresh ? [data] : previousData ?? [];
    if (!forceRefresh && data.isNotEmpty) {
      // [1] check if new list's item are already present or not
      bool containsNew = (tdList.isEmpty
          ? false
          : tdList.every((element) {
              if (element is! List) return false;
              return element.every((ee) {
                return data.contains(ee);
              });
            }));
      // [1]

      if (!containsNew) {
        tdList.add(data);
      }
    }

    final _nextPageParams = (_getNextPageParam!(tdList.last) ?? "") as String;
    if (_nextPageParams.isNotEmpty) {
      onNextPageParams!(InfiniteQueryParams(
          _nextPageParams.isNotEmpty, _nextPageParams, queryKey));
    }
    return tdList;
  }

  @override
  Future<List<T>> onFetch(BehaviourContext<List<T>> context) async {
    final queryContext = context.queryContext;
    final queryKey = context.queryKey;
    final res = await context.queryFn(context: queryContext);

    final parsedData =
        converter.convert<T>(context.select!(res.data) ?? res.data);
    if (context.forceRefresh && paramsList.containsKey(queryKey)) {
      for (final element in paramsList[queryKey]!) {
        final res =
            await context.queryFn(context: queryContext..pageParam = element);

        final _parsedData =
            converter.convert<T>(context.select!(res.data) ?? res.data);

        parsedData.addAll(_parsedData);
      }
    }

    return revalidateData(parsedData, context.cacheData,
        forceRefresh: context.forceRefresh, queryKey: queryKey);
  }
}
