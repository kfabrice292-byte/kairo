import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatModel> _chats = [];
  final bool _isLoading = false;

  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _listenToChats();
  }

  void _listenToChats() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .listen(
          (snapshot) {
            final list = snapshot.docs
                .map((doc) => ChatModel.fromFirestore(doc))
                .toList();
            // Sort locally to avoid Firestore composite index requirement
            list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
            _chats = list;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error listening to chats: $error');
          },
        );
  }

  Future<String> createOrGetChat(
    String otherUserId,
    String otherUserName,
    String otherUserAvatar,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    // Generate deterministic ID
    final uids = [currentUser.uid, otherUserId]..sort();
    final deterministicId = 'chat_${uids[0]}_${uids[1]}';

    // 1. Chercher s'il existe déjà un chat en local
    final existingChat = _chats.firstWhere(
      (chat) => chat.id == deterministicId,
      orElse: () => ChatModel(
        id: '',
        participantIds: [],
        participantNames: {},
        participantAvatars: {},
        lastMessage: '',
        lastSenderId: '',
        lastMessageTime: DateTime.now(),
        unreadCounts: {},
        typingStatus: {},
      ),
    );

    if (existingChat.id.isNotEmpty) {
      return existingChat.id;
    }

    // 2. Vérifier sur Firestore au cas où
    final docRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(deterministicId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      return deterministicId;
    }

    // 3. Créer un nouveau chat
    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final myData = myDoc.data() ?? {};
    final myName = myData['name'] ?? currentUser.displayName ?? 'Moi';
    final myAvatar =
        myData['photoURL'] ??
        currentUser.photoURL ??
        'https://ui-avatars.com/api/?name=$myName';

    await docRef.set({
      'participantIds': [currentUser.uid, otherUserId],
      'participantNames': {currentUser.uid: myName, otherUserId: otherUserName},
      'participantAvatars': {
        currentUser.uid: myAvatar,
        otherUserId: otherUserAvatar,
      },
      'lastMessage': 'Nouvelle conversation',
      'lastSenderId': currentUser.uid,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': {currentUser.uid: 0, otherUserId: 1},
      'typingStatus': {currentUser.uid: false, otherUserId: false},
    });

    return deterministicId;
  }

  Future<void> sendMessage(
    String chatId,
    String content,
    String otherUserId, {
    String? imageUrl,
    String? sharedPostId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    if (content.isEmpty && imageUrl == null && sharedPostId == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // 1. Ajouter le message
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': userId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (sharedPostId != null) 'sharedPostId': sharedPostId,
      'reactions': {},
    });

    // 2. Mettre à jour le document de chat (dernier message)
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': content,
      'lastSenderId': userId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.$otherUserId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> deleteChat(String chatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Simplest approach: Delete the chat document.
    // A robust approach would delete all messages first, or just remove the userId from participantIds
    // to do a soft delete. Let's do a hard delete for simplicity here.
    await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
  }

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'typingStatus.$userId': isTyping,
    });
  }

  Future<void> addReaction(
    String chatId,
    String messageId,
    String emoji,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // We get the message doc and update its reactions map
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': emoji});
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> markMessagesAsRead(String chatId, String myUserId) async {
    // 1. Remettre le compteur à 0
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'unreadCounts.$myUserId': 0,
    });

    // 2. Marquer les messages non-lus comme lus dans la collection messages
    final unreadMessages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: myUserId)
        .get();

    if (unreadMessages.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
