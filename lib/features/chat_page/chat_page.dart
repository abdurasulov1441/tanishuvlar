import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('senderId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshotSent) {
          if (snapshotSent.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('receiverId', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshotReceived) {
              if (snapshotReceived.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final sentMessages = snapshotSent.data?.docs ?? [];
              final receivedMessages = snapshotReceived.data?.docs ?? [];

              // Создаем словарь для хранения последнего сообщения для каждого пользователя
              final chatUsers = <String, Map<String, dynamic>>{};

              // Обрабатываем отправленные сообщения
              for (var message in sentMessages) {
                final receiverId = message['receiverId'];
                final lastMessage = message['message'];
                final timestamp = message['timestamp'] as Timestamp?;

                if (!chatUsers.containsKey(receiverId)) {
                  chatUsers[receiverId] = {
                    'lastMessage': lastMessage,
                    'timestamp': timestamp,
                  };
                } else {
                  // Обновляем запись, если текущее сообщение новее
                  if (timestamp != null &&
                      (chatUsers[receiverId]?['timestamp'] == null ||
                          timestamp.compareTo(
                                  chatUsers[receiverId]!['timestamp']
                                      as Timestamp) >
                              0)) {
                    chatUsers[receiverId] = {
                      'lastMessage': lastMessage,
                      'timestamp': timestamp,
                    };
                  }
                }
              }

              // Обрабатываем полученные сообщения
              for (var message in receivedMessages) {
                final senderId = message['senderId'];
                final lastMessage = message['message'];
                final timestamp = message['timestamp'] as Timestamp?;

                if (!chatUsers.containsKey(senderId)) {
                  chatUsers[senderId] = {
                    'lastMessage': lastMessage,
                    'timestamp': timestamp,
                  };
                } else {
                  // Обновляем запись, если текущее сообщение новее
                  if (timestamp != null &&
                      (chatUsers[senderId]?['timestamp'] == null ||
                          timestamp.compareTo(chatUsers[senderId]!['timestamp']
                                  as Timestamp) >
                              0)) {
                    chatUsers[senderId] = {
                      'lastMessage': lastMessage,
                      'timestamp': timestamp,
                    };
                  }
                }
              }

              // Если нет чатов, отображаем сообщение
              if (chatUsers.isEmpty) {
                return const Center(
                  child: Text('Нет активных чатов.'),
                );
              }

              // Отображаем список пользователей с последними сообщениями
              return ListView.builder(
                itemCount: chatUsers.length,
                itemBuilder: (context, index) {
                  final userId = chatUsers.keys.elementAt(index);
                  final lastMessage = chatUsers[userId]?['lastMessage'] ?? '';
                  final timestamp =
                      chatUsers[userId]?['timestamp'] ?? Timestamp.now();

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Пользователь $userId'),
                    subtitle: Text(
                      '$lastMessage\n${timestamp.toDate()}',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailPage(
                            chatUserName: 'Пользователь $userId',
                            userId: userId,
                          ),
                        ),
                      );
                    },
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
