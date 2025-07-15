import 'package:campus_link/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../session/session.dart'; // para acessar Session.currentUser.id
import '../models/message_models.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;

  const ChatPage({super.key, required this.chat});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> sendMessage() async {
    final content = controller.text.trim();
    if (content.isEmpty) return;

    final currentUserId = Session.currentStudent!.id;
    final receiverId = widget.chat.userId;

    try {
      // 1. Adiciona a mensagem ao Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      controller.clear();

      // 2. Envia notificação push
      final senderName = Session.currentStudent?.nome ?? 'Alguém';
      await NotificationService.sendChatNotification(
        receiverId: receiverId,
        senderName: senderName,
        message: content,
      );
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Session.currentStudent!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chat.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    final content = data['content'] ?? '';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width *
                              0.75, // Limita a 75% da largura da tela
                        ),
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blue[600]
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]
                                  : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          content,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(8),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]!
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Escreve uma mensagem...",
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
