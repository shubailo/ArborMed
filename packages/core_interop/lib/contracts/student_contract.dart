abstract class StudentContract {
  Future<void> addXP(int amount);
  Future<void> addCoins(int amount);
  Future<int> getXP();
  Future<int> getCoins();
  Future<int> getLevel();
}
