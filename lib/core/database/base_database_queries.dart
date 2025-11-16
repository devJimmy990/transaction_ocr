abstract class BaseDatabaseQueries {
  Future<int> delete(String id);

  Future<List<Map<String, dynamic>>> getAll();

  Future<int> insert(Map<String, dynamic> payload);

  Future<int> update(String id, Map<String, dynamic> payload);
}
