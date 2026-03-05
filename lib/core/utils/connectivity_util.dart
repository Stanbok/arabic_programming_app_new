import 'package:connectivity_plus/connectivity_plus.dart';

/// Utility class for checking network connectivity
class ConnectivityUtil {
  ConnectivityUtil._();

  static final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  static Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Check if has connection from results list
  static bool hasConnectionFromResults(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
