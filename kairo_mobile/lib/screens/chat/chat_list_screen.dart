import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/chat_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import '../../widgets/empty_state_widget.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final myUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Messagerie',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: chatProvider.chats.isEmpty
          ? const Center(
              child: EmptyStateWidget(
                title: 'Bienvenue sur la plateforme !',
                message: 'Commencez une discussion et découvrez la communauté.',
                icon: PhosphorIconsLight.chatTeardropText,
              ),
            )
          : ListView.builder(
              itemCount: chatProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];

                // Find the other user
                final otherUserId = chat.participantIds.firstWhere(
                  (id) => id != myUserId,
                  orElse: () => '',
                );
                if (otherUserId.isEmpty) return const SizedBox.shrink();

                final otherUserName =
                    chat.participantNames[otherUserId] ?? 'Utilisateur';
                final otherUserAvatar =
                    chat.participantAvatars[otherUserId] ??
                    'https://ui-avatars.com/api/?name=$otherUserName';
                final unreadCount = chat.unreadCounts[myUserId] ?? 0;

                final timeFormatted = DateFormat(
                  'HH:mm',
                ).format(chat.lastMessageTime);
                final isOtherTyping = chat.typingStatus[otherUserId] ?? false;

                return Dismissible(
                  key: Key(chat.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Theme.of(context).cardColor),
                  ),
                  onDismissed: (direction) {
                    context.read<ChatProvider>().deleteChat(chat.id);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: CachedNetworkImageProvider(
                        otherUserAvatar,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  otherUserName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Supprimé : FutureBuilder pour le badge vérifié (Requête N+1)
                              // Le badge vérifié peut être affiché uniquement sur le profil complet
                              // ou ajouté au modèle de chat (ChatModel) lors de sa création.
                            ],
                          ),
                        ),
                        Text(
                          timeFormatted,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? AppColors.primary
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isOtherTyping
                                ? 'est en train d\'écrire...'
                                : (chat.lastSenderId == myUserId
                                      ? 'Vous: ${chat.lastMessage}'
                                      : chat.lastMessage),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isOtherTyping
                                  ? AppColors.primary
                                  : (unreadCount > 0
                                        ? Theme.of(context).textTheme.bodyLarge?.color
                                        : Colors.grey.shade600),
                              fontWeight: (unreadCount > 0 || isOtherTyping)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontStyle: isOtherTyping
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Mark as read immediately
                      context.read<ChatProvider>().markMessagesAsRead(
                        chat.id,
                        myUserId,
                      );

                      // Navigate to detail
                      context.push(
                        '/chat_detail',
                        extra: {
                          'chatId': chat.id,
                          'otherUserId': otherUserId,
                          'otherUserName': otherUserName,
                          'otherUserAvatar': otherUserAvatar,
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
