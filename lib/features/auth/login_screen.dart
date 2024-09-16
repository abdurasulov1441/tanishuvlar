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
      print(e.code);

      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        SnackBarService.showSnackBar(
          context,
          'Invalid email or password. try again later',
          true,
        );
        return;
      } else {
        SnackBarService.showSnackBar(
          context,
          'Uncorectly mistake! try again later.',
          true,
        );
        return;
      }
    }

    navigator.pushNamedAndRemoveUntil('/main', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                height: 20,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Welcome !',
                    style: AppStyle.fontStyle.copyWith(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'You can sign in',
                    style: AppStyle.fontStyle
                        .copyWith(color: AppColors.dividerColor),
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
                  Text(
                    'Free Movies'.toUpperCase(),
                    style: AppStyle.fontStyle.copyWith(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Text(
                        'Email',
                        style: AppStyle.fontStyle.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextFormField(
                    style: const TextStyle(color: AppColors.dividerColor),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    controller: emailTextInputController,
                    validator: (email) =>
                        email != null && !EmailValidator.validate(email)
                            ? 'Enter corectly email'
                            : null,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      hintText: 'Enter email',
                      hintStyle:
                          AppStyle.fontStyle.copyWith(color: Colors.white),
                      label: const Icon(
                        Icons.mail,
                        color: Color.fromARGB(255, 209, 209, 209),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Text(
                        'Password',
                        style: AppStyle.fontStyle.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextFormField(
                    style: const TextStyle(color: AppColors.dividerColor),
                    autocorrect: false,
                    controller: passwordTextInputController,
                    obscureText: isHiddenPassword,
                    validator: (value) => value != null && value.length < 6
                        ? 'min 6 symbols'
                        : null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      hintText: 'Enter password',
                      hintStyle:
                          AppStyle.fontStyle.copyWith(color: Colors.white),
                      label: const Icon(
                        Icons.lock,
                        color: Color.fromARGB(255, 209, 209, 209),
                      ),
                      suffix: InkWell(
                        onTap: togglePasswordView,
                        child: Icon(
                          isHiddenPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/reset_password'),
                        child: Text(
                          'Forgot password?',
                          style: AppStyle.fontStyle.copyWith(
                            color: const Color.fromARGB(255, 209, 209, 209),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 46, 46, 46),
                    ),
                    onPressed: login,
                    child: Center(
                        child: Text(
                      'Sing in',
                      style: AppStyle.fontStyle.copyWith(
                          color: AppColors.backgroundColor,
                          fontWeight: FontWeight.bold),
                    )),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Do\'nt have an account?',
                    style: AppStyle.fontStyle.copyWith(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/signup'),
                    child: Text('Sing up',
                        style: AppStyle.fontStyle.copyWith(
                          color: const Color.fromARGB(255, 209, 209, 209),
                        )),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
