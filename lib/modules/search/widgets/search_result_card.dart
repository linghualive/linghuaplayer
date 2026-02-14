import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/search/search_video_model.dart';
import '../../../modules/player/player_controller.dart';
import '../../../shared/widgets/cached_image.dart';

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
    return InkWell(
      onTap: () {
        final playerCtrl = Get.find<PlayerController>();
        playerCtrl.playFromSearch(video);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedImage(
              imageUrl: video.pic,
              width: 160,
              height: 100,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      video.author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatPlay(video.play),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.comment_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatPlay(video.danmaku),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          video.duration,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
