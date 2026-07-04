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
        .listen((snapshot) {
      final list = snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
      // Sort locally to avoid Firestore composite index requirement
      list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      _chats = list;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to chats: $error');
    });
  }

  Future<String> createOrGetChat(String otherUserId, String otherUserName, String otherUserAvatar) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    // Chercher s'il existe déjà un chat entre les deux (avec un tri ou une comparaison simple)
    final existingChat = _chats.firstWhere(
      (chat) => chat.participantIds.contains(otherUserId) && chat.participantIds.length == 2,
      orElse: () => ChatModel(
        id: '',
        participantIds: [],
        participantNames: {},
        participantAvatars: {},
        lastMessage: '',
        lastSenderId: '',
        lastMessageTime: DateTime.now(),
        unreadCounts: {},
      ),
    );

    if (existingChat.id.isNotEmpty) {
      return existingChat.id;
    }

    // Créer un nouveau chat
    final docRef = FirebaseFirestore.instance.collection('chats').doc();
    
    // Récupérer mes infos pour les stocker
    final myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final myData = myDoc.data() ?? {};
    final myName = myData['name'] ?? currentUser.displayName ?? 'Moi';
    final myAvatar = myData['photoURL'] ?? currentUser.photoURL ?? 'https://ui-avatars.com/api/?name=$myName';

    await docRef.set({
      'participantIds': [currentUser.uid, otherUserId],
      'participantNames': {
        currentUser.uid: myName,
        otherUserId: otherUserName,
      },
      'participantAvatars': {
        currentUser.uid: myAvatar,
        otherUserId: otherUserAvatar,
      },
      'lastMessage': 'Nouvelle conversation',
      'lastSenderId': currentUser.uid,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': {
        currentUser.uid: 0,
        otherUserId: 1,
      },
    });

    return docRef.id;
  }

  Future<void> sendMessage(String chatId, String content, String otherUserId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || content.isEmpty) return;

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

  Stream<List<MessageModel>> getMessages(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  Future<void> markMessagesAsRead(String chatId, String myUserId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'unreadCounts.$myUserId': 0,
    });
  }
}
