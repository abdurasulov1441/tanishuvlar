import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId; // ID чата
  final String userId; // Почта собеседника
  final String chatUserName;

  const ChatDetailPage(
      {super.key,
      required this.chatId,
      required this.userId,
      required this.chatUserName});

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  late String currentUserEmail;

  @override
  void initState() {
    super.initState();
    currentUserEmail = _auth.currentUser!.email!;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    String message = _messageController.text.trim();

    // Отправляем сообщение в существующий чат (по его ID)
    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': currentUserEmail, // Почта отправителя
      'receiverId': widget.userId, // Почта получателя
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Обновляем последнее сообщение в чате
    await _firestore.collection('chats').doc(widget.chatId).update({
      'lastMessage': message, // Обновляем последнее сообщение
      'lastSender': currentUserEmail, // Обновляем отправителя
      'timestamp':
          FieldValue.serverTimestamp(), // Обновляем время последнего сообщения
    });

    _messageController.clear();

    // Прокрутка вниз после отправки сообщения
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чат с ${widget.chatUserName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId) // Чат по его ID
                  .collection('messages') // Сообщения в этом чате
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                // Прокрутка вниз после рендера виджета
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData =
                        messages[index].data() as Map<String, dynamic>;

                    String message = messageData['message'];
                    bool isMe = messageData['senderId'] == currentUserEmail;

                    return _buildMessage(message, isMe);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Введите сообщение...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: isMe
          ? const EdgeInsets.only(left: 80.0, right: 16.0)
          : const EdgeInsets.only(left: 16.0, right: 80.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Text(
            message,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
