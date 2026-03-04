import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/lesson.dart';
import '../../../core/providers/content_providers.dart';
import '../../home/state/progress_provider.dart';
import '../../home/state/gamification_provider.dart';
import '../../../core/widgets/code_view.dart';
import 'lesson_completion_screen.dart';

class LessonScreen extends ConsumerWidget {
  final String lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(contentLessonProvider(lessonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: lessonsAsync.when(
        data: (lesson) {
          // simple scrollable content rendering
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(lesson.title, style: Theme.of(context).textTheme.headline5),
              const SizedBox(height: 12),
              ...lesson.content.map((block) => _buildBlock(block)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Show a completion/recap screen first. Actual lesson completion is awarded after passing the quiz.
                  final takeaways = lesson.content
                      .whereType<TextBlock>()
                      .take(3)
                      .map((b) => b.value)
                      .toList();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LessonCompletionScreen(lessonId: lesson.id, takeaways: takeaways)));
                },
                child: const Text('I finished reading'),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lesson not found')),
      ),
    );
  }

  Widget _buildBlock(ContentBlock block) {
    return block.when(
      text: (value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: MarkdownBody(data: value),
      ),
      tip: (value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Card(
          color: Colors.yellow.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [const Icon(Icons.lightbulb, color: Colors.amber), const SizedBox(width: 8), Expanded(child: Text(value))]),
          ),
        ),
      ),
      warning: (value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [const Icon(Icons.warning, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text(value))]),
          ),
        ),
      ),
      interactive: (payload) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Interactive example'), const SizedBox(height: 8), Text(payload.toString())]),
          ),
        ),
      ),
      list: (items) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(children: items.map((e) => Row(children: [const Icon(Icons.circle, size: 8), const SizedBox(width: 8), Expanded(child: Text(e))])).toList()),
      ),
      code: (value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: CodeView(code: value),
      ),
      image: (url) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Image.network(url),
      ),
      video: (url) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Video: $url', style: const TextStyle(color: Colors.blue)),
      ),
    );
  }
}
