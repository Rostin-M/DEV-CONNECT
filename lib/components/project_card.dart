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

  const ProjectCard({
    super.key,
    required this.project,
    required this.currentUserId,
    required this.onTap,
    required this.onLikeToggle,
    required this.onShare,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLiked = project.likes.contains(currentUserId);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final bool hasScreenshots = project.screenshots.isNotEmpty;
    final String mainImageUrl = hasScreenshots
        ? project.screenshots[0]['url']
        : ImageConstants.defaultProjectImage;

    return Card(
      elevation: isDarkMode ? 2 : 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAuthorHeader(context),

            Hero(
              tag: 'project_image_${project.title}',
              child: CachedNetworkImage(
                imageUrl: mainImageUrl,
                fit: BoxFit.cover,
                height: 220,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  height: 220,
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTheme.neutralColor,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildTechTags(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : AppTheme.neutralColor,
                          size: 28,
                        ),
                        onPressed: onLikeToggle,
                      ),
                      Text(project.likes.length.toString()),

                      const SizedBox(width: 12),

                      IconButton(
                        icon: const Icon(
                          Icons.mode_comment_outlined,
                          color: AppTheme.neutralColor,
                          size: 28,
                        ),
                        onPressed: onComment,
                      ),
                      Text(project.commentsCount.toString()),
                    ],
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: AppTheme.neutralColor,
                      size: 28,
                    ),
                    onPressed: onShare,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorHeader(BuildContext context) {
    final avatarUrl = (project.authorAvatar.isNotEmpty)
        ? CachedNetworkImageProvider(project.authorAvatar)
        : const AssetImage('assets/images/default_avatar.png') as ImageProvider;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: avatarUrl,
          radius: 20,
          backgroundColor: Colors.grey[200],
        ),
        title: Text(
          project.authorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Publicado ${project.createdAt.toDate().toLocal().toString().split(' ')[0]}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            project.status,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechTags() {
    return Wrap(
      spacing: 6.0,
      runSpacing: 4.0,
      children: project.tags.take(3).map((tag) {
        return Chip(
          label: Text(tag),
          backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.7),
          labelStyle: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}
