import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user model provider
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserNotifier(authService);
});

final currentUserProvider = userProvider;

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(const AsyncValue.loading()) {
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      // First try to get cached user
      final cachedUser = await _authService.getCachedUser();
      
      if (cachedUser != null) {
        state = AsyncValue.data(cachedUser);
      } else if (_authService.currentUser == null) {
        // No cached user and not signed in, sign in anonymously
        final user = await _authService.signInAnonymously();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInAnonymously();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> linkWithGoogle() async {
    try {
      final user = await _authService.linkWithGoogle();
      if (user != null) {
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    String? displayName,
    int? selectedAvatarIndex,
  }) async {
    try {
      final user = await _authService.updateUserProfile(
        displayName: displayName,
        selectedAvatarIndex: selectedAvatarIndex,
      );
      if (user != null) {
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addXp(int xp) async {
    try {
      final user = await _authService.updateUserStats(addXp: xp);
      if (user != null) {
        state = AsyncValue.data(user);
      }
    } catch (e) {
      // Silent fail for XP updates
    }
  }

  Future<void> updateStreak(int streak) async {
    try {
      final user = await _authService.updateUserStats(newStreak: streak);
      if (user != null) {
        state = AsyncValue.data(user);
      }
    } catch (e) {
      // Silent fail for streak updates
    }
  }

  Future<void> incrementCompletedLessons() async {
    try {
      final user = await _authService.updateUserStats(
        incrementCompletedLessons: true,
      );
      if (user != null) {
        state = AsyncValue.data(user);
      }
    } catch (e) {
      // Silent fail
    }
  }

  void refreshUser() {
    _initUser();
  }
}

// Convenience providers
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

final isAnonymousProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user.valueOrNull?.isAnonymous ?? true;
});

final isPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user.valueOrNull?.isPremium ?? false;
});
