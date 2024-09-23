import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_page.dart';
import 'package:intl/intl.dart'; // Для форматирования времени

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserEmail)
            .orderBy('timestamp', descending: true) // Сортировка по времени
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет активных чатов.'));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final participants = chatData['participants'] as List<dynamic>;

              // Находим почту собеседника
              final chatPartnerEmail =
                  participants.firstWhere((email) => email != currentUserEmail);

              // Последнее сообщение и его отправитель
              final lastMessage = chatData['lastMessage'] ?? '';
              final lastSender = chatData['lastSender'] ?? '';

              // Форматируем время последнего сообщения
              final timestamp =
                  chatData['timestamp'] as Timestamp? ?? Timestamp.now();
              final formattedTime = DateFormat.Hm().format(timestamp.toDate());

              // Подготавливаем текст для последнего сообщения
              String lastMessageDisplay;
              if (lastSender == currentUserEmail) {
                lastMessageDisplay =
                    'Вы: $lastMessage'; // Если отправитель - текущий пользователь
              } else {
                lastMessageDisplay =
                    lastMessage; // Если отправитель - собеседник
              }

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                    'Чат с $chatPartnerEmail'), // Показываем почту собеседника
                subtitle: Text(
                  '$lastMessageDisplay\n$formattedTime',
                ), // Последнее сообщение и время
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(
                        chatId: chatDoc.id, // Передаем chatId
                        userId: chatPartnerEmail,
                        chatUserName: chatPartnerEmail,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
