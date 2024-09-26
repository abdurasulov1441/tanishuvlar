import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tanishuvlar/services/snack_bar.dart';
import 'package:tanishuvlar/style/app_colors.dart';
import 'package:tanishuvlar/style/app_style.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isHiddenPassword = true;
  TextEditingController emailTextInputController = TextEditingController();
  TextEditingController passwordTextInputController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailTextInputController.dispose();
    passwordTextInputController.dispose();

    super.dispose();
  }

  void togglePasswordView() {
    setState(() {
      isHiddenPassword = !isHiddenPassword;
    });
  }

  Future<void> login() async {
    final navigator = Navigator.of(context);

    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextInputController.text.trim(),
        password: passwordTextInputController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        SnackBarService.showSnackBar(
          context,
          'Noto\'g\'ri email yoki parol. Qayta urinib ko\'ring.',
          true,
        );
      } else {
        SnackBarService.showSnackBar(
          context,
          'Noma\'lum xato. Iltimos keyinroq qayta urinib ko\'ring.',
          true,
        );
      }
    }

    navigator.pushNamedAndRemoveUntil('/main', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Xush kelibsiz!',
                  style: AppStyle.fontStyle.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hisobingizga kiring',
                  style: AppStyle.fontStyle
                      .copyWith(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  controller: emailTextInputController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Emailingizni kiriting',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  validator: (email) =>
                      email != null && !EmailValidator.validate(email)
                          ? 'To\'g\'ri email kiriting'
                          : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  controller: passwordTextInputController,
                  obscureText: isHiddenPassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Parolingizni kiriting',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isHiddenPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                      onPressed: togglePasswordView,
                    ),
                  ),
                  validator: (value) => value != null && value.length < 6
                      ? 'Parol kamida 6 belgidan iborat bo\'lishi kerak'
                      : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: login,
                    child: Text(
                      'Kirish',
                      style: AppStyle.fontStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/signup'),
                    child: Text(
                      'Hisobingiz yo\'qmi? Ro\'yxatdan o\'ting',
                      style: AppStyle.fontStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
