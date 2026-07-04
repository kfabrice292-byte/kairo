import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/providers/feed_provider.dart';
import '../core/models/post_model.dart';
import '../core/models/comment_model.dart';
import '../core/providers/community_provider.dart';
import '../core/providers/notification_provider.dart';
import 'community/community_detail_screen.dart';
import 'community/community_discovery_screen.dart';
import 'community/create_community_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/public_profile_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 32),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(PhosphorIcons.bell()),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.unreadCount == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '${provider.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(PhosphorIcons.users()),
            tooltip: 'Réseau & Membres',
            onPressed: () {
              context.push('/search');
            },
          ),
          IconButton(
            icon: Icon(PhosphorIcons.paperPlaneRight()),
            onPressed: () {
              context.push('/chat_list');
            },
          ),
        ],
      ),
      body: Consumer<FeedProvider>(
        builder: (context, provider, child) {
          final posts = provider.posts;
          return ListView.builder(
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCommunities(context);
              }
              return PostCard(post: posts[index - 1]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreatePostModal(),
          );
        },
        child: Icon(PhosphorIcons.pencilSimple()),
      ),
    );
  }
  Widget _buildCommunities(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final communities = provider.communities;

    if (provider.isLoading) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Communautés',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityDiscoveryScreen()));
                  },
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(fontSize: 14, color: Color(0xFFF97316), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: communities.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Bouton "Créer"
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateCommunityScreen()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1.5, style: BorderStyle.solid),
                            ),
                            child: const Icon(Icons.add, color: Colors.grey, size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text('Créer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                final comm = communities[index - 1];
                final color = Color(int.tryParse(comm.colorHex, radix: 16) ?? 0xFF3B82F6);
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityDetailScreen(community: comm),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.7), color],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                            border: comm.members.contains(FirebaseAuth.instance.currentUser?.uid) 
                                ? Border.all(color: const Color(0xFFF97316), width: 2) 
                                : null,
                          ),
                          child: const Icon(Icons.people, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            comm.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;
    if (post.isStylized) {
      final gradients = [
        [const Color(0xFFF97316), const Color(0xFFEA580C)], // Orange
        [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)], // Purple
        [const Color(0xFF10B981), const Color(0xFF047857)], // Emerald
        [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // Blue
        [const Color(0xFFEC4899), const Color(0xFFBE185D)], // Pink
      ];
      final styleIndex = post.styleIndex < gradients.length ? post.styleIndex : 0;
      final selectedGradient = gradients[styleIndex];

      contentWidget = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selectedGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          post.content,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, height: 1.4, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      contentWidget = Text(
        post.content,
        style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PublicProfileScreen(userId: post.authorId),
                ));
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: post.authorAvatar.isNotEmpty 
                        ? NetworkImage(post.authorAvatar) 
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    child: post.authorAvatar.isEmpty 
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          post.authorRole,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (FirebaseAuth.instance.currentUser?.uid == post.authorId)
                  PopupMenuButton<String>(
                    icon: Icon(PhosphorIcons.dotsThree(), color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer la publication'),
                            content: const Text('Êtes-vous sûr de vouloir supprimer cette publication ? Cette action est irréversible.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<FeedProvider>().deletePost(post.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            contentWidget,
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrls.first,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.error_outline)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InteractionButton(
                  icon: PhosphorIcons.heart(post.isLiked ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular), 
                  iconColor: post.isLiked ? Colors.red : Colors.grey.shade600,
                  count: post.likedBy.length.toString(),
                  onTap: () => context.read<FeedProvider>().toggleLike(post.id),
                ),
                _InteractionButton(
                  icon: PhosphorIcons.chatCircle(),
                  iconColor: Colors.grey.shade600,
                  count: post.comments.toString(),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (context) => _CommentsSheet(postId: post.id),
                    );
                  },
                ),
                _InteractionButton(
                  icon: PhosphorIcons.shareNetwork(),
                  iconColor: Colors.grey.shade600,
                  count: '',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lien copié dans le presse-papiers !'),
                        backgroundColor: Color(0xFFF97316),
                      ),
                    );
                  },
                ),
                _InteractionButton(
                  icon: PhosphorIcons.bookmarkSimple(post.isSaved ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
                  iconColor: post.isSaved ? const Color(0xFF1E293B) : Colors.grey.shade600,
                  count: '',
                  onTap: () => context.read<FeedProvider>().toggleSave(post.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color iconColor;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.count,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            if (count.isNotEmpty && count != '0') ...[
              const SizedBox(width: 6),
              Text(count, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;

  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _replyTo(String authorName) {
    _commentController.text = '@$authorName ';
    _focusNode.requestFocus();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<FeedProvider>().addComment(widget.postId, _commentController.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire publié !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la publication.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('Commentaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(height: 32),
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: context.read<FeedProvider>().getComments(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
                }
                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return Center(
                    child: Text('Soyez le premier à commenter !', 
                      style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final avatar = comment.authorAvatar.isNotEmpty 
                        ? comment.authorAvatar 
                        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(comment.authorName)}';
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => PublicProfileScreen(userId: comment.authorId),
                            ));
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(avatar),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (context) => PublicProfileScreen(userId: comment.authorId),
                                    ));
                                  },
                                  child: Text(
                                    comment.authorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _replyTo(comment.authorName),
                                  child: const Text(
                                    'Répondre',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF97316),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=User&background=F97316&color=fff'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                _isSubmitting 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), color: const Color(0xFFF97316)),
                      onPressed: _submitComment,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePostModal extends StatefulWidget {
  const CreatePostModal({super.key});

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isPublishing = false;
  bool _isStylized = false;
  int _styleIndex = 0;

  final List<List<Color>> gradients = [
    [const Color(0xFFF97316), const Color(0xFFEA580C)], // Orange
    [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)], // Purple
    [const Color(0xFF10B981), const Color(0xFF047857)], // Emerald
    [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // Blue
    [const Color(0xFFEC4899), const Color(0xFFBE185D)], // Pink
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _publish() async {
    if (_controller.text.isEmpty && _selectedImages.isEmpty) return;

    setState(() {
      _isPublishing = true;
    });

    await context.read<FeedProvider>().addPost(
      _controller.text,
      images: _selectedImages,
      isStylized: _isStylized,
      styleIndex: _styleIndex,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Créer un post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Texte Simple'),
                  selected: !_isStylized,
                  onSelected: (val) => setState(() => _isStylized = false),
                  selectedColor: const Color(0xFFF97316).withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: !_isStylized ? const Color(0xFFF97316) : Colors.grey.shade600, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                  backgroundColor: Colors.grey.shade100,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Carte Stylisée ✨'),
                  selected: _isStylized,
                  onSelected: (val) => setState(() => _isStylized = true),
                  selectedColor: const Color(0xFFF97316).withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: _isStylized ? const Color(0xFFF97316) : Colors.grey.shade600, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                  backgroundColor: Colors.grey.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isStylized) ...[
              Wrap(
                spacing: 8,
                children: List.generate(gradients.length, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _styleIndex = index),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: gradients[index]),
                        border: _styleIndex == index
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: _styleIndex == index
                            ? [BoxShadow(color: gradients[index][0].withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _isStylized 
                    ? LinearGradient(colors: gradients[_styleIndex], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: _isStylized ? null : Colors.grey.shade100,
              ),
              child: TextField(
                controller: _controller,
                maxLines: _isStylized ? 6 : 4,
                textAlign: _isStylized ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: _isStylized ? Colors.white : Colors.black87,
                  fontSize: _isStylized ? 20 : 16,
                  fontWeight: _isStylized ? FontWeight.w600 : FontWeight.normal,
                ),
                decoration: InputDecoration(
                  hintText: _isStylized ? 'Votre citation ou idée forte...' : 'Partagez votre expérience...',
                  hintStyle: TextStyle(
                    color: _isStylized ? Colors.white70 : Colors.grey.shade500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 10,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(PhosphorIcons.image(), color: const Color(0xFFF97316)),
                  tooltip: 'Ajouter une image',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isPublishing ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPublishing 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
