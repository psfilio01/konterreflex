import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';

enum IntelligenceOrbState { idle, speaking, listening, thinking, success }

extension IntelligenceOrbStatePresentation on IntelligenceOrbState {
  String get label => switch (this) {
        IntelligenceOrbState.idle => 'Bereit',
        IntelligenceOrbState.speaking => 'Konterreflex spricht',
        IntelligenceOrbState.listening => 'Konterreflex hört zu',
        IntelligenceOrbState.thinking => 'Konterreflex denkt nach',
        IntelligenceOrbState.success => 'Abgeschlossen',
      };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        IntelligenceOrbState.idle => l10n.orbReady,
        IntelligenceOrbState.speaking => l10n.orbSpeaking,
        IntelligenceOrbState.listening => l10n.orbListening,
        IntelligenceOrbState.thinking => l10n.orbThinking,
        IntelligenceOrbState.success => l10n.orbComplete,
      };

  IconData get icon => switch (this) {
        IntelligenceOrbState.idle => Icons.circle_outlined,
        IntelligenceOrbState.speaking => Icons.graphic_eq_rounded,
        IntelligenceOrbState.listening => Icons.mic_none_rounded,
        IntelligenceOrbState.thinking => Icons.more_horiz_rounded,
        IntelligenceOrbState.success => Icons.check_rounded,
      };
}

class IntelligenceOrb extends StatefulWidget {
  const IntelligenceOrb({
    super.key,
    this.size = 132,
    this.state = IntelligenceOrbState.idle,
    this.showStatusLabel = true,
  });

  final double size;
  final IntelligenceOrbState state;
  final bool showStatusLabel;

  @override
  State<IntelligenceOrb> createState() => _IntelligenceOrbState();
}

class _IntelligenceOrbState extends State<IntelligenceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant IntelligenceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncMotion();
  }

  void _syncMotion() {
    _controller.stop();
    _controller.value = 0;
    if (_reducedMotion || widget.state == IntelligenceOrbState.idle) return;
    if (widget.state == IntelligenceOrbState.success) {
      _controller.duration = const Duration(milliseconds: 650);
      _controller.forward();
    } else {
      _controller.duration = const Duration(milliseconds: 1800);
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _colors(ColorScheme scheme) => switch (widget.state) {
        IntelligenceOrbState.idle => [AppColors.mist, AppColors.lavender],
        IntelligenceOrbState.speaking => [
            scheme.primaryContainer,
            AppColors.sand
          ],
        IntelligenceOrbState.listening => [
            AppColors.mist,
            scheme.tertiaryContainer
          ],
        IntelligenceOrbState.thinking => [AppColors.lavender, AppColors.mist],
        IntelligenceOrbState.success => [
            const Color(0xFFCFE7D8),
            const Color(0xFFE6F1E9),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stateLabel = widget.state.localizedLabel(context.l10n);
    return Semantics(
      container: true,
      liveRegion: true,
      image: true,
      label: stateLabel,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final wave = math.sin(_controller.value * math.pi * 2);
                final scale = switch (widget.state) {
                  IntelligenceOrbState.speaking => 1 + wave * 0.035,
                  IntelligenceOrbState.listening => 1 + wave * 0.02,
                  IntelligenceOrbState.thinking => 1.0,
                  IntelligenceOrbState.success =>
                    1 + math.sin(_controller.value * math.pi) * 0.06,
                  IntelligenceOrbState.idle => 1.0,
                };
                final angle = widget.state == IntelligenceOrbState.thinking
                    ? wave * 0.035
                    : 0.0;
                return Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    key: const Key('intelligence-orb-motion'),
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _colors(scheme),
                  ),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.12),
                    width:
                        widget.state == IntelligenceOrbState.listening ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.10),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.state.icon,
                  size: widget.size * 0.28,
                  color: widget.state == IntelligenceOrbState.success
                      ? AppColors.success
                      : AppColors.foreground.withValues(alpha: 0.78),
                ),
              ),
            ),
            if (widget.showStatusLabel) ...[
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  stateLabel,
                  key: ValueKey(widget.state),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
