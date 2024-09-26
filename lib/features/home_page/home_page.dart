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
        title: const Text('Yangi foydalanuvchilar'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('profiles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Yangi foydalanuvchilar yo\'q.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userEmail =
                  users[index].id; // Email sifatida hujjatning IDsi ishlatiladi
              final firstName = userData['firstName'] ?? 'Kiritilmagan';
              final lastName = userData['lastName'] ?? '';
              final birthDate = userData['birthDate'] ?? 'Kiritilmagan';
              final gender = userData['gender'] ?? 'Kiritilmagan';

              // Joriy foydalanuvchini ro'yxatdan chiqarish
              if (userEmail == currentUserEmail) {
                return const SizedBox(); // Joriy foydalanuvchini o\'tkazib yuborish
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
                    '$firstName $lastName'), // Ism va familiya ko\'rsatiladi
                subtitle: Text('Tug\'ilgan sana: $birthDate\nJinsi: $gender'),
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

  // Mavjud chat borligini tekshirish, yo'q bo'lsa yangi chat yaratish
  Future<void> _handleUserTap(
      BuildContext context, String currentUserEmail, String userEmail) async {
    // Joriy foydalanuvchi va suhbatdosh bilan mavjud chatni qidirish
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserEmail)
        .get();

    DocumentSnapshot? existingChat;

    // Suhbatdosh bilan chat borligini tekshirish
    for (var doc in chatSnapshot.docs) {
      var participants = doc['participants'] as List;
      if (participants.contains(userEmail)) {
        existingChat = doc; // DocumentSnapshot saqlanadi, Map emas
        break;
      }
    }

    if (existingChat != null) {
      // Agar chat mavjud bo'lsa, unga o'tish
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: existingChat!.id, // Hujjatning IDsi orqali chatga o\'tish
            userId: userEmail, // Suhbatdoshning emaili
            chatUserName: userEmail, // Email ko\'rsatiladi
          ),
        ),
      );
    } else {
      // Agar chat yo'q bo'lsa, yangi chat yaratish
      DocumentReference newChat =
          await FirebaseFirestore.instance.collection('chats').add({
        'participants': [
          currentUserEmail,
          userEmail
        ], // Ikkala email qo\'shiladi
        'lastMessage': '', // Chat yaratilganda oxirgi xabar bo'sh bo'ladi
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Yangi chatga o'tish
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: newChat.id, // Yangi chatning IDsi
            userId: userEmail,
            chatUserName: userEmail,
          ),
        ),
      );
    }
  }
}
