import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../history/domain/models/personal_record.dart';

class PRCelebrationOverlay extends StatefulWidget {
  const PRCelebrationOverlay({
    super.key,
    required this.exerciseName,
    required this.value,
    required this.recordType,
    required this.onDismiss,
  });

  final String exerciseName;
  final double value;
  final RecordType recordType;
  final VoidCallback onDismiss;

  @override
  State<PRCelebrationOverlay> createState() => _PRCelebrationOverlayState();
}

class _PRCelebrationOverlayState extends State<PRCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    HapticFeedback.heavyImpact();
    _controller.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (!mounted || _dismissing) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _titleForType(S s, RecordType type) {
    switch (type) {
      case RecordType.maxWeight:
        return s.prTypeWeight;
      case RecordType.maxReps:
        return s.prTypeReps;
      case RecordType.maxVolume:
        return s.prTypeVolume;
      case RecordType.estimatedOneRepMax:
        return s.prTypeE1rm;
    }
  }

  String _formattedValue(S s, RecordType type, double value) {
    final formatted = value.toStringAsFixed(1);
    switch (type) {
      case RecordType.maxWeight:
        return s.prValueWeight(formatted);
      case RecordType.maxReps:
        return s.prValueReps(value.round().toString());
      case RecordType.maxVolume:
        return s.prValueVolume(formatted);
      case RecordType.estimatedOneRepMax:
        return s.prValueE1rm(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 56,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _titleForType(s, widget.recordType),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.exerciseName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedValue(s, widget.recordType, widget.value),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
