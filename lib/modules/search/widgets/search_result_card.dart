import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/search/search_video_model.dart';
import '../../../modules/player/player_controller.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/video_action_buttons.dart';

class SearchResultCard extends StatelessWidget {
  final SearchVideoModel video;

  const SearchResultCard({super.key, required this.video});

  String _formatPlay(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.outline.withValues(alpha: 0.8);
    return InkWell(
      onTap: () {
        final playerCtrl = Get.find<PlayerController>();
        playerCtrl.playFromSearch(video);
      },
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CachedImage(
                imageUrl: video.pic,
                width: 150,
                height: 94,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 94,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      video.author,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 13, color: subtitleColor),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            _formatPlay(video.play),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: subtitleColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.comment_outlined, size: 12, color: subtitleColor),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            _formatPlay(video.danmaku),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: subtitleColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          video.duration,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: subtitleColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            VideoActionColumn(video: video),
          ],
        ),
      ),
    );
  }
}
