import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:share_plus/share_plus.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/providers/feed_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/models/post_model.dart';
import '../core/models/comment_model.dart';
import '../core/providers/notification_provider.dart';
import 'notifications/notifications_screen.dart';
import 'profile/public_profile_screen.dart';
import 'network/network_screen.dart';
import 'profile/cv_edit_screen.dart';
import 'profile/cover_letter_screen.dart';
import 'profile/portfolio_edit_screen.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/expandable_text.dart';
import '../widgets/empty_state_widget.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import '../core/providers/opportunity_provider.dart';
import 'opportunities_screen.dart';
import 'publish/add_project_dialog.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import '../widgets/subscription_reminder_banner.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedProvider>().loadMorePosts();
    }
    
    if (_scrollController.position.pixels > 300) {
      if (!_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      }
    } else {
      if (_showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.unreadCount == 0)
                      return SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${provider.unreadCount}',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(PhosphorIcons.magnifyingGlass()),
            tooltip: 'Recherche',
            onPressed: () {
              context.push('/search');
            },
          ),
          IconButton(
            icon: Icon(PhosphorIcons.users()),
            tooltip: 'Mon Réseau',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NetworkScreen()),
              );
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
      body: Column(
        children: [
          const SubscriptionReminderBanner(),
          const _DocumentGeneratorsHeader(),
          Expanded(
            child: Consumer<FeedProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.posts.isEmpty) {
                  return ListView.builder(
                    itemCount: 5,
                    padding: const EdgeInsets.only(top: 16),
                    itemBuilder: (context, index) {
                      return const ShimmerPostCard();
                    },
                  );
                }
                final posts = provider.posts;
                
                if (posts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<FeedProvider>().loadPosts(refresh: true);
                    },
                    child: const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: EmptyStateWidget(
                        title: 'Fil d\'actualité vide',
                        message: 'Soyez le premier à publier un projet portfolio !',
                        icon: PhosphorIconsLight.briefcase,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<FeedProvider>().loadPosts(refresh: true);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: posts.length + (provider.hasMore ? 1 : 0) + 1, // +1 for Inspiration header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Inspiration & Projets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      
                      final postIndex = index - 1;
                      if (postIndex == posts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: ShimmerPostCard(),
                        );
                      }
                      return PostCard(post: posts[postIndex]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollToTop) ...[
            FloatingActionButton(
              heroTag: 'scrollToTopBtn',
              mini: true,
              onPressed: _scrollToTop,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: AppColors.primary,
              child: Icon(PhosphorIcons.caretUp()),
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: 'addProjectBtn',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddProjectDialog(),
              );
            },
            child: Icon(PhosphorIcons.briefcase()),
            tooltip: 'Ajouter un projet',
          ),
        ],
      ),
    );
  }


}

