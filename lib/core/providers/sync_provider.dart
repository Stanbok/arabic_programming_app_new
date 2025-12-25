import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSync;
  final String? error;

  SyncState({
    this.status = SyncStatus.idle,
    this.lastSync,
    this.error,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSync,
    String? error,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
      error: error ?? this.error,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(SyncState());

  void startSync() {
    state = state.copyWith(status: SyncStatus.syncing, error: null);
  }

  void endSync({bool success = true, String? error}) {
    state = state.copyWith(
      status: success ? SyncStatus.success : SyncStatus.error,
      lastSync: success ? DateTime.now() : state.lastSync,
      error: error,
    );
    
    // Return to idle after a short delay if success
    if (success) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle);
        }
      });
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
