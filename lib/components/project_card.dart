import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dev_connect/data/models/project_model.dart';
import 'package:dev_connect/themes/app_theme.dart';
import 'package:dev_connect/constants/image_constants.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onLikeToggle;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.currentUserId,
    required this.onTap,
    required this.onLikeToggle,
    required this.onShare,
    required this.onComment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLiked = project.likes.contains(currentUserId);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final bool isOwner = project.authorId == currentUserId;

    final bool hasScreenshots = project.screenshots.isNotEmpty;
    final String mainImageUrl = hasScreenshots
        ? project.screenshots[0]['url']
        : ImageConstants.defaultProjectImage;

    return Card(
      elevation: isDarkMode ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAuthorHeader(context, isDarkMode, isOwner),
            _buildProjectImage(mainImageUrl, isDarkMode),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildTechTags(isDarkMode),
                  const SizedBox(height: 12),
                  _buildActionButtons(isLiked, isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorHeader(
    BuildContext context,
    bool isDarkMode,
    bool isOwner,
  ) {
    final avatarUrl = project.authorAvatar.isNotEmpty
        ? project.authorAvatar
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(project.authorName)}&background=random&size=200&bold=true';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
            radius: 20,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.authorName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _getTimeAgo(project.createdAt.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              project.status.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          if (isOwner && onDelete != null) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteDialog(context);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar proyecto'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar proyecto'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este proyecto? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onDelete != null) {
                  onDelete!();
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectImage(String imageUrl, bool isDarkMode) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
        placeholder: (context, url) => Container(
          height: 200,
          color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechTags(bool isDarkMode) {
    if (project.tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: project.tags.take(4).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      AppTheme.primaryColor.withValues(alpha: 0.3),
                      AppTheme.secondaryColor.withValues(alpha: 0.3),
                    ]
                  : [
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                      AppTheme.secondaryColor.withValues(alpha: 0.15),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: isDarkMode
                  ? AppTheme.secondaryColor
                  : AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(bool isLiked, bool isDarkMode) {
    final iconColor = isDarkMode ? Colors.grey[300] : Colors.grey[700];
    final textColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: onLikeToggle,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : iconColor,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      project.likes.length.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: onComment,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.mode_comment_outlined,
                      color: iconColor,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      project.commentsCount.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onShare,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.share_outlined, color: iconColor, size: 24),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}a';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Ahora';
    }
  }
}
