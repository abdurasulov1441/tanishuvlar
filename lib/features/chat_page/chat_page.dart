import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_page.dart';
import 'package:intl/intl.dart'; // Vaqtni formatlash uchun

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatlar'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserEmail)
            .orderBy('timestamp', descending: true) // Vaqt bo'yicha tartiblash
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Faol chatlar yo\'q.'));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final participants = chatData['participants'] as List<dynamic>;

              // Suhbatdoshning emailini topamiz
              final chatPartnerEmail =
                  participants.firstWhere((email) => email != currentUserEmail);

              // Oxirgi xabar va uning yuboruvchisi
              final lastMessage = chatData['lastMessage'] ?? '';
              final lastSender = chatData['lastSender'] ?? '';

              // Oxirgi xabar vaqtini formatlash
              final timestamp =
                  chatData['timestamp'] as Timestamp? ?? Timestamp.now();
              final formattedTime = DateFormat.Hm().format(timestamp.toDate());

              // Oxirgi xabar uchun matn tayyorlash
              String lastMessageDisplay;
              if (lastSender == currentUserEmail) {
                lastMessageDisplay =
                    'Siz: $lastMessage'; // Agar yuboruvchi joriy foydalanuvchi bo'lsa
              } else {
                lastMessageDisplay =
                    lastMessage; // Agar yuboruvchi suhbatdosh bo'lsa
              }

              // Oxirgi xabar holatini tekshirish
              String messageStatus =
                  chatData['lastMessageStatus'] ?? 'yetkazilgan';
              IconData messageStatusIcon =
                  messageStatus == 'read' ? Icons.done_all : Icons.done;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                    '$chatPartnerEmail bilan chat'), // Suhbatdoshning emailini ko'rsatish
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$lastMessageDisplay\n$formattedTime',
                      ),
                    ),
                    if (lastSender ==
                        currentUserEmail) // Galachalar faqat foydalanuvchi yuborgan xabarlar uchun ko'rsatiladi
                      Icon(
                        messageStatusIcon,
                        size: 16.0,
                        color:
                            messageStatus == 'read' ? Colors.blue : Colors.grey,
                      ),
                  ],
                ), // Oxirgi xabar va vaqt bilan galachalar
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(
                        chatId: chatDoc.id, // chatId ni uzatish
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
