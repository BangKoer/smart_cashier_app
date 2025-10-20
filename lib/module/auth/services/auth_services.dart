// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_cashier_app/common/widgets/custom_sidebar_home.dart';
import 'package:smart_cashier_app/constant/error_handling.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:smart_cashier_app/module/home/screens/home_screen.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';

class AuthServices {
  // sign up user
  Future<void> registerUser({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      User user = User(
          id: '',
          name: name,
          email: email,
          password: password,
          role: "admin",
          token: '',
          createdAt: DateTime.now());

      http.Response res = await http.post(Uri.parse('$baseUrl/admin/register'),
          body: user.toJson(),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8'
          });

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(
              context, "Account Created! Login with the same credentials");
        },
      );
    } catch (e) {
      showSnackBar(
        context,
        e.toString(),
        bgColor: Colors.red,
      );
      // ignore: avoid_print
      print(e.toString());
    }
  }

  Future<void> loginUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      http.Response res = await http.post(Uri.parse('$baseUrl/admin/login'),
          body: jsonEncode({'email': email, 'password': password}),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8'
          });
      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () async {
          // Save token in device memory
          SharedPreferences prefs = await SharedPreferences.getInstance();
          Provider.of<UserProvider>(context, listen: false).setUser(res.body);
          await prefs.setString('x-auth-token', jsonDecode(res.body)['token']);

          // to home screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            CustomSidebarHome.routeName,
            (route) => false,
          );

          showSnackBar(
            context,
            "Login Success!",
            bgColor: Colors.green,
          );
        },
      );
    } catch (e) {
      showSnackBar(
        context,
        e.toString(),
        bgColor: Colors.red,
      );
      // ignore: avoid_print
      print(e.toString());
    }
  }

  Future<void> getUserdata(BuildContext context) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString('x-auth-token');

      if (token == null) pref.setString('x-auth-token', '');

      // validating token
      var tokenRes = await http
          .post(Uri.parse('$baseUrl/isTokenValid'), headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'x-auth-token': token!,
      });

      var response = jsonDecode(tokenRes.body);
      if (response == true) {
        http.Response userResponse =
            await http.get(Uri.parse("$baseUrl/"), headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        });

        var userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(userResponse.body);
      }
    } catch (e) {
      showSnackBar(
        context,
        e.toString(),
        bgColor: Colors.red,
      );
      // ignore: avoid_print
      print(e.toString());
    }
  }
}
