import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tanishuvlar/services/snack_bar.dart';
import 'package:tanishuvlar/style/app_colors.dart';
import 'package:tanishuvlar/style/app_style.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  TextEditingController emailTextInputController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailTextInputController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailTextInputController.text.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        SnackBarService.showSnackBar(
          context,
          'Bunday email ro\'yxatdan o\'tmagan!',
          true,
        );
        return;
      } else {
        SnackBarService.showSnackBar(
          context,
          'Noma\'lum xato! Qayta urinib ko\'ring yoki qo\'llab-quvvatlashga murojaat qiling.',
          true,
        );
        return;
      }
    }

    const snackBar = SnackBar(
      content:
          Text('Parolni tiklash amalga oshirildi. Pochtangizni tekshiring'),
      backgroundColor: Colors.green,
    );

    scaffoldMessenger.showSnackBar(snackBar);
    navigator.pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        backgroundColor: Colors.grey[800],
        title: Text(
          'Parolni tiklash',
          style: AppStyle.fontStyle.copyWith(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                style: const TextStyle(color: AppColors.textColor),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                controller: emailTextInputController,
                validator: (email) =>
                    email != null && !EmailValidator.validate(email)
                        ? 'To\'g\'ri email kiriting'
                        : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20.0), // Rounded corners
                    borderSide: BorderSide(color: AppColors.textColor),
                  ),
                  hintText: 'Emailingizni kiriting',
                  hintStyle: AppStyle.fontStyle.copyWith(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850], // Darker background for input
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(
                      vertical: 15), // Increased padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // Rounded button
                  ),
                ),
                onPressed: resetPassword,
                child: Center(
                  child: Text(
                    'Parolni tiklash',
                    style: AppStyle.fontStyle
                        .copyWith(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
