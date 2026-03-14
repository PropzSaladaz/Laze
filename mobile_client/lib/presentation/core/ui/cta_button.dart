import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

class CtaButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CtaButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: 0.75,
        child: Container(
          decoration: BoxDecoration(
            color: appColors.primary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: appColors.surface_1,
              width: 1,
            ),
            boxShadow: const [
              // light at top left
              BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.64), offset: Offset(-2,  -1), blurRadius: 5),
              BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.57), offset: Offset(-8,  -3), blurRadius: 9),
              BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.38), offset: Offset(-18, -8), blurRadius: 12),
              BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.18), offset: Offset(-31, -14), blurRadius: 14),
              BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.01), offset: Offset(-49, -22), blurRadius: 15),
              // shadow bottom right
              BoxShadow(color: Color.fromRGBO(95, 95, 95, 0.012), offset: Offset(36,  4), blurRadius: 10),
              BoxShadow(color: Color.fromRGBO(95, 95, 95, 0.01), offset: Offset(23,  3), blurRadius: 9),
              BoxShadow(color: Color.fromRGBO(95, 95, 95, 0.05), offset: Offset(13, 1), blurRadius: 8),
              BoxShadow(color: Color.fromRGBO(95, 95, 95, 0.09), offset: Offset(6, 1), blurRadius: 6),
              BoxShadow(color: Color.fromRGBO(95, 95, 95, 0.1), offset: Offset(1, 0), blurRadius: 3),
            ],
          ),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: const StadiumBorder(),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: appColors.surface_1,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                fontFamily: 'NunitoSans',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
