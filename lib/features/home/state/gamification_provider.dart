import 'package:flutter_riverpod/flutter_riverpod.dart';

class GamificationState {
  final int xp;
  final int streak;
  final Set<String> badges;
  final int gems;

  const GamificationState({this.xp = 0, this.streak = 0, this.badges = const {}, this.gems = 0});

  GamificationState copyWith({int? xp, int? streak, Set<String>? badges, int? gems}) {
    return GamificationState(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      gems: gems ?? this.gems,
    );
  }
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier() : super(const GamificationState());

  void addXp(int amount) {
    final newXp = state.xp + amount;
    state = state.copyWith(xp: newXp);

    // auto-award badges at XP milestones
    if (newXp >= 100 && !state.badges.contains('bronze')) addBadge('bronze');
    if (newXp >= 300 && !state.badges.contains('silver')) addBadge('silver');
    if (newXp >= 600 && !state.badges.contains('gold')) addBadge('gold');
  }

  void incrementStreak() {
    state = state.copyWith(streak: state.streak + 1);
  }

  void addBadge(String badgeId) {
    final newBadges = {...state.badges, badgeId};
    state = state.copyWith(badges: newBadges);
  }

  void addGems(int amount) {
    state = state.copyWith(gems: state.gems + amount);
  }
}

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});
