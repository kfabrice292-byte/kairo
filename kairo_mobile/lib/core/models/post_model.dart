import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorAvatar;
  final String content;
  final String? category;
  final Map<String, dynamic> customFields;
  final List<String> tags;
  final String? communityId; // Si null, c'est un post global
  final List<String> imageUrls;
  final bool isStylized;
  final int styleIndex;
  List<String> likedBy;
  List<String> savedBy;
  int comments;
  bool isLiked;
  bool isSaved;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatar,
    required this.content,
    this.category,
    this.customFields = const {},
    this.tags = const [],
    this.communityId,
    this.imageUrls = const [],
    this.isStylized = false,
    this.styleIndex = 0,
    this.likedBy = const [],
    this.savedBy = const [],
    this.comments = 0,
    this.isLiked = false,
    this.isSaved = false,
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
      category: data['category'],
      customFields: data['customFields'] != null
          ? Map<String, dynamic>.from(data['customFields'])
          : {},
      tags: List<String>.from(data['tags'] ?? []),
      communityId: data['communityId'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isStylized: data['isStylized'] ?? false,
      styleIndex: data['styleIndex'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      savedBy: List<String>.from(data['savedBy'] ?? []),
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
      'category': category,
      'customFields': customFields,
      'tags': tags,
      'communityId': communityId,
      'imageUrls': imageUrls,
      'isStylized': isStylized,
      'styleIndex': styleIndex,
      'likedBy': likedBy,
      'savedBy': savedBy,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
