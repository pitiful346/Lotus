import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const lotusQualityAccent = Color(0xFFB7F34A);
const lotusQualityMuted = Color(0xFF9AA8B9);

enum LotusStateKind { empty, error, offline, information }

/// Consistent empty/error/offline panel with a screen-reader live region.
class LotusStateView extends StatelessWidget {
  const LotusStateView({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final LotusStateKind kind;
  final String title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon =
        icon ??
        switch (kind) {
          LotusStateKind.empty => Icons.inbox_outlined,
          LotusStateKind.error => Icons.error_outline_rounded,
          LotusStateKind.offline => Icons.cloud_off_outlined,
          LotusStateKind.information => Icons.info_outline_rounded,
        };
    final isLiveRegion =
        kind == LotusStateKind.error || kind == LotusStateKind.offline;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              container: true,
              liveRegion: isLiveRegion,
              label: '$title. $message',
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      resolvedIcon,
                      color: lotusQualityMuted,
                      size: compact ? 32 : 46,
                    ),
                    SizedBox(height: compact ? 8 : 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: lotusQualityMuted,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: FilledButton.tonal(
                  onPressed: () {
                    unawaited(LotusProductFeedback.selection());
                    onAction!();
                  },
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cross-fades meaningful state changes and disables motion when requested by
/// the operating system.
class LotusAnimatedSwap extends StatelessWidget {
  const LotusAnimatedSwap({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : duration,
      reverseDuration: reduceMotion ? Duration.zero : duration,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}

/// Lightweight loading placeholders. The pulse is disabled for reduced motion.
class LotusSkeletonList extends StatefulWidget {
  const LotusSkeletonList({
    super.key,
    this.itemCount = 4,
    this.compact = false,
  });

  final int itemCount;
  final bool compact;

  @override
  State<LotusSkeletonList> createState() => _LotusSkeletonListState();
}

class _LotusSkeletonListState extends State<LotusSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.42,
      upperBound: 0.78,
      value: 0.55,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.55;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'A carregar conteúdo',
      child: ExcludeSemantics(
        child: ListView.separated(
          key: const Key('lotus-skeleton-list'),
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(widget.compact ? 12 : 16),
          itemCount: widget.itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Opacity(
              opacity: _controller.value,
              child: Container(
                height: widget.compact ? 58 : 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF25303C),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deliberately sparse haptics for completed actions and important failures.
abstract final class LotusProductFeedback {
  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> success() => HapticFeedback.lightImpact();
  static Future<void> error() => HapticFeedback.mediumImpact();
}
