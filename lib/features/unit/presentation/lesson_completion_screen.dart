import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LessonCompletionScreen extends StatelessWidget {
  final String lessonId;
  final List<String> takeaways;

  const LessonCompletionScreen({super.key, required this.lessonId, this.takeaways = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson complete')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 72, color: Colors.purple),
            const SizedBox(height: 16),
            const Text('Nice work!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Here are the key takeaways:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ...takeaways.map((t) => Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(child: Text(t)),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // navigate to quiz for this lesson
                GoRouter.of(context).go('/quiz/$lessonId');
              },
              child: const Text("Let's test what we learned"),
            )
          ],
        ),
      ),
    );
  }
}
