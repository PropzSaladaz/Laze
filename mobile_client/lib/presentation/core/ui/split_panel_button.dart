import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

class SplitPanelButton extends StatelessWidget {
  static const Radius _radius = Radius.circular(32);
  static const double _topTextSize = 24;
  static const double _bottomTextSize = 22;
  static const double _separatorHorizontalPadding = 18;

  final String topText;
  final String bottomText;
  final VoidCallback onBottomPressed;
  final double width;
  final double height;

  const SplitPanelButton({
    super.key,
    required this.topText,
    required this.bottomText,
    required this.onBottomPressed,
    this.width = 176,
    this.height = 176,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: appColors.border,
        borderRadius: const BorderRadius.all(_radius),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(_radius),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  topText,
                  style: TextStyle(
                    color: appColors.textMuted,
                    fontSize: _topTextSize,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _separatorHorizontalPadding,
              ),
              child: Container(
                height: 1,
                color: appColors.divider,
              ),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBottomPressed,
                  child: Center(
                    child: Text(
                      bottomText,
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: _bottomTextSize,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
