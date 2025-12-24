import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/constants/app_colors.dart';
import '../../../data/models/path_model.dart';
import '../../../data/repositories/progress_repository.dart'
    show ContentLockState;

class PathCard extends StatefulWidget {
  final PathModel path;
  final ContentLockState lockState;
  final double progress;
  final VoidCallback onTap;

  const PathCard({
    super.key,
    required this.path,
    required this.lockState,
    required this.progress,
    required this.onTap,
  });

  @override
  State<PathCard> createState() => _PathCardState();
}

class _PathCardState extends State<PathCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.lockState == ContentLockState.locked;
    final isCompleted = widget.lockState == ContentLockState.completed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: isLocked
                ? []
                : [
                    BoxShadow(
                      color: (isCompleted
                              ? AppColors.success
                              : AppColors.primary)
                          .withOpacity(_isPressed ? 0.2 : 0.15),
                      blurRadius: _isPressed ? 20 : 24,
                      offset: Offset(0, _isPressed ? 6 : 8),
                      spreadRadius: _isPressed ? -2 : 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: _buildBackgroundGradient(
                    isDark, isLocked, isCompleted),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success.withOpacity(0.4)
                      : isLocked
                          ? AppColors.dividerLight.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.3),
                  width: isCompleted ? 2 : 1,
                ),
              ),
              child: Opacity(
                opacity: isLocked ? 0.65 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Icon + Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEnhancedIcon(isLocked, isCompleted),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.path.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                            ),
                                      ),
                                    ),
                                    if (widget.path.isVIP)
                                      _buildVIPBadge(),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.path.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                        height: 1.4,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bottom row: Level chip + Progress + Status
                      Row(
                        children: [
                          _buildLevelChip(context),
                          const Spacer(),
                          _buildCircularProgress(isLocked, isCompleted),
                          const SizedBox(width: 12),
                          _buildStatusIcon(isLocked, isCompleted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _buildBackgroundGradient(
      bool isDark, bool isLocked, bool isCompleted) {
    if (isCompleted) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                AppColors.success.withOpacity(0.15),
                AppColors.surfaceDark,
              ]
            : [
                AppColors.success.withOpacity(0.08),
                AppColors.surfaceLight,
              ],
      );
    }

    if (isLocked) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                AppColors.surfaceDark,
                AppColors.surfaceDark,
              ]
            : [
                AppColors.surfaceLight.withOpacity(0.5),
                AppColors.surfaceLight,
              ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.primary.withOpacity(0.12),
              AppColors.surfaceDark,
            ]
          : [
              AppColors.primary.withOpacity(0.06),
              AppColors.surfaceLight,
            ],
    );
  }

  Widget _buildEnhancedIcon(bool isLocked, bool isCompleted) {
    final color = isCompleted
        ? AppColors.success
        : isLocked
            ? AppColors.locked
            : AppColors.primary;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getPathIcon(),
          color: color,
          size: 36,
        ),
      ),
    );
  }

  IconData _getPathIcon() {
    switch (widget.path.order) {
      case 1:
        return Icons.play_circle_outline_rounded;
      case 2:
        return Icons.alt_route_rounded;
      case 3:
        return Icons.functions_rounded;
      case 4:
        return Icons.data_array_rounded;
      default:
        return Icons.code_rounded;
    }
  }

  Widget _buildVIPBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.vipGold, AppColors.vipGoldLight],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.vipGold.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'VIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.2),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_cellular_alt_rounded,
            size: 14,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            widget.path.level,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(bool isLocked, bool isCompleted) {
    final color = isCompleted
        ? AppColors.success
        : isLocked
            ? AppColors.locked
            : AppColors.primary;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: const Size(48, 48),
            painter: _CircularProgressPainter(
              progress: 1.0,
              color: color.withOpacity(0.15),
              strokeWidth: 4,
            ),
          ),
          // Progress circle
          CustomPaint(
            size: const Size(48, 48),
            painter: _CircularProgressPainter(
              progress: widget.progress,
              color: color,
              strokeWidth: 4,
            ),
          ),
          // Percentage text
          Text(
            '${(widget.progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool isLocked, bool isCompleted) {
    if (isLocked) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.locked.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.locked.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: AppColors.locked,
          size: 24,
        ),
      );
    }

    if (isCompleted) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.success,
              AppColors.success.withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw arc from top (-90 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}