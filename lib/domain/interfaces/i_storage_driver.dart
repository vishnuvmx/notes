/// Storage driver abstraction contract.
abstract class IStorageDriver {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<List<String>> getAllKeys();
}
