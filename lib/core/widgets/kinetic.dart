import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared "Kinetic Green" design-system atoms recreated from the design
/// handoff (`rf.css` / `screens.js`). These compose into the redesigned
/// screens. Colours come from the active [ColorScheme]; typography uses
/// Space Grotesk (display) and JetBrains Mono (technical numerals/labels).
class KineticText {
  KineticText._();

  /// JetBrains Mono — tabular numerals and technical labels.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w700,
    double? letterSpacing,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        height: height,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Space Grotesk — display & headings with tight tracking.
  static TextStyle display({
    double size = 24,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = -0.3,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        height: height,
      );
}

/// Accent eyebrow label: mono, uppercase, wide tracking, with a trailing rule.
/// Mirrors rf.css `.eyebrow`.
class KineticEyebrow extends StatelessWidget {
  const KineticEyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text.toUpperCase(),
          style: KineticText.mono(
            size: 11,
            letterSpacing: 2.6,
            color: accent,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 30, height: 1, color: accent.withValues(alpha: 0.5)),
      ],
    );
  }
}

/// Section label: mono, uppercase, dim, with a trailing hairline that fills
/// the remaining width. Mirrors rf.css `.sl`.
class KineticSectionLabel extends StatelessWidget {
  const KineticSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: KineticText.mono(
            size: 11,
            letterSpacing: 1.9,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: cs.outlineVariant)),
      ],
    );
  }
}

enum KineticPillVariant { accent, volt, ghost }

/// Small status pill/badge. Mirrors rf.css `.pill` (+ `--accent`/`--volt`/`--ghost`).
class KineticPill extends StatelessWidget {
  const KineticPill(
    this.label, {
    super.key,
    this.icon,
    this.variant = KineticPillVariant.accent,
  });

  final String label;
  final IconData? icon;
  final KineticPillVariant variant;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (variant) {
      KineticPillVariant.accent => (
          cs.primary.withValues(alpha: 0.14),
          cs.primary,
        ),
      KineticPillVariant.volt => (
          cs.tertiary.withValues(alpha: 0.18),
          cs.tertiary,
        ),
      KineticPillVariant.ghost => (cs.surfaceContainer, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: KineticText.mono(size: 10.5, letterSpacing: 0.8, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Primary call-to-action button. Mirrors rf.css `.cta`.
class KineticCta extends StatelessWidget {
  const KineticCta({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 58,
    this.borderRadius = 18,
    this.iconAfter = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;
  final bool iconAfter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconWidget =
        icon != null ? Icon(icon, size: 20, color: cs.onPrimary) : null;
    final text = Text(
      label.toUpperCase(),
      style:
          KineticText.mono(size: 14, letterSpacing: 1.1, color: cs.onPrimary),
    );
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconWidget != null && !iconAfter) ...[
                iconWidget,
                const SizedBox(width: 10),
              ],
              text,
              if (iconWidget != null && iconAfter) ...[
                const SizedBox(width: 10),
                iconWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat tile — a small label over a large mono value. Mirrors rf.css `.stat`.
class KineticStatTile extends StatelessWidget {
  const KineticStatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueSize = 30,
  });

  final String label;
  final String value;
  final String? unit;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: KineticText.mono(
              size: 10.5,
              weight: FontWeight.w600,
              letterSpacing: 1.7,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: KineticText.mono(
                  size: valueSize,
                  weight: FontWeight.w700,
                  letterSpacing: -0.9,
                  color: cs.onSurface,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 5),
                Text(
                  unit!,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// App header: accent logo tile + RepFoundry wordmark + notification button.
/// Mirrors rf.css `.apphead`.
class KineticAppHeader extends StatelessWidget {
  const KineticAppHeader(
      {super.key, this.onNotifications, this.hasNotificationDot = true});

  final VoidCallback? onNotifications;
  final bool hasNotificationDot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.bolt, size: 20, color: cs.onPrimary),
              ),
              const SizedBox(width: 10),
              Text.rich(
                TextSpan(
                  style: KineticText.display(
                    size: 17,
                    letterSpacing: -0.2,
                    color: cs.onSurface,
                  ),
                  children: [
                    const TextSpan(text: 'Rep'),
                    TextSpan(
                        text: 'Foundry', style: TextStyle(color: cs.primary)),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onNotifications,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 22,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (hasNotificationDot)
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: cs.surfaceContainerLow, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
