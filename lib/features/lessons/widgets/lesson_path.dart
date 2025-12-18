import 'package:flutter/material.dart';
import '../../../models/lesson_model.dart';
import '../../../models/progress_model.dart';
import 'lesson_card.dart';

class LessonPath extends StatelessWidget {
  final List<LessonModel> lessons;
  final Map<String, LessonProgress> progress;
  final ScrollController scrollController;

  const LessonPath({
    super.key,
    required this.lessons,
    required this.progress,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final lesson = lessons[index];
          final lessonProgress = progress[lesson.id];

          // Zig-zag alignment: alternate left/center/right
          final alignmentIndex = index % 3;
          final alignment = switch (alignmentIndex) {
            0 => Alignment.centerRight,
            1 => Alignment.center,
            2 => Alignment.centerLeft,
            _ => Alignment.center,
          };

          // Determine if this is the current lesson (first incomplete)
          final isCurrentLesson = _isCurrentLesson(index);

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Stack(
              children: [
                // Connection line to next lesson
                if (index < lessons.length - 1)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConnectionPainter(
                        startAlignment: alignment,
                        endAlignment: _getAlignment((index + 1) % 3),
                        isCompleted: lessonProgress?.isCompleted ?? false,
                      ),
                    ),
                  ),
                // Lesson card
                Align(
                  alignment: alignment,
                  child: LessonCard(
                    lesson: lesson,
                    progress: lessonProgress,
                    index: index,
                    isCurrentLesson: isCurrentLesson,
                  ),
                ),
              ],
            ),
          );
        },
        childCount: lessons.length,
      ),
    );
  }

  bool _isCurrentLesson(int index) {
    // First lesson is current if no progress
    if (index == 0 && !progress.containsKey(lessons[0].id)) {
      return true;
    }

    // Check if previous is complete but this one isn't
    if (index > 0) {
      final previousProgress = progress[lessons[index - 1].id];
      final currentProgress = progress[lessons[index].id];

      if (previousProgress?.isCompleted == true &&
          currentProgress?.isCompleted != true) {
        return true;
      }
    }

    return false;
  }

  Alignment _getAlignment(int index) {
    return switch (index) {
      0 => Alignment.centerRight,
      1 => Alignment.center,
      2 => Alignment.centerLeft,
      _ => Alignment.center,
    };
  }
}

class _ConnectionPainter extends CustomPainter {
  final Alignment startAlignment;
  final Alignment endAlignment;
  final bool isCompleted;

  _ConnectionPainter({
    required this.startAlignment,
    required this.endAlignment,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted
          ? const Color(0xFF22C55E).withOpacity(0.5)
          : const Color(0xFFCBD5E1).withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startX = _getX(startAlignment, size.width);
    final endX = _getX(endAlignment, size.width);

    final path = Path();
    path.moveTo(startX, 40); // Start below current card
    path.quadraticBezierTo(
      (startX + endX) / 2,
      size.height / 2,
      endX,
      size.height - 40, // End above next card
    );

    canvas.drawPath(path, paint);
  }

  double _getX(Alignment alignment, double width) {
    if (alignment == Alignment.centerRight) return width * 0.75;
    if (alignment == Alignment.centerLeft) return width * 0.25;
    return width * 0.5;
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) {
    return oldDelegate.isCompleted != isCompleted;
  }
}
