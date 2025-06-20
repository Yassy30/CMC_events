import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cmc_ev/models/user.dart' as local_user;
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  local_user.User? _user;
  local_user.User? get user => _user;

  void setUser(local_user.User user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}