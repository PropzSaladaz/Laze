import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/press_animation_mixin.dart';

class PairingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const PairingCard({super.key, required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(scale.spaceLg),
      decoration: BoxDecoration(
        color: colors.surface_1,
        borderRadius: BorderRadius.circular(Dimens.radius.small),
        border: Border.all(color: colors.divider),
      ),
      child: child,
    );
  }
}

class PairingAction extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary, busy;
  const PairingAction({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.primary = false,
    this.busy = false,
  });
  @override
  State<PairingAction> createState() => _PairingActionState();
}

class _PairingActionState extends State<PairingAction>
    with PressAnimationMixin<PairingAction> {
  bool _trackingPress = false;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final enabled = widget.onPressed != null && !widget.busy;
    final foreground = enabled
        ? (widget.primary ? colors.onPrimary : colors.text)
        : colors.disabledFg;
    return Listener(
      onPointerDown: enabled
          ? (_) {
              _trackingPress = true;
              handlePointerDown();
            }
          : null,
      onPointerUp: (_) {
        if (!_trackingPress) return;
        _trackingPress = false;
        handlePointerUp();
      },
      onPointerCancel: (_) {
        if (!_trackingPress) return;
        _trackingPress = false;
        handlePointerCancel();
      },
      child: AnimatedContainer(
        duration: isPressed ? pressDownDuration : pressUpDuration,
        decoration: BoxDecoration(
          color: enabled
              ? (widget.primary ? colors.primary : colors.bg)
              : colors.disabledBg,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(Dimens.radius.pill),
          boxShadow:
              enabled && !isPressed ? AppShadows.raisedControl(colors) : null,
        ),
        child: TextButton(
          onPressed: enabled ? widget.onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: foreground,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy) ...[
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: foreground)),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                  child: Text(widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: Dimens.text.small,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6))),
            ],
          ),
        ),
      ),
    );
  }
}

class PairingNotice extends StatelessWidget {
  final String message;
  const PairingNotice({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: .08),
          border: Border.all(color: colors.error.withValues(alpha: .3)),
          borderRadius: BorderRadius.circular(Dimens.radius.small),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 20, color: colors.error),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: Dimens.text.small,
                      color: colors.text,
                      height: 1.5))),
        ]),
      ),
    );
  }
}
