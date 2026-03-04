import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/unit.dart';
import '../../../core/providers/content_providers.dart';
import '../../home/state/gamification_provider.dart';
import 'unit_card.dart';
import 'roadmap.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final gamification = ref.watch(gamificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Units'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(child: Text('XP: ${gamification.xp}')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(child: Text('Streak: ${gamification.streak}')),
          ),
        ],
      ),
      body: const Roadmap(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Units')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: units.length,
        itemBuilder: (context, i) => UnitCard(unit: units[i]),
      ),
    );
  }
}
