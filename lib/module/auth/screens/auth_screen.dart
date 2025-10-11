import 'package:flutter/material.dart';
import 'package:smart_cashier_app/common/widgets/custom_text_Field.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';

enum Auth {
  login,
  register,
}

class AuthScreen extends StatefulWidget {
  static const String routeName = 'auth-screen';
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  Auth _auth = Auth.register;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Login Page
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: GlobalVariables.secondaryColor,
              ),
              child: Column(
                children: [
                  const Text(
                    "Login Page",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  CustomTextField(
                    textEditingController: _nameController,
                    hintText: "Name",
                    borderColor: Colors.white,
                  ),
                  CustomTextField(
                    textEditingController: _emailController,
                    hintText: "Email",
                    borderColor: Colors.white,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
