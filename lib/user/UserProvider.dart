import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class UserProvider extends ChangeNotifier {
  String? userId;

  void setUserId(String? id) {
    userId = id;
    notifyListeners();
  }

  Future<void> loadUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    setUserId(id);
  }
}