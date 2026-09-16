import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/chat_model.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
// Note: We use a simple placeholder for Firebase Storage since the package might not be included yet.
// If not, we will use a dummy URL for now.

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    // Marquer les messages comme lus dès l'ouverture du chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myUserId = context.read<AuthProvider>().userModel?.uid;
      if (myUserId != null) {
        context.read<ChatProvider>().markMessagesAsRead(
          widget.chatId,
          myUserId,
        );
      }
    });
  }

  void _sendMessage({String? imageUrl, String? sharedPostId}) {
    final content = _messageController.text.trim();
    if (content.isEmpty && imageUrl == null && sharedPostId == null) return;
    _messageController.clear();

    context.read<ChatProvider>().sendMessage(
      widget.chatId,
      content,
      widget.otherUserId,
      imageUrl: imageUrl,
      sharedPostId: sharedPostId,
    );
  }

  void _onTyping(String text) {
    context.read<ChatProvider>().setTypingStatus(widget.chatId, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      context.read<ChatProvider>().setTypingStatus(widget.chatId, false);
    });
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Pour une vraie implémentation, on uploaderait le fichier sur Firebase Storage ici.
      // Pour la démo, on utilise une URL factice ou on simule l'upload.
      // String imageUrl = await uploadToStorage(pickedFile.path);
      String fakeImageUrl =
          'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}';
      _sendMessage(imageUrl: fakeImageUrl);
    }
  }

  void _showReactionSheet(String messageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['❤️', '👏', '🔥', '😂', '👍']
              .map(
                (emoji) => GestureDetector(
                  onTap: () {
                    context.read<ChatProvider>().addReaction(
                      widget.chatId,
                      messageId,
                      emoji,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(emoji, style: TextStyle(fontSize: 32)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().userModel;
    final myUserId = authUser?.uid ?? '';
    
    final isConnected = true; // Allow chatting even if pending

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                widget.otherUserAvatar,
              ),
              radius: 18,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.otherUserName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        if (data['isVerified'] == true) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                              color: AppColors.primary,
                              size: 16,
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: context.read<ChatProvider>().getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Envoyez un premier message à ${widget.otherUserName} !',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true, // Pour que les messages récents soient en bas
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myUserId;

                    return GestureDetector(
                      onLongPress: () => _showReactionSheet(msg.id),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 4, top: 2),
                              padding: EdgeInsets.symmetric(
                                horizontal: msg.imageUrl != null ? 4 : 16,
                                vertical: msg.imageUrl != null ? 4 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (msg.imageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: msg.imageUrl!,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      ),
                                    ),
                                  if (msg.content.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: msg.imageUrl != null ? 8 : 0,
                                        left: msg.imageUrl != null ? 12 : 0,
                                        right: msg.imageUrl != null ? 12 : 0,
                                        bottom: msg.imageUrl != null ? 8 : 0,
                                      ),
                                      child: Text(
                                        msg.content,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Theme.of(context).textTheme.bodyLarge?.color,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: msg.imageUrl != null ? 12 : 0,
                                      bottom: msg.imageUrl != null ? 4 : 0,
                                      left: msg.imageUrl != null ? 12 : 0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'HH:mm',
                                          ).format(msg.timestamp),
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white70
                                                : Colors.grey.shade500,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          SizedBox(width: 4),
                                          Icon(
                                            msg.isRead
                                                ? PhosphorIcons.checks()
                                                : PhosphorIcons.check(),
                                            size: 14,
                                            color: msg.isRead
                                                ? Colors.blue.shade100
                                                : Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (msg.reactions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    msg.reactions.values.join(' '),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              children: [
                Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    try {
                      final chat = provider.chats.firstWhere(
                        (c) => c.id == widget.chatId,
                      );
                      final isTyping =
                          chat.typingStatus[widget.otherUserId] ?? false;
                      if (!isTyping) return SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              '${widget.otherUserName} est en train d\'écrire...',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      return SizedBox.shrink();
                    }
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: isConnected,
                        onChanged: _onTyping,
                        decoration: InputDecoration(
                          hintText: isConnected
                              ? 'Écrire un message...'
                              : 'Ajoutez ${widget.otherUserName} à votre réseau',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: isConnected
                          ? AppColors.primary
                          : Colors.grey,
                      radius: 24,
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).cardColor,
                          size: 20,
                        ),
                        onPressed: isConnected ? _sendMessage : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
