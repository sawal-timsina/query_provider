abstract class BaseProvider {
  BaseProvider();

  Future refetch();

  void clearCache();

  void revalidateCache();
}
