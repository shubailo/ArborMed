abstract class NavigationContract {
  void navigateTo(String route, {Map<String, String>? params});
  void pop();
  void replace(String route, {Map<String, String>? params});
}
