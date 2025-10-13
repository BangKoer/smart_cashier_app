import 'package:flutter/material.dart';
import 'package:smart_cashier_app/models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(
      id: '',
      name: '',
      email: '',
      password: '',
      role: '',
      token: '',
      createdAt: null);

  User get user => _user;

  // Parameter using data type string instead User because were going to pass json body which is String.
  void setUser(String user){
    _user = User.fromJson(user);
    notifyListeners();
  } 
}
