import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Function(String, String) onUserSelected;

  const HomePage({super.key, required this.onUserSelected});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новые пользователи'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('profiles') // Коллекция профилей
            .orderBy('birthDate', descending: true) // Сортировка
            .limit(20) // Лимит
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('Нет недавно добавленных пользователей.'));
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
                child: Text('Нет недавно добавленных пользователей.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final name = userData['firstName'] ?? 'Не указано';
              final lastName = userData['lastName'] ?? '';
              final birthDate = userData['birthDate'] ?? 'Не указано';
              final gender = userData['gender'] ?? 'Не указано';

              // Исключаем текущего пользователя из списка
              if (userId == currentUser?.email) {
                return const SizedBox(); // Возвращаем пустой виджет
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text('$name $lastName'),
                subtitle: Text('Дата рождения: $birthDate\nПол: $gender'),
                onTap: () {
                  onUserSelected(
                      userId, name); // Передаем данные о пользователе
                },
              );
            },
          );
        },
      ),
    );
  }
}
