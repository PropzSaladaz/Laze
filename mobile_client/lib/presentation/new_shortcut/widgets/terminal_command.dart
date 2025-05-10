import 'package:flutter/material.dart';

class TerminalCommandInput extends StatelessWidget {
  final String operativeSystemName;
  final Function(String) onCommandUpdated;

  final String? hintText;
  final String? prefixText;

  const TerminalCommandInput(
      {super.key,
      required this.operativeSystemName,
      required this.onCommandUpdated,
      this.hintText,
      this.prefixText});

  @override
  Widget build(BuildContext context) {
    final inputTheme = Theme.of(context).inputDecorationTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              operativeSystemName,
              style: const TextStyle(
                fontSize: 20,
                // color: ColorConstants.darkText,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: const BorderRadius.all(Radius.circular(25.0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: onCommandUpdated,
              maxLines: 2,
              maxLength: 256,
              decoration: InputDecoration(
                prefixText: prefixText ?? "\$ ",
                hintText: hintText ?? "firefox 'https://google.com'",
                border: InputBorder.none,
              ),
            ),
          )
        ],
      ),
    );
  }
}
