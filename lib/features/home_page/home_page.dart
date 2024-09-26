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
      backgroundColor:
          const Color(0xFF1F1F1F), // Тёмный фон как на странице логина
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F), // Тёмный AppBar
        title: const Text('Yangi foydalanuvchilar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        elevation: 0, // Убираем тень AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Логика обновления
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('profiles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Yangi foydalanuvchilar yo\'q.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userEmail = users[index].id;
              final firstName = userData['firstName'] ?? 'Kiritilmagan';
              final lastName = userData['lastName'] ?? '';
              final birthDate = userData['birthDate'] ?? 'Kiritilmagan';
              final gender = userData['gender'] ?? 'Kiritilmagan';

              if (userEmail == currentUserEmail) {
                return const SizedBox(); // Пропускаем текущего пользователя
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      gender == 'Ayol' ? Colors.pinkAccent : Colors.blueAccent,
                  child: Text(
                    firstName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Tug\'ilgan sana: $birthDate\nJinsi: $gender',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
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

  // Проверка на наличие чата и создание нового при необходимости
  Future<void> _handleUserTap(
      BuildContext context, String currentUserEmail, String userEmail) async {
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserEmail)
        .get();

    DocumentSnapshot? existingChat;

    for (var doc in chatSnapshot.docs) {
      var participants = doc['participants'] as List;
      if (participants.contains(userEmail)) {
        existingChat = doc;
        break;
      }
    }

    if (existingChat != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: existingChat!.id,
            userId: userEmail,
            chatUserName: userEmail,
          ),
        ),
      );
    } else {
      DocumentReference newChat =
          await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUserEmail, userEmail],
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: newChat.id,
            userId: userEmail,
            chatUserName: userEmail,
          ),
        ),
      );
    }
  }
}
