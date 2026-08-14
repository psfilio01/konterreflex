import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';

enum IntelligenceOrbState {
  idle,
  preparing,
  speaking,
  listening,
  thinking,
  processingSpeech,
  processingSpeechComplete,
  success,
}

extension IntelligenceOrbStatePresentation on IntelligenceOrbState {
  String get label => switch (this) {
        IntelligenceOrbState.idle => 'Bereit',
        IntelligenceOrbState.preparing => 'Audio wird vorbereitet',
        IntelligenceOrbState.speaking => 'Konterreflex spricht',
        IntelligenceOrbState.listening => 'Konterreflex hört zu',
        IntelligenceOrbState.thinking => 'Konterreflex denkt nach',
        IntelligenceOrbState.processingSpeech => 'Antwort wird verarbeitet',
        IntelligenceOrbState.processingSpeechComplete =>
          'Antwort ist verarbeitet',
        IntelligenceOrbState.success => 'Abgeschlossen',
      };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        IntelligenceOrbState.idle => l10n.orbReady,
        IntelligenceOrbState.preparing => l10n.orbPreparing,
        IntelligenceOrbState.speaking => l10n.orbSpeaking,
        IntelligenceOrbState.listening => l10n.orbListening,
        IntelligenceOrbState.thinking => l10n.orbThinking,
        IntelligenceOrbState.processingSpeech => l10n.orbProcessingSpeech,
        IntelligenceOrbState.processingSpeechComplete =>
          l10n.orbProcessingSpeechComplete,
        IntelligenceOrbState.success => l10n.orbComplete,
      };

  IconData get icon => switch (this) {
        IntelligenceOrbState.idle => Icons.circle_outlined,
        IntelligenceOrbState.preparing => Icons.hourglass_top_rounded,
        IntelligenceOrbState.speaking => Icons.graphic_eq_rounded,
        IntelligenceOrbState.listening => Icons.mic_none_rounded,
        IntelligenceOrbState.thinking => Icons.more_horiz_rounded,
        IntelligenceOrbState.processingSpeech ||
        IntelligenceOrbState.processingSpeechComplete =>
          Icons.blur_circular_rounded,
        IntelligenceOrbState.success => Icons.check_rounded,
      };
}

class IntelligenceOrb extends StatefulWidget {
  const IntelligenceOrb({
    super.key,
    this.size = 132,
    this.state = IntelligenceOrbState.idle,
    this.showStatusLabel = true,
    this.activityLevel = 0,
  });

