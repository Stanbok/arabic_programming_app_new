import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/content_providers.dart';
import '../../home/state/progress_provider.dart';
import '../../../core/providers/scores_provider.dart';

import '../../../core/models/unit.dart';

class UnitCard extends ConsumerWidget {
  final Unit unit;

  const UnitCard({super.key, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final req = unit.unlockRequirement;
    bool locked = false;
    final unitsAsync = ref.watch(unitsProvider);
    final progress = ref.watch(progressProvider);

    final scores = ref.watch(scoresProvider);
    if (req != null) {
      locked = unitsAsync.maybeWhen(
        data: (units) {
          final prev = units.firstWhere(
              (u) => u.id == req.previousUnitId,
              orElse: () => unit);
          if (prev.id == unit.id) return false;

          // Check minimum score requirement if provided
          if (req.minScore != null) {
            int total = 0;
            int count = 0;
            for (var lessonId in prev.lessons) {
              if (scores.containsKey(lessonId)) {
                total += scores[lessonId]!;
                count++;
              }
            }
            if (count == 0) return true; // locked until scores available
            final avg = (total / count).round();
            if (avg < (req.minScore ?? 0)) return true; // locked
          }

          // fallback: require all previous lessons marked complete
          bool allDone = true;
          for (var lessonId in prev.lessons) {
            if ((progress[lessonId] ?? 0.0) < 1.0) {
              allDone = false;
              break;
            }
          }
          return !allDone;
        },
        orElse: () => true, // locked while loading
      );
    }

    // calculate unit progress as average of lesson progress
    final progressMap = ref.watch(progressProvider);
    double unitProgress = 0.0;
    if (unit.lessons.isNotEmpty) {
      final total = unit.lessons
          .map((id) => progressMap[id] ?? 0.0)
          .fold<double>(0.0, (a, b) => a + b);
      unitProgress = total / unit.lessons.length;
    }

    return Card(
      color: locked ? Colors.grey.shade200 : Colors.white,
      child: ListTile(
        leading: Icon(locked ? Icons.lock : Icons.check_circle,
            color: locked ? Colors.grey : Colors.green),
        title: Text(unit.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unit.description),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: unitProgress),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: locked
            ? null
            : () {
                GoRouter.of(context).go('/unit/${unit.id}');
              },
      ),
    );
  }
}
