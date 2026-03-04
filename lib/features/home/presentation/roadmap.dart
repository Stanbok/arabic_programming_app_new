import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/unit.dart';
import '../../../core/providers/content_providers.dart';
import '../../home/presentation/unit_card.dart';
import '../../home/state/progress_provider.dart';
import '../../../core/providers/scores_provider.dart';

class Roadmap extends ConsumerWidget {
  const Roadmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);

    return unitsAsync.when(
      data: (units) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        itemCount: units.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final unit = units[index];
          // compute a simple locked state for animation purposes
          final progress = ref.watch(progressProvider);
          final scores = ref.watch(scoresProvider);
          bool lockedForAnim = false;
          final req = unit.unlockRequirement;
          if (req != null) {
            final prev = units.firstWhere((u) => u.id == req.previousUnitId, orElse: () => unit);
            if (prev.id != unit.id) {
              if (req.minScore != null) {
                int total = 0;
                int count = 0;
                for (var lessonId in prev.lessons) {
                  if (scores.containsKey(lessonId)) {
                    total += scores[lessonId]!;
                    count++;
                  }
                }
                if (count == 0) lockedForAnim = true;
                else {
                  final avg = (total / count).round();
                  if (avg < (req.minScore ?? 0)) lockedForAnim = true;
                }
              }
              for (var lessonId in prev.lessons) {
                if ((progress[lessonId] ?? 0.0) < 1.0) lockedForAnim = true;
              }
            }
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // timeline indicator
              Container(
                width: 40,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                    ),
                    if (index < units.length - 1)
                      Container(
                        width: 2,
                        height: 60,
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: UnitCard(key: ValueKey('${unit.id}-${lockedForAnim ? 1 : 0}'), unit: unit),
                ),
              ),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading roadmap')),
    );
  }
}
