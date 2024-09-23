import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tanishuvlar/features/chat_page/chat_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новые пользователи'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('profiles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет новых пользователей.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userEmail =
                  users[index].id; // Используем id документа как email
              final firstName = userData['firstName'] ?? 'Не указано';
              final lastName = userData['lastName'] ?? '';
              final birthDate = userData['birthDate'] ?? 'Не указано';
              final gender = userData['gender'] ?? 'Не указано';

              // Исключаем текущего пользователя из списка
              if (userEmail == currentUserEmail) {
                return const SizedBox(); // Пропускаем текущего пользователя
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(firstName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text('$firstName $lastName'), // Показ имени и фамилии
                subtitle: Text('Дата рождения: $birthDate\nПол: $gender'),
                onTap: () {
                  _handleUserTap(context, currentUserEmail!, userEmail);
                },
              );
            },
          );
        },
      ),
    );
  }

  // Проверка, есть ли уже чат, если нет — создаем его
  Future<void> _handleUserTap(
      BuildContext context, String currentUserEmail, String userEmail) async {
    // Поиск существующего чата с текущим пользователем и собеседником
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserEmail)
        .get();

    DocumentSnapshot? existingChat;

    // Проверка, есть ли чат с собеседником
    for (var doc in chatSnapshot.docs) {
      var participants = doc['participants'] as List;
      if (participants.contains(userEmail)) {
        existingChat = doc; // Сохраняем DocumentSnapshot, а не Map
        break;
      }
    }

    if (existingChat != null) {
      // Если чат уже существует, переходим в него
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: existingChat!
                .id, // Используем existingChat.id для получения ID документа
            userId: userEmail, // Почта собеседника
            chatUserName: userEmail, // Отображаемая почта
          ),
        ),
      );
    } else {
      // Если чата нет, создаем новый
      DocumentReference newChat =
          await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUserEmail, userEmail], // Добавляем обе почты
        'lastMessage': '', // Пустое последнее сообщение при создании
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Переход в новый чат
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: newChat.id, // Используем ID нового чата
            userId: userEmail,
            chatUserName: userEmail,
          ),
        ),
      );
    }
  }
}
