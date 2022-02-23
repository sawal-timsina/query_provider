abstract class CacheManager {
  dynamic get(String key);

  Future<bool> set(String key, dynamic value);

  void remove(String key);

  bool containsKey(String key);

  void clear();
}
