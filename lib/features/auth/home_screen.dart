import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tanishuvlar/features/auth/login_screen.dart';
import 'package:tanishuvlar/features/main_page/main_page.dart';
import 'package:tanishuvlar/style/app_colors.dart';

class Home1Screen extends StatelessWidget {
  const Home1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
        backgroundColor: AppColors.textColor,
        resizeToAvoidBottomInset: false,
        body: (user == null) ? const LoginScreen() : const MainPage());
  }
}
