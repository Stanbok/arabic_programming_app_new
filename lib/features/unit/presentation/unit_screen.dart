import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/unit.dart';
import '../../../core/models/lesson.dart';
import '../../../core/providers/content_providers.dart';
import '../../home/state/progress_provider.dart';

class UnitScreen extends ConsumerWidget {
  final String unitId;

  const UnitScreen({super.key, required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final lessonsAsync = ref.watch(lessonsForUnitProvider(unitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Unit')), // could show dynamic title
      body: unitsAsync.when(
        data: (units) {
          final unit = units.firstWhere((u) => u.id == unitId);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(unit.title, style: Theme.of(context).textTheme.headlineMedium),
              ),
              Expanded(
                child: lessonsAsync.when(
                  data: (lessons) => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lessons.length,
                    itemBuilder: (context, i) {
                      final lesson = lessons[i];
                      final prog = ref.watch(progressProvider)[lesson.id] ?? 0.0;
                      final locked = i > 0 && prog < 1.0;
                      return AnimatedOpacity(
                        opacity: locked ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: Card(
                          color: locked ? Colors.grey.shade200 : Colors.white,
                          child: ListTile(
                            title: Text(lesson.title),
                            subtitle: LinearProgressIndicator(value: prog),
                            trailing: Icon(locked ? Icons.lock : Icons.arrow_forward_ios,
                                size: 16),
                            onTap: locked
                                ? null
                                : () {
                                    GoRouter.of(context).go('/lesson/${lesson.id}');
                                  },
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error loading lessons')),
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading unit')),
      ),
    );
  }
}

// LessonScreen import is not required; navigation uses go_router
