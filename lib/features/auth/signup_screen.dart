import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tanishuvlar/services/snack_bar.dart';
import 'package:tanishuvlar/style/app_colors.dart';
import 'package:tanishuvlar/style/app_style.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  bool isHiddenPassword = true;
  TextEditingController emailTextInputController = TextEditingController();
  TextEditingController passwordTextInputController = TextEditingController();
  TextEditingController passwordTextRepeatInputController =
      TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailTextInputController.dispose();
    passwordTextInputController.dispose();
    passwordTextRepeatInputController.dispose();

    super.dispose();
  }

  void togglePasswordView() {
    setState(() {
      isHiddenPassword = !isHiddenPassword;
    });
  }

  Future<void> signUp() async {
    final navigator = Navigator.of(context);

    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    if (passwordTextInputController.text !=
        passwordTextRepeatInputController.text) {
      SnackBarService.showSnackBar(
        context,
        'Пароли должны совпадать',
        true,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextInputController.text.trim(),
        password: passwordTextInputController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print(e.code);

      if (e.code == 'email-already-in-use') {
        SnackBarService.showSnackBar(
          context,
          'Такой Email уже используется, повторите попытку с использованием другого Email',
          true,
        );
        return;
      } else {
        SnackBarService.showSnackBar(
          context,
          'Неизвестная ошибка! Попробуйте еще раз или обратитесь в поддержку.',
          true,
        );
      }
    }

    navigator.pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.textColor,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.headerColor,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Text(
                'Create a new account',
                style: AppStyle.fontStyle.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(
                height: 10,
              ),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'Free Movies'.toUpperCase(),
                style: AppStyle.fontStyle.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                controller: emailTextInputController,
                validator: (email) =>
                    email != null && !EmailValidator.validate(email)
                        ? 'Enter corectly email'
                        : null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter your email',
                  hintStyle: AppStyle.fontStyle.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                style: const TextStyle(color: AppColors.textColor),
                autocorrect: false,
                controller: passwordTextInputController,
                obscureText: isHiddenPassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    value != null && value.length < 6 ? 'min 6 symbols' : null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter passowrd',
                  hintStyle: AppStyle.fontStyle.copyWith(color: Colors.white),
                  suffix: InkWell(
                    onTap: togglePasswordView,
                    child: Icon(
                      isHiddenPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                autocorrect: false,
                controller: passwordTextRepeatInputController,
                obscureText: isHiddenPassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    value != null && value.length < 6 ? 'min 6 symbols' : null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter new passowrd again',
                  hintStyle: AppStyle.fontStyle.copyWith(color: Colors.white),
                  suffix: InkWell(
                    onTap: togglePasswordView,
                    child: Icon(
                        isHiddenPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textColor),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 46, 46, 46),
                ),
                onPressed: signUp,
                child: Center(
                    child: Text(
                  'Sing up',
                  style: AppStyle.fontStyle.copyWith(color: Colors.white),
                )),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Sign in',
                    style: AppStyle.fontStyle.copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
