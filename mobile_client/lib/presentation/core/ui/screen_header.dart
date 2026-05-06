import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

class ScreenHeader extends StatelessWidget {
  final Widget title;
  final List<Widget>? actions;

  const ScreenHeader({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;

        final titleBanner = Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: appColors.border,
            border: Border.all(color: appColors.divider, width: 1),
            borderRadius: BorderRadius.circular(scale.radiusPill),
          ),
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle(
            style: TextStyle(
              color: appColors.textMuted,
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            child: title,
          ),
        );

        final actionRow = actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!
                    .asMap()
                    .entries
                    .map((entry) => Padding(
                          padding: EdgeInsets.only(
                            left: entry.key == 0 ? 0 : 10,
                          ),
                          child: entry.value,
                        ))
                    .toList(),
              )
            : null;

        if (actionRow == null) return titleBanner;

        return isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBanner,
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actionRow,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleBanner),
                  const SizedBox(width: 12),
                  actionRow,
                ],
              );
      },
    );
  }
}
