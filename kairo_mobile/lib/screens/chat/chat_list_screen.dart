import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/chat_provider.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final myUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messagerie', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: chatProvider.chats.isEmpty
          ? const Center(
              child: Text(
                'Aucune conversation pour le moment.\nTrouvez des membres et commencez à discuter !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: chatProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];
                
                // Find the other user
                final otherUserId = chat.participantIds.firstWhere((id) => id != myUserId, orElse: () => '');
                if (otherUserId.isEmpty) return const SizedBox.shrink();

                final otherUserName = chat.participantNames[otherUserId] ?? 'Utilisateur';
                final otherUserAvatar = chat.participantAvatars[otherUserId] ?? 'https://ui-avatars.com/api/?name=$otherUserName';
                final unreadCount = chat.unreadCounts[myUserId] ?? 0;
                
                final timeFormatted = DateFormat('HH:mm').format(chat.lastMessageTime);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(otherUserAvatar),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(otherUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(timeFormatted, style: TextStyle(color: unreadCount > 0 ? const Color(0xFFF97316) : Colors.grey, fontSize: 12)),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastSenderId == myUserId ? 'Vous: ${chat.lastMessage}' : chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF97316),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    // Mark as read immediately
                    context.read<ChatProvider>().markMessagesAsRead(chat.id, myUserId);
                    
                    // Navigate to detail
                    context.push('/chat_detail', extra: {
                      'chatId': chat.id,
                      'otherUserId': otherUserId,
                      'otherUserName': otherUserName,
                      'otherUserAvatar': otherUserAvatar,
                    });
                  },
                );
              },
            ),
    );
  }
}
