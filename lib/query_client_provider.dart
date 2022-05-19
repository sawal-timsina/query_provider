library query_provider;

import 'package:get_it/get_it.dart' show GetIt;

import 'converters/converter.dart';
import 'utils/cache_manager.dart';

class QueryClientProvider {
  QueryClientProvider({
    required ResponseConverter converter,
    required CacheManager cacheManager,
  }) {
    GetIt.instance.registerSingleton<ResponseConverter>(converter);
    GetIt.instance.registerSingleton<CacheManager>(cacheManager);
  }
}
