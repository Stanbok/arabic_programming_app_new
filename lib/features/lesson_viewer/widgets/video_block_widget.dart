import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';

/// A widget that displays a video with controls.
class VideoBlockWidget extends StatefulWidget {
  final String url;
  final String? caption;
  final String? thumbnail;

  const VideoBlockWidget({
    super.key,
    required this.url,
    this.caption,
    this.thumbnail,
  });

  @override
  State<VideoBlockWidget> createState() => _VideoBlockWidgetState();
}

class _VideoBlockWidgetState extends State<VideoBlockWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showThumbnail = true;

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _showThumbnail = false;
    });

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 8),
              Text(
                'فشل تحميل الفيديو',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      );
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildVideoContent(),
          ),
        ),
        if (widget.caption != null && widget.caption!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.caption!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return Container(
        color: AppColors.dividerLight,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              SizedBox(height: 8),
              Text(
                'فشل تحميل الفيديو',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      );
    }

    if (_showThumbnail) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.thumbnail != null)
            CachedNetworkImage(
              imageUrl: widget.thumbnail!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.black87),
            )
          else
            Container(color: Colors.black87),
          Center(
            child: InkWell(
              onTap: _initializeVideo,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
