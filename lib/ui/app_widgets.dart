import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

// ──────────────────────────────────────────────────────────
// APP BACKGROUND GRADIENT — matches web body gradient
// ──────────────────────────────────────────────────────────

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Stack(
      children: [
        // Base linear gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF04100C), const Color(0xFF060E18)]
                : [const Color(0xFFECFDF5), const Color(0xFFEFF6FF)], // Premium fresh mint-to-blue gradient
            ),
          ),
        ),
        // Radial 1
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isDark ? const Color(0x140EA5E9) : const Color(0x22F59E0B), // Vibrant amber glow in light mode
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Radial 2
        Positioned(
          bottom: -120,
          right: -120,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isDark ? const Color(0x1410B981) : const Color(0x2610B981), // Vibrant emerald glow in light mode
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// GLASSMORPHISM CARD — mirrors web .card style
// ──────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.margin,
    this.accentColor,   // top accent bar color (like .stat-card::before)
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? const BorderRadius.all(Radius.circular(20));
    final isDark = context.isDark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? const Color(0x59000000) 
              : const Color(0x0D020617), // very soft premium shadow in light mode
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                  ? [const Color(0x33FFFFFF), const Color(0x1AFFFFFF)] // Sáng hơn một chút
                  : [const Color(0xF2FFFFFF), const Color(0xD9FFFFFF)], // Solid frosted white in light mode
              ),
              border: Border.all(
                color: isDark 
                  ? const Color(0x26FFFFFF) 
                  : const Color(0x40FFFFFF), // bright crisp white border in light mode for glass reflection
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (accentColor != null)
                  Container(height: 3, color: accentColor),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// STATUS BADGE — mirrors web .badge + variants
// ──────────────────────────────────────────────────────────

enum BadgeVariant {
  pending,
  active,
  completed,
  approved,
  confirmed,
  rejected,
  inactive,
  cancelled,
  scheduled,
  ongoing,
  neutral,
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.variant});

  final String label;
  final BadgeVariant? variant;

  static BadgeVariant fromStatus(String status) {
    return switch (status.toLowerCase()) {
      'pending'   => BadgeVariant.pending,
      'open'      => BadgeVariant.scheduled,
      'active'    => BadgeVariant.active,
      'completed' => BadgeVariant.completed,
      'approved'  => BadgeVariant.approved,
      'confirmed' => BadgeVariant.confirmed,
      'rejected'  => BadgeVariant.rejected,
      'inactive'  => BadgeVariant.inactive,
      'cancelled' => BadgeVariant.cancelled,
      'scheduled' => BadgeVariant.scheduled,
      'ongoing'   => BadgeVariant.ongoing,
      'won'       => BadgeVariant.active,
      'lost'      => BadgeVariant.rejected,
      _           => BadgeVariant.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, borderColor) = _colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: context.radii.full,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: context.typography.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.7,
          height: 1.3,
        ),
      ),
    );
  }

  (Color, Color, Color) _colors(BuildContext context) {
    final v = variant ?? BadgeVariant.neutral;
    final isDark = context.isDark;
    return switch (v) {
      BadgeVariant.pending   => (context.colors.warningLight,  isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309), const Color(0x4DF59E0B)),
      BadgeVariant.active    => (context.colors.successLight,  isDark ? const Color(0xFF34D399) : const Color(0xFF047857), const Color(0x4D10B981)),
      BadgeVariant.completed => (context.colors.successLight,  isDark ? const Color(0xFF34D399) : const Color(0xFF047857), const Color(0x4D10B981)),
      BadgeVariant.approved  => (context.colors.successLight,  isDark ? const Color(0xFF34D399) : const Color(0xFF047857), const Color(0x4D10B981)),
      BadgeVariant.confirmed => (context.colors.successLight,  isDark ? const Color(0xFF34D399) : const Color(0xFF047857), const Color(0x4D10B981)),
      BadgeVariant.rejected  => (context.colors.dangerLight,   isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C), const Color(0x4DEF4444)),
      BadgeVariant.inactive  => (context.colors.dangerLight,   isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C), const Color(0x4DEF4444)),
      BadgeVariant.cancelled => (context.colors.dangerLight,   isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C), const Color(0x4DEF4444)),
      BadgeVariant.scheduled => (context.colors.infoLight,     isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8), const Color(0x4D3B82F6)),
      BadgeVariant.ongoing   => (context.colors.purpleLight,   isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9), const Color(0x4D8B5CF6)),
      BadgeVariant.neutral   => (context.colors.surface3,      isDark ? context.colors.muted : context.colors.text2,         context.colors.border),
    };
  }
}

