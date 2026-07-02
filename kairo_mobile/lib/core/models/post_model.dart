import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorAvatar;
  final String content;
  final List<String> imageUrls;
  final bool isStylized;
  final int styleIndex;
  List<String> likedBy;
  int comments;
  bool isLiked;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatar,
    required this.content,
    this.imageUrls = const [],
    this.isStylized = false,
    this.styleIndex = 0,
    this.likedBy = const [],
    this.comments = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Utilisateur',
      authorRole: data['authorRole'] ?? '',
      authorAvatar: data['authorAvatar'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isStylized: data['isStylized'] ?? false,
      styleIndex: data['styleIndex'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      comments: data['comments'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorAvatar': authorAvatar,
      'content': content,
      'imageUrls': imageUrls,
      'isStylized': isStylized,
      'styleIndex': styleIndex,
      'likedBy': likedBy,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
