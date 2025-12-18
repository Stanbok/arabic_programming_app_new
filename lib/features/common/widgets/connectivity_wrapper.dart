import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/connectivity_service.dart';

/// A wrapper widget that shows a banner when offline
class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;
  final bool showBannerOnly;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.showBannerOnly = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectivityProvider);

    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isConnected ? 0 : 36,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isConnected ? 0 : 1,
            child: Material(
              color: AppColors.warning,
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.offlineMode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Main content
        Expanded(child: child),
      ],
    );
  }
}
