import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_widget.dart';
import 'shimmer_loading.dart';

/// A generic widget for handling AsyncValue states
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace? stackTrace)? error;
  final VoidCallback? onRetry;
  final bool skipLoadingOnRefresh;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
    this.skipLoadingOnRefresh = true,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading?.call() ?? _defaultLoading(),
      error: (e, st) => error?.call(e, st) ?? _defaultError(e),
      skipLoadingOnRefresh: skipLoadingOnRefresh,
    );
  }

  Widget _defaultLoading() {
    return const Center(
      child: CardContentShimmer(),
    );
  }

  Widget _defaultError(Object e) {
    return AppErrorWidget(
      error: e,
      onRetry: onRetry,
    );
  }
}

/// A sliver version for CustomScrollView
class AsyncValueSliverWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace? stackTrace)? error;
  final VoidCallback? onRetry;

  const AsyncValueSliverWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading?.call() ?? _defaultLoading(),
      error: (e, st) => error?.call(e, st) ?? _defaultError(e),
    );
  }

  Widget _defaultLoading() {
    return const SliverFillRemaining(
      child: Center(
        child: CardContentShimmer(),
      ),
    );
  }

  Widget _defaultError(Object e) {
    return SliverFillRemaining(
      child: AppErrorWidget(
        error: e,
        onRetry: onRetry,
      ),
    );
  }
}
