import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String userId;
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

    // Устанавливаем активный статус при входе в чат
    _setActiveStatus(true);

    // Проверяем, прочитаны ли сообщения собеседником
    _checkIfMessagesRead();
  }

  @override
  void dispose() {
    _setActiveStatus(false);
    super.dispose();
  }

  Future<void> _setActiveStatus(bool isActive) async {
    await _firestore.collection('users').doc(currentUserEmail).update({
      'isActive': isActive,
      'chatId': widget.chatId,
    }).catchError((error) {
      print("Ошибка обновления статуса пользователя: $error");
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    String message = _messageController.text.trim();

    setState(() {
      _messageController.clear();
    });

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': currentUserEmail,
        'receiverId': widget.userId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'delivered',
      });

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': message,
        'lastSender': currentUserEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
    }
  }

  Future<void> _checkIfMessagesRead() async {
    QuerySnapshot unreadMessages = await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserEmail)
        .where('status', isEqualTo: 'delivered')
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({
        'status': 'read',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('Чат с ${widget.chatUserName}');
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            bool isUserActiveInChat = userData['isActive'] == true &&
                userData['chatId'] == widget.chatId;

            return Text(
              'Чат с ${widget.chatUserName} ${isUserActiveInChat ? "(online)" : ""}',
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

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
                    String status = messageData['status'];
                    bool isMe = messageData['senderId'] == currentUserEmail;

                    return _buildMessage(message, isMe, status);
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

  Widget _buildMessage(String message, bool isMe, String status) {
    IconData messageStatusIcon = status == 'read' ? Icons.done_all : Icons.done;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: isMe
          ? const EdgeInsets.only(left: 80.0, right: 16.0)
          : const EdgeInsets.only(left: 16.0, right: 80.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
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
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  messageStatusIcon,
                  size: 16.0,
                  color: status == 'read' ? Colors.blue : Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
