import 'package:flutter/material.dart';
import 'package:smart_cashier_app/common/widgets/custom_button.dart';
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/common/widgets/custom_text_Field.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/auth/services/auth_services.dart';
import 'package:toggle_switch/toggle_switch.dart';

class AuthScreen extends StatefulWidget {
  static const String routeName = 'auth-screen';
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _authActive = 0; // Mean Login form active
  bool isLoading = false;
  final AuthServices authServices = AuthServices();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void signInUser() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
    }

    await authServices.loginUser(
      context: context,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() {
      isLoading = false;
    });
  }

  void signUpUser() async {
    if (_registerFormKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
    }

    await authServices.registerUser(
      context: context,
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
    );

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Image.asset(
                  'assets/smarttext.png',
                  scale: 12,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: GlobalVariables.secondaryColor,
                  ),
                  child: _authActive == 1 ? _registerForm() : _loginForm(),
                ),
                const SizedBox(
                  height: 10,
                ),
                ToggleSwitch(
                  minWidth: double.infinity,
                  minHeight: 50,
                  initialLabelIndex: _authActive,
                  totalSwitches: 2,
                  labels: const ["Login", "Register"],
                  onToggle: (index) {
                    setState(() {
                      _authActive = index!;
                    });
                  },
                ),
              ],
            ),
          ),
          if (isLoading) CustomLoading(),
        ],
      ),
    );
  }

  Form _loginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          const Text(
            "Login",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          CustomTextField(
            textEditingController: _emailController,
            hintText: "Email",
            icontf: Icons.alternate_email,
            inputType: TextInputType.emailAddress,
          ),
          CustomTextField(
            textEditingController: _passwordController,
            hintText: "Password",
            icontf: Icons.lock_person,
            isPasswordField: true,
          ),
          const SizedBox(
            height: 10,
          ),
          CustomButton(
            text: "Login",
            onClick: signInUser,
          )
        ],
      ),
    );
  }

  Form _registerForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          const Text(
            "Register",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          CustomTextField(
            textEditingController: _nameController,
            hintText: "Name",
            icontf: Icons.person,
          ),
          CustomTextField(
            textEditingController: _emailController,
            hintText: "Email",
            icontf: Icons.alternate_email,
            inputType: TextInputType.emailAddress,
          ),
          CustomTextField(
            textEditingController: _passwordController,
            hintText: "Password",
            icontf: Icons.lock_person,
            isPasswordField: true,
          ),
          const SizedBox(
            height: 10,
          ),
          CustomButton(
            text: "Register",
            onClick: signUpUser,
          )
        ],
      ),
    );
  }
}
