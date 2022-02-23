library query_provider;

import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';

import 'converters/converter.dart';
import 'utils/cache_manager.dart';

final getItQuery = GetIt.instance;

class QueryClientProvider extends StatelessWidget {
  final Widget child;

  QueryClientProvider(
      {Key? key,
      required this.child,
      required ResponseConverter converter,
      required CacheManager cacheManager})
      : super(key: key) {
    getItQuery.registerSingleton<ResponseConverter>(converter);
    getItQuery.registerSingleton<CacheManager>(cacheManager);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