// ──────────────────────────────────────────────────────────
// ROLE BADGE — mirrors web .role-* badges
// ──────────────────────────────────────────────────────────

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, borderColor, label) = _config(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: context.radii.full,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: context.typography.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  (Color, Color, Color, String) _config(BuildContext context) {
    final isDark = context.isDark;
    return switch (role.toLowerCase()) {
      'admin'     => (context.colors.purpleLight,  isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9), const Color(0x4D8B5CF6), 'Admin'),
      'owner'     => (context.colors.successLight, isDark ? const Color(0xFF34D399) : const Color(0xFF047857), const Color(0x4D10B981), 'Owner'),
      'jockey'    => (context.colors.orangeLight,  isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C), const Color(0x4DF97316), 'Jockey'),
      'referee'   => (context.colors.infoLight,    isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8), const Color(0x4D3B82F6), 'Referee'),
      'spectator' => (context.colors.surface3,     isDark ? context.colors.muted : context.colors.text2,         context.colors.border,         'Spectator'),
      _           => (context.colors.surface3,     isDark ? context.colors.muted : context.colors.text2,         context.colors.border,         role),
    };
  }
}

// ──────────────────────────────────────────────────────────
// USER AVATAR — mirrors web .avatar + role colors
// ──────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.role,
    this.size = 36,
  });

  final String name;
  final String role;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final gradient = _gradient(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: context.typography.fontFamily,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  List<Color> _gradient(BuildContext context) {
    return switch (role.toLowerCase()) {
      'admin'     => AppRoleColors.avatarAdmin,
      'owner'     => AppRoleColors.avatarOwner,
      'jockey'    => AppRoleColors.avatarJockey,
      'referee'   => AppRoleColors.avatarReferee,
      'spectator' => AppRoleColors.avatarSpectator,
      _           => AppRoleColors.avatarDefault,
    };
  }
}

// ──────────────────────────────────────────────────────────
// STAT CARD — mirrors web .stat-card
// ──────────────────────────────────────────────────────────

class AnimatedRainbowCard extends StatefulWidget {
  const AnimatedRainbowCard({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedRainbowCard> createState() => _AnimatedRainbowCardState();
}

class _AnimatedRainbowCardState extends State<AnimatedRainbowCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colors = isDark 
      ? [const Color(0x26FFFFFF), const Color(0xFFEC4899), const Color(0xFF8B5CF6), const Color(0xFF3B82F6), const Color(0xFF06B6D4), const Color(0x26FFFFFF)]
      : [const Color(0xFFDB2777), const Color(0xFFEA580C), const Color(0xFFD97706), const Color(0xFF16A34A), const Color(0xFF0284C7), const Color(0xFF7C3AED), const Color(0xFFDB2777)];
    
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: SweepGradient(
              colors: colors,
              transform: GradientRotation(_ctrl.value * 2 * 3.141592653589793),
            ),
          ),
          padding: const EdgeInsets.all(1.5), // border width
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.5),
              color: isDark ? const Color(0xFF0D1626) : Colors.white,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedRainbowCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: context.typography.statValue.copyWith(color: context.colors.text),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: context.typography.captionUpper.copyWith(
                color: context.colors.muted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// SECTION HEADER
// ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.typography.h2),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: context.typography.bodyMuted),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// LOADING SHIMMER — elegant loading state
// ──────────────────────────────────────────────────────────

class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key, this.height = 80});

  final double height;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: context.radii.md,
          gradient: LinearGradient(
            begin: Alignment(-1 + _anim.value * 2, 0),
            end: Alignment(1 + _anim.value * 2, 0),
            colors: const [
              Color(0x14FFFFFF),
              Color(0x28FFFFFF),
              Color(0x14FFFFFF),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// EMPTY STATE
// ──────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.border),
              ),
              child: Icon(icon, color: context.colors.muted, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: context.typography.h3, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: context.typography.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// PRIMARY BUTTON  (with loading + full-width options)
// ──────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final vPad = small ? 10.0 : 13.0;
    final hPad = small ? 14.0 : 18.0;
    final fontSize = small ? 13.0 : 14.0;

    Widget btn;

    if (variant == AppButtonVariant.primary) {
      btn = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:  context.colors.primaryDark,
          foregroundColor:  Colors.white,
          disabledBackgroundColor: context.colors.primaryDark.withValues(alpha: 0.6),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          textStyle: TextStyle(
            fontFamily: context.typography.fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: context.radii.base),
        ),
        child: _buildChild(),
      );
    } else if (variant == AppButtonVariant.danger) {
      btn = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.danger,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          textStyle: TextStyle(
            fontFamily: context.typography.fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: context.radii.base),
        ),
        child: _buildChild(),
      );
    } else {
      // ghost / outlined
      btn = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colors.text2,
          side: BorderSide(color: context.colors.border),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          textStyle: TextStyle(
            fontFamily: context.typography.fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: context.radii.base),
        ),
        child: _buildChild(),
      );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}