class _DocumentGeneratorsHeader extends StatelessWidget {
  const _DocumentGeneratorsHeader();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    if (user == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildGeneratorCard(
                  context,
                  title: 'Mon CV',
                  icon: PhosphorIcons.fileText(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CVEditScreen(user: user),
                      ),
                    );
                  }, 
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGeneratorCard(
                  context,
                  title: 'Lettre',
                  icon: PhosphorIcons.envelopeSimple(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CoverLetterScreen(),
                      ),
                    );
                  }, 
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGeneratorCard(
                  context,
                  title: 'Portfolio',
                  icon: PhosphorIcons.briefcase(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PortfolioEditScreen(user: user),
                      ),
                    );
                  }, 
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black87;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final post = widget.post;
    final provider = context.watch<FeedProvider>();
    final userCache = provider.usersCache[post.authorId];

    final displayAvatar = userCache?.photoURL.isNotEmpty == true
        ? userCache!.photoURL
        : post.authorAvatar;
    final displayName = userCache?.name.isNotEmpty == true
        ? userCache!.name
        : post.authorName;
    final displayRole = userCache?.professionalTitle.isNotEmpty == true
        ? userCache!.professionalTitle
        : post.authorRole;

    Widget contentWidget;
    bool shouldBeStylized = post.isStylized && post.imageUrls.isEmpty;

    if (shouldBeStylized) {
      final gradients = [
        [AppColors.primary, const Color(0xFFEA580C)], // Orange
        [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)], // Purple
        [AppColors.success, const Color(0xFF047857)], // Emerald
        [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // Blue
        [const Color(0xFFEC4899), const Color(0xFFBE185D)], // Pink
      ];
      final styleIndex = post.styleIndex < gradients.length
          ? post.styleIndex
          : 0;
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
          style: TextStyle(
            fontSize: 22,
            height: 1.4,
            color: Theme.of(context).cardColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      contentWidget = ExpandableText(
        text: post.content,
        maxLines: 5,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24), // Softer corners
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.03),
              blurRadius: 8,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PublicProfileScreen(userId: post.authorId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: displayAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(displayAvatar)
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      child: displayAvatar.isEmpty
                          ? Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (userCache?.isVerified == true) ...[
                                SizedBox(width: 4),
                                Icon(PhosphorIcons.sealCheck(PhosphorIconsStyle.fill), color: AppColors.primary, size: 16),
                              ],
                            ],
                          ),
                          Text(
                            displayRole,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey.shade400 
                                  : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        PhosphorIcons.dotsThree(),
                        color: Colors.grey.shade600,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Supprimer la publication'),
                              content: Text(
                                'Êtes-vous sûr de vouloir supprimer cette publication ? Cette action est irréversible.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Annuler',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<FeedProvider>().deletePost(
                                      post.id,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (value == 'report') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Publication signalée.'),
                            ),
                          );
                        } else if (value == 'copy') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lien copié !')),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        if (FirebaseAuth.instance.currentUser?.uid ==
                            post.authorId)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('Signaler'),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Copier le lien'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              if (post.category != null && post.category != 'Général' && post.category != 'community_portfolio') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.category!,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
              if (post.category == 'community_portfolio' && post.customFields.containsKey('nom_projet')) ...[
                Text(
                  post.customFields['nom_projet'].toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              contentWidget,
              if (post.category == 'community_portfolio') ...[
                if (post.customFields.containsKey('outils')) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '🛠 Outils utilisés',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.customFields['outils'].toString()
                        .split(',')
                        .map((tool) => tool.trim())
                        .where((tool) => tool.isNotEmpty)
                        .map((tool) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tool,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (post.customFields.containsKey('lecons')) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4), // Light green
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              '💡 Leçons apprises',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.customFields['lecons'].toString(),
                          style: const TextStyle(color: Color(0xFF14532D), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (post.category != 'community_portfolio' && post.customFields.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Theme.of(context).cardColor.withValues(alpha: 0.05) 
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: post.customFields.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ${e.key.replaceAll('_', ' ').replaceFirst(e.key[0], e.key[0].toUpperCase())}: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value.toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.grey.shade300 
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                SizedBox(height: 12),
              ],
              if (post.tags.isNotEmpty) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: post.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (post.imageUrls.isNotEmpty) ...[
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: post.imageUrls.first,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 40,
                              right: 20,
                              child: IconButton(
                                icon: Icon(Icons.close, color: Theme.of(context).cardColor, size: 30),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrls.first,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        height: 250,
                        color: Colors.grey.shade200,
                        child: Center(child: Icon(Icons.error_outline)),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InteractionButton(
                    icon: PhosphorIcons.heart(
                      post.isLiked
                          ? PhosphorIconsStyle.fill
                          : PhosphorIconsStyle.regular,
                    ),
                    iconColor: post.isLiked ? Colors.red : Colors.grey.shade600,
                    count: post.likedBy.length.toString(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<FeedProvider>().toggleLike(post.id);
                    },
                  ),
                  _InteractionButton(
                    icon: PhosphorIcons.chatCircle(),
                    iconColor: Colors.grey.shade600,
                    count: post.comments.toString(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) => CommentsSheet(postId: post.id),
                      );
                    },
                  ),
                  _InteractionButton(
                    icon: PhosphorIcons.shareNetwork(),
                    iconColor: Colors.grey.shade600,
                    count: '',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      final String shareText =
                          "Découvrez l'expérience de ${post.authorName} sur Kaïro !\n\n${post.content}\n\nhttps://kairo.app/experience/${post.id}";
                      Share.share(shareText);
                    },
                  ),
                  _InteractionButton(
                    icon: PhosphorIcons.bookmarkSimple(
                      post.isSaved
                          ? PhosphorIconsStyle.fill
                          : PhosphorIconsStyle.regular,
                    ),
                    iconColor: post.isSaved
                        ? AppColors.primary
                        : Colors.grey.shade600,
                    count: '',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<FeedProvider>().toggleSave(post.id);
                    },
                  ),
                ],
              ),
            ],
          ),
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
              SizedBox(width: 6),
              Text(
                count,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final String postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;

  String? replyingToId;
  Stream<List<CommentModel>>? _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = context.read<FeedProvider>().getComments(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _replyTo(String authorName, String commentId) {
    setState(() {
      replyingToId = commentId;
    });
    _commentController.text = '@$authorName ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    _focusNode.requestFocus();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<FeedProvider>().addComment(
        widget.postId,
        _commentController.text.trim(),
        parentId: replyingToId,
      );
      if (mounted) {
        setState(() {
          replyingToId = null;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commentaire publié !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la publication.'),
            backgroundColor: Colors.red,
          ),
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
    final user = context.watch<AuthProvider>().userModel;
    if (user == null) return const SizedBox.shrink();
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
          Text(
            'Commentaires',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Divider(height: 32),
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _commentsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('Chargement...'));
                }
                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'Soyez le premier à commenter !',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                final rootComments = comments
                    .where((c) => c.parentId == null)
                    .toList();
                final childComments = <String, List<CommentModel>>{};
                for (var c in comments.where((c) => c.parentId != null)) {
                  childComments.putIfAbsent(c.parentId!, () => []).add(c);
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: rootComments.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = rootComments[index];
                    final replies = childComments[comment.id] ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCommentRow(comment, isReply: false),
                        if (replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 32, top: 12),
                            child: Column(
                              children: replies
                                  .map(
                                    (reply) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _buildCommentRow(
                                        reply,
                                        isReply: true,
                                      ),
                                    ),
                                  )
                                  .toList(),
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
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(
                    'https://ui-avatars.com/api/?name=User&background=F97316&color=fff',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                _isSubmitting
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          PhosphorIcons.paperPlaneRight(
                            PhosphorIconsStyle.fill,
                          ),
                          color: AppColors.primary,
                        ),
                        onPressed: _submitComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentRow(CommentModel comment, {required bool isReply}) {
    final avatar = comment.authorAvatar.isNotEmpty
        ? comment.authorAvatar
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(comment.authorName)}';
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMyComment = currentUserId == comment.authorId;
    final userCache = context.read<FeedProvider>().usersCache[comment.authorId];
    final isVerified = userCache?.isVerified == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PublicProfileScreen(userId: comment.authorId),
              ),
            );
          },
          child: CircleAvatar(
            radius: isReply ? 12 : 16,
            backgroundImage: CachedNetworkImageProvider(avatar),
          ),
        ),
        SizedBox(width: 12),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PublicProfileScreen(userId: comment.authorId),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          comment.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        SizedBox(width: 4),
                        Icon(PhosphorIcons.sealCheck(PhosphorIconsStyle.fill), color: AppColors.primary, size: 14),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(comment.content, style: TextStyle(fontSize: 14)),
                if (!isReply) ...[
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _replyTo(comment.authorName, comment.id),
                    child: Text(
                      'Répondre',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isMyComment)
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Supprimer le commentaire ?'),
                  content: Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.read<FeedProvider>().deleteComment(widget.postId, comment.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Commentaire supprimé')),
                          );
                        }
                      },
                      child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class CreatePostModal extends StatefulWidget {
  const CreatePostModal({super.key});

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  static String _draftContent = '';
  static String _draftTitle = '';
  static String _draftLessons = '';
  static final List<String> _draftTags = [];

  late final TextEditingController _controller; // Description
  late final TextEditingController _titleController;
  late final TextEditingController _lessonsController;
  late final TextEditingController _tagsController; // Tools

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isPublishing = false;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _draftContent);
    _titleController = TextEditingController(text: _draftTitle);
    _lessonsController = TextEditingController(text: _draftLessons);
    _tagsController = TextEditingController(text: _draftTags.join(', '));
    _selectedTags = List.from(_draftTags);

    void saveDraft() {
      _draftContent = _controller.text;
      _draftTitle = _titleController.text;
      _draftLessons = _lessonsController.text;
      _draftTags.clear();
      _draftTags.addAll(_selectedTags);
    }

    _controller.addListener(saveDraft);
    _titleController.addListener(saveDraft);
    _lessonsController.addListener(saveDraft);
    _tagsController.addListener(() {
      _selectedTags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      saveDraft();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _lessonsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer l\'image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Recadrer l\'image'),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImages.add(File(croppedFile.path));
        });
      }
    }
  }

  Future<void> _publish() async {
    if (_titleController.text.isEmpty || _controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir au moins le titre et la description.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    final customFieldsToSave = <String, dynamic>{
      'nom_projet': _titleController.text.trim(),
    };
    if (_lessonsController.text.trim().isNotEmpty) {
      customFieldsToSave['lecons'] = _lessonsController.text.trim();
    }
    if (_tagsController.text.trim().isNotEmpty) {
      customFieldsToSave['outils'] = _tagsController.text.trim();
    }

    try {
      await context.read<FeedProvider>().addPost(
        _controller.text, // Description
        images: _selectedImages,
        isStylized: false,
        styleIndex: 0,
        category: 'community_portfolio', // Enforce Portfolio format
        customFields: customFieldsToSave,
        tags: _selectedTags,
      );

      // Clear draft after successful publish
      _draftContent = '';
      _draftTitle = '';
      _draftLessons = '';
      _draftTags.clear();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet publié dans le Portfolio Communautaire !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                  const Text(
                    'Publier un projet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Titre du projet',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Ex: Refonte du site E-commerce',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Description courte (3 lignes max)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  hintText: 'Quel était l\'objectif ? Comment avez-vous procédé ?',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Outils utilisés (Tags)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: 'Ex: Flutter, Firebase, Figma (séparés par des virgules)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Leçons apprises 💡',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lessonsController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ce que j\'ai appris de ce projet...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
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
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Theme.of(context).cardColor,
                                ),
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
                    icon: Icon(PhosphorIcons.image(), color: AppColors.primary),
                    tooltip: 'Ajouter une image',
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isPublishing ? null : _publish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Theme.of(context).iconTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isPublishing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).cardColor,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Publier le projet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
