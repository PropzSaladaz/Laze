import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: appColors.border,
              border: Border.all(color: appColors.divider, width: 1),
              borderRadius: BorderRadius.circular(scale.radiusPill),
            ),
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle(
              style: TextStyle(
                color: appColors.textMuted,
                fontSize: Dimens.text.header,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
              child: title,
            ),
          ),
        ),
        if (actionRow != null) ...[
          const SizedBox(width: 12),
          actionRow,
        ],
      ],
    );
  }
}
