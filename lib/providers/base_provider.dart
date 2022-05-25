abstract class BaseProvider {
  BaseProvider();

  Future refetch();

  Future<bool> clearCache();

  void revalidateCache();
}