  final double size;
  final IntelligenceOrbState state;
  final bool showStatusLabel;
  final double activityLevel;

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
    if (_reducedMotion ||
        widget.state == IntelligenceOrbState.idle ||
        widget.state == IntelligenceOrbState.processingSpeechComplete) {
      return;
    }
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
        IntelligenceOrbState.preparing => [
            AppColors.lavender,
            scheme.surfaceContainerHighest,
          ],
        IntelligenceOrbState.speaking => [
            scheme.primaryContainer,
            AppColors.sand
          ],
        IntelligenceOrbState.listening => [
            AppColors.mist,
            scheme.tertiaryContainer
          ],
        IntelligenceOrbState.thinking => [AppColors.lavender, AppColors.mist],
        IntelligenceOrbState.processingSpeech => [
            AppColors.mist,
            AppColors.lavender,
          ],
        IntelligenceOrbState.processingSpeechComplete => [
            const Color(0xFFD8EBDD),
            const Color(0xFFEDF5EC),
          ],
        IntelligenceOrbState.success => [
            const Color(0xFFCFE7D8),
            const Color(0xFFE6F1E9),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stateLabel = widget.state.localizedLabel(context.l10n);
    final showsVoiceActivity = widget.state == IntelligenceOrbState.speaking ||
        widget.state == IntelligenceOrbState.listening;
    final showsProcessingSpiral =
        widget.state == IntelligenceOrbState.processingSpeech ||
            widget.state == IntelligenceOrbState.processingSpeechComplete;
    final activityLevel = _reducedMotion && showsVoiceActivity
        ? 0.32
        : widget.activityLevel.clamp(0.0, 1.0);
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
                  IntelligenceOrbState.preparing => 1 + wave * 0.01,
                  IntelligenceOrbState.thinking => 1.0,
                  IntelligenceOrbState.processingSpeech => 1.0,
                  IntelligenceOrbState.processingSpeechComplete => 1.0,
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
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: activityLevel),
                duration: _reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                builder: (context, activity, orb) => Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (showsVoiceActivity)
                      Transform.scale(
                        key: const Key('voice-activity-halo'),
                        scale: 1.08 + activity * 0.22,
                        child: Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (widget.state == IntelligenceOrbState.listening
                                        ? scheme.tertiary
                                        : scheme.primary)
                                    .withValues(
                                  alpha: 0.12 + activity * 0.16,
                                ),
                                scheme.surface.withValues(alpha: 0),
                              ],
                              stops: const [0.38, 1],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.state ==
                                            IntelligenceOrbState.listening
                                        ? scheme.tertiary
                                        : scheme.primary)
                                    .withValues(
                                  alpha: 0.08 + activity * 0.14,
                                ),
                                blurRadius: 34 + activity * 24,
                                spreadRadius: 5 + activity * 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    orb!,
                  ],
                ),
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
                      width: widget.state == IntelligenceOrbState.listening
                          ? 3
                          : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.10),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: showsProcessingSpiral
                      ? TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: widget.state ==
                                    IntelligenceOrbState
                                        .processingSpeechComplete
                                ? 1
                                : 0.85,
                          ),
                          duration: _reducedMotion
                              ? Duration.zero
                              : widget.state ==
                                      IntelligenceOrbState
                                          .processingSpeechComplete
                                  ? const Duration(milliseconds: 300)
                                  : const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, child) =>
                              AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final pulseWave = math.sin(
                                _controller.value * math.pi * 2,
                              );
                              return CustomPaint(
                                key: const Key('speech-processing-spiral'),
                                painter: SpeechProcessingSpiralPainter(
                                  progress: progress,
                                  pulse: _reducedMotion ||
                                          widget.state ==
                                              IntelligenceOrbState
                                                  .processingSpeechComplete
                                      ? 0
                                      : (pulseWave + 1) / 2,
                                  sage: AppColors.sage,
                                  success: AppColors.success,
                                ),
                              );
                            },
                          ),
                        )
                      : Icon(
                          widget.state.icon,
                          size: widget.size * 0.28,
                          color: widget.state == IntelligenceOrbState.success
                              ? AppColors.success
                              : AppColors.foreground.withValues(alpha: 0.78),
                        ),
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

@visibleForTesting
class SpeechProcessingSpiralPainter extends CustomPainter {
  const SpeechProcessingSpiralPainter({
    required this.progress,
    required this.pulse,
    required this.sage,
    required this.success,
  });

  final double progress;
  final double pulse;
  final Color sage;
  final Color success;

  static const _turns = 2.5;
  static const _samples = 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maximumRadius = size.shortestSide * 0.31;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final sampleCount = math.max(2, (_samples * clampedProgress).ceil());
    final path = Path();
    Offset tip = center + Offset(0, -maximumRadius);
    for (var index = 0; index < sampleCount; index += 1) {
      final fraction = clampedProgress * index / (sampleCount - 1);
      final angle = -math.pi / 2 + fraction * math.pi * 2 * _turns;
      final radius = maximumRadius * (1 - fraction);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      tip = point;
    }

    final bounds = Rect.fromCircle(center: center, radius: maximumRadius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.026
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [sage, success],
      ).createShader(bounds);
    canvas.drawPath(path, stroke);

    final glow = Paint()
      ..color = success.withValues(alpha: 0.14 + pulse * 0.12)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        size.shortestSide * (0.028 + pulse * 0.018),
      );
    canvas.drawCircle(
      tip,
      size.shortestSide * (0.026 + pulse * 0.008),
      glow,
    );
    canvas.drawCircle(
      tip,
      size.shortestSide * (clampedProgress >= 1 ? 0.025 : 0.018),
      Paint()..color = success,
    );
  }

  @override
  bool shouldRepaint(covariant SpeechProcessingSpiralPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      pulse != oldDelegate.pulse ||
      sage != oldDelegate.sage ||
      success != oldDelegate.success;
}
