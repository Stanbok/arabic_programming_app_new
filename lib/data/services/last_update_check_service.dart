import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';
import '../models/manifest/update_check_model.dart';

/// Service for tracking when the last update check was performed
/// 
/// Enforces daily-only update checks:
/// - First app launch of the day triggers update check
/// - Subsequent launches skip the check
/// - Tracks last known global manifest version
/// - Stores pending update notification state
class LastUpdateCheckService {
  LastUpdateCheckService._();
  static final LastUpdateCheckService instance = LastUpdateCheckService._();

  Box<UpdateCheckModel>? _updateCheckBox;

  Box<UpdateCheckModel> get _box {
    _updateCheckBox ??= Hive.box<UpdateCheckModel>(HiveBoxes.updateCheck);
    return _updateCheckBox!;
  }

  /// Get current update check state
  UpdateCheckModel _getOrCreateState() {
    var state = _box.get(HiveKeys.lastUpdateCheck);
    if (state == null) {
      state = UpdateCheckModel.initial();
      _box.put(HiveKeys.lastUpdateCheck, state);
    }
    return state;
  }

  /// Check if we should perform an update check
  /// Returns true only on first launch of the day
  bool shouldCheckForUpdates() {
    final state = _getOrCreateState();
    return state.shouldCheckToday();
  }

  /// Record that an update check was performed
  Future<void> recordUpdateCheck({
    required int globalManifestVersion,
    bool updateAvailable = false,
    String? updateMessage,
  }) async {
    final newState = UpdateCheckModel(
      lastCheckDate: DateTime.now(),
      lastGlobalVersion: globalManifestVersion,
      updateAvailable: updateAvailable,
      updateMessage: updateMessage,
    );
    await _box.put(HiveKeys.lastUpdateCheck, newState);
  }

  /// Get the last known global manifest version
  int getLastKnownGlobalVersion() {
    return _getOrCreateState().lastGlobalVersion;
  }

  /// Check if there's a pending update notification
  bool hasPendingUpdateNotification() {
    return _getOrCreateState().updateAvailable;
  }

  /// Get the pending update message
  String? getPendingUpdateMessage() {
    return _getOrCreateState().updateMessage;
  }

  /// Clear the pending update notification (user dismissed it)
  Future<void> clearUpdateNotification() async {
    final current = _getOrCreateState();
    final updated = UpdateCheckModel(
      lastCheckDate: current.lastCheckDate,
      lastGlobalVersion: current.lastGlobalVersion,
      updateAvailable: false,
      updateMessage: null,
    );
    await _box.put(HiveKeys.lastUpdateCheck, updated);
  }

  /// Get last check date
  DateTime getLastCheckDate() {
    return _getOrCreateState().lastCheckDate;
  }

  /// Force next launch to check for updates (for testing/debugging)
  Future<void> forceNextCheck() async {
    final current = _getOrCreateState();
    final updated = UpdateCheckModel(
      lastCheckDate: DateTime(2000), // Old date forces check
      lastGlobalVersion: current.lastGlobalVersion,
      updateAvailable: current.updateAvailable,
      updateMessage: current.updateMessage,
    );
    await _box.put(HiveKeys.lastUpdateCheck, updated);
  }

  /// Reset all update check state
  Future<void> reset() async {
    await _box.put(HiveKeys.lastUpdateCheck, UpdateCheckModel.initial());
  }
}
