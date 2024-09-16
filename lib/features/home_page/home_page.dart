import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Недавно добавленные пользователи'),
      ),
      body: const Center(
        child: Text('Здесь будут отображаться недавно добавленные пользователи'),
      ),
    );
  }
}
