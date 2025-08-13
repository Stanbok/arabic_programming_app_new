import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';

class WorldMapLessonCard extends StatelessWidget {
  final LessonModel lesson;
  final LessonStatus status;
  final VoidCallback onTap;

  const WorldMapLessonCard({
    Key? key,
    required this.lesson,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: status != LessonStatus.locked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: _getCardColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(context),
            width: 2,
          ),
          boxShadow: status != LessonStatus.locked ? [
            BoxShadow(
              color: _getBorderColor(context).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            // Image Section
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                color: Colors.grey[100],
              ),
              child: Stack(
                children: [
                  // Lesson Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: _buildImage(),
                  ),
                  
                  // Status Overlay
                  if (status == LessonStatus.locked)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  
                  // Status Icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getStatusIconBackground(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: status == LessonStatus.locked ? Colors.grey[600] : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: status != LessonStatus.locked ? onTap : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: status != LessonStatus.locked ? 2 : 0,
                      ),
                      child: Text(
                        _getButtonText(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (lesson.imageUrl != null) {
      if (lesson.imageUrl!.startsWith('assets/')) {
        // Local image
        return Image.asset(
          lesson.imageUrl!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      } else if (lesson.imageUrl!.startsWith('http')) {
        // Network image
        return Image.network(
          lesson.imageUrl!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      }
    }
    
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.code,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

  Color _getCardColor() {
    switch (status) {
      case LessonStatus.completed:
        return Colors.green.withOpacity(0.1);
      case LessonStatus.open:
        return Colors.white;
      case LessonStatus.locked:
        return Colors.grey[100]!;
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (status) {
      case LessonStatus.completed:
        return Colors.green;
      case LessonStatus.open:
        return Theme.of(context).colorScheme.primary;
      case LessonStatus.locked:
        return Colors.grey;
    }
  }

  Color _getStatusIconBackground() {
    switch (status) {
      case LessonStatus.completed:
        return Colors.green;
      case LessonStatus.open:
        return Colors.blue;
      case LessonStatus.locked:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case LessonStatus.completed:
        return Icons.check;
      case LessonStatus.open:
        return Icons.play_arrow;
      case LessonStatus.locked:
        return Icons.lock;
    }
  }

  Color _getButtonColor(BuildContext context) {
    switch (status) {
      case LessonStatus.completed:
        return Colors.green;
      case LessonStatus.open:
        return Theme.of(context).colorScheme.primary;
      case LessonStatus.locked:
        return Colors.grey;
    }
  }

  String _getButtonText() {
    switch (status) {
      case LessonStatus.completed:
        return 'راجع';
      case LessonStatus.open:
        return 'ابدأ';
      case LessonStatus.locked:
        return 'مغلق';
    }
  }
}