enum AppButtonVariant { primary, ghost, danger }

// ──────────────────────────────────────────────────────────
// SCREEN SCAFFOLD — replaces the old ScreenScaffold
// ──────────────────────────────────────────────────────────

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: AppBar(
          backgroundColor: isDark 
            ? const Color(0x9904100C) 
            : const Color(0xB3FFFFFF),
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.transparent),
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [context.colors.primary, context.colors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          actions: actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1, 
              color: isDark 
                ? context.colors.border 
                : const Color(0x1F000000), // thin subtle border under glass appBar in light mode
            ),
          ),
        ),
        body: SafeArea(child: body),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// SELECTABLE ITEM ROW — replaces selectableTextRow
// ──────────────────────────────────────────────────────────

class SelectableItemRow extends StatelessWidget {
  const SelectableItemRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? context.colors.primaryLight : const Color(0x0AFFFFFF),
          borderRadius: context.radii.base,
          border: Border.all(
            color: selected ? context.colors.primaryRing : context.colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? context.colors.primary : context.colors.border,
                  width: selected ? 5 : 2,
                ),
                color: selected ? context.colors.primary : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.typography.body.copyWith(
                      color: selected ? context.colors.primary : context.colors.text2,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.typography.caption),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// ALERT DIALOG — themed
// ──────────────────────────────────────────────────────────

Future<void> showAppAlert(
  BuildContext context,
  String title,
  String message, {
  bool isError = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isError ? context.colors.dangerLight : context.colors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: isError ? context.colors.danger : context.colors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(title, style: context.typography.h3),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: context.colors.border,
            ),
            const SizedBox(height: 16),
            Text(message, style: context.typography.body),
            const SizedBox(height: 24),
            AppButton(
              label: 'OK',
              onPressed: () => Navigator.of(ctx).pop(),
              variant: isError ? AppButtonVariant.danger : AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────
// TOPBAR USER BADGE — mirrors web .user-badge
// ──────────────────────────────────────────────────────────

class UserBadge extends StatelessWidget {
  const UserBadge({super.key, required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
      decoration: BoxDecoration(
        color: context.colors.surface2,
        borderRadius: context.radii.full,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(name: name, role: role, size: 28),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontFamily: context.typography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.text,
                ),
              ),
              RoleBadge(role: role),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// NAV MENU ITEM — for nav drawer items
// ──────────────────────────────────────────────────────────

class NavMenuItem extends StatelessWidget {
  const NavMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? context.colors.primaryLight : Colors.transparent,
          borderRadius: context.radii.full,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? context.colors.primary : context.colors.muted,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: context.typography.fontFamily,
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? context.colors.primary : context.colors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// RACE RESULTS MODAL — reusable bottom sheet
// ──────────────────────────────────────────────────────────

class RaceResultsBottomSheet extends StatefulWidget {
  const RaceResultsBottomSheet({
    super.key,
    required this.raceName,
    required this.onFetchResults,
  });

  final String raceName;
  final Future<Map<String, dynamic>> Function() onFetchResults;

  @override
  State<RaceResultsBottomSheet> createState() => _RaceResultsBottomSheetState();
}

class _RaceResultsBottomSheetState extends State<RaceResultsBottomSheet> {
  Map<String, dynamic>? _results;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _loading = true;
      _error = null;
    });
    widget.onFetchResults().then((res) {
      if (mounted) {
        setState(() {
          _results = res;
          _loading = false;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() {
          _error = err.toString();
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final resultItems = _results?['results'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1626) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1F000000),
          width: 1,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Thứ tự về đích',
                  style: context.typography.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            widget.raceName,
            style: context.typography.bodyMuted,
          ),
          const SizedBox(height: 20),
          
          if (_loading)
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LoadingShimmer(height: 72),
            ))
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Lỗi khi tải kết quả: $_error',
                style: context.typography.body.copyWith(color: context.colors.danger),
                textAlign: TextAlign.center,
              ),
            )
          else if (resultItems is! List || resultItems.isEmpty)
            const EmptyState(
              icon: Icons.flag_outlined,
              title: 'Chưa có kết quả',
              subtitle: 'Kết quả sẽ hiển thị sau khi trận đấu kết thúc.',
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView(
                shrinkWrap: true,
                children: resultItems.whereType<Map>().map((item) {
                  final position  = item['position'];
                  final horseId   = item['horseId'];
                  final jockeyId  = item['jockeyId'];
                  final horseName = horseId is Map
                      ? horseId['name']?.toString() ?? 'N/A'
                      : 'N/A';
                  final jockeyName = jockeyId is Map
                      ? jockeyId['fullName']?.toString() ?? 'N/A'
                      : 'N/A';
                  final rank = position is int ? position : int.tryParse(position?.toString() ?? '') ?? 0;
                  
                  final isTop3 = rank <= 3;
                  final medal = switch (rank) { 1 => '🥇', 2 => '🥈', 3 => '🥉', _ => null };
                  final accentColor = switch (rank) {
                    1 => context.colors.accent,
                    2 => context.colors.muted,
                    3 => context.colors.orange,
                    _ => null,
                  };

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      accentColor: isTop3 ? accentColor : null,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: medal != null
                                ? Text(medal, style: const TextStyle(fontSize: 24))
                                : Text(
                                    '#$rank',
                                    style: context.typography.h3.copyWith(color: context.colors.muted),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  horseName,
                                  style: context.typography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isTop3 ? context.colors.text : context.colors.text2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 12, color: context.colors.muted),
                                    const SizedBox(width: 4),
                                    Text(jockeyName, style: context.typography.caption),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

void showRaceResultsModal(
  BuildContext context, {
  required String raceName,
  required Future<Map<String, dynamic>> Function() onFetchResults,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RaceResultsBottomSheet(
      raceName: raceName,
      onFetchResults: onFetchResults,
    ),
  );
}

// ──────────────────────────────────────────────────────────
// APP BOTTOM SHEET — generic reusable bottom sheet
// ──────────────────────────────────────────────────────────

void showAppBottomSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = context.isDark;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1626) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1F000000),
            width: 1,
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.typography.h2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: context.typography.bodyMuted,
              ),
              const SizedBox(height: 20),
            ] else ...[
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      );
    },
  );
}

// ──────────────────────────────────────────────────────────
// SWIPEABLE CARD — generic swipeable card for actions
// ──────────────────────────────────────────────────────────

class SwipeableCard extends StatelessWidget {
  const SwipeableCard({
    super.key,
    required this.child,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.id,
    this.rightIcon = Icons.check_circle_outline,
    this.leftIcon = Icons.cancel_outlined,
    this.rightLabel = 'Chấp nhận',
    this.leftLabel = 'Từ chối',
  });

  final Widget child;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final String id;
  final IconData rightIcon;
  final IconData leftIcon;
  final String rightLabel;
  final String leftLabel;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(id),
      background: _buildBackground(
        context: context,
        color: context.colors.successLight,
        iconColor: context.colors.success,
        icon: rightIcon,
        label: rightLabel,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildBackground(
        context: context,
        color: context.colors.dangerLight,
        iconColor: context.colors.danger,
        icon: leftIcon,
        label: leftLabel,
        alignment: Alignment.centerRight,
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onSwipeRight();
        } else {
          onSwipeLeft();
        }
      },
      child: child,
    );
  }

  Widget _buildBackground({
    required BuildContext context,
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: isLeft ? TextDirection.ltr : TextDirection.rtl,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Text(
            label,
            style: context.typography.h3.copyWith(color: iconColor),
          ),
        ],
      ),
    );
  }
}
