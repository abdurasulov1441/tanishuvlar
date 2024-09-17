import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailPage extends StatefulWidget {
  final String userId; // ID собеседника
  final String chatUserName;

  const ChatDetailPage(
      {super.key, required this.userId, required this.chatUserName});

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController =
      ScrollController(); // Контроллер для прокрутки

  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid; // ID текущего пользователя
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    String message = _messageController.text.trim();

    // Отправляем сообщение в Firestore
    await _firestore.collection('chats').add({
      'senderId': currentUserId,
      'receiverId': widget.userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .where('senderId', whereIn: [currentUserId, widget.userId])
                    .where('receiverId',
                        whereIn: [currentUserId, widget.userId])
                    .orderBy('timestamp',
                        descending: false) // Сортируем по времени
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Сообщений пока нет.'));
                  }

                  var allMessages = snapshot.data!.docs;

                  // Прокручиваем вниз, когда появляются новые сообщения
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
                    itemCount: allMessages.length,
                    itemBuilder: (context, index) {
                      var messageData = allMessages[index];
                      bool isMe = messageData['senderId'] == currentUserId;

                      return _buildMessage(messageData['message'], isMe);
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(), // Поле ввода и кнопка отправки
          ],
        ),
      ),
    );
  }

  // Виджет для отображения сообщений
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

  // Виджет для ввода сообщения и кнопки отправки
  Widget _buildMessageInput() {
    return Padding(
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
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
    );
  }
}
