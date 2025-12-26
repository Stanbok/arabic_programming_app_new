import 'package:hive/hive.dart';

part 'update_check_model.g.dart';

/// Tracks when the last update check was performed
/// Used to enforce daily-only update checks
@HiveType(typeId: 11)
class UpdateCheckModel extends HiveObject {
  @HiveField(0)
  final DateTime lastCheckDate;

  @HiveField(1)
  final int lastGlobalVersion;

  @HiveField(2)
  final bool updateAvailable;

  @HiveField(3)
  final String? updateMessage;

  UpdateCheckModel({
    required this.lastCheckDate,
    required this.lastGlobalVersion,
    this.updateAvailable = false,
    this.updateMessage,
  });

  /// Check if we should perform an update check today
  bool shouldCheckToday() {
    final now = DateTime.now();
    final lastCheck = DateTime(
      lastCheckDate.year,
      lastCheckDate.month,
      lastCheckDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(lastCheck);
  }

  /// Create initial state (forces check on first run)
  factory UpdateCheckModel.initial() {
    return UpdateCheckModel(
      lastCheckDate: DateTime(2000),
      lastGlobalVersion: 0,
      updateAvailable: false,
    );
  }
}
