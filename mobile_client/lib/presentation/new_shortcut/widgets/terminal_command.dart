import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/styled_input.dart';

class TerminalCommandInput extends StatefulWidget {
  final String operativeSystemName;
  final Function(String) onCommandUpdated;

  final String? initCommand;

  final String? hintText;
  final String? prefixText;

  const TerminalCommandInput({
    super.key,
    required this.operativeSystemName,
    required this.onCommandUpdated,
    required this.initCommand,
    this.hintText,
    this.prefixText,
  });

  @override
  State<TerminalCommandInput> createState() => _TerminalCommandInputState();
}

class _TerminalCommandInputState extends State<TerminalCommandInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initCommand ?? "");
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _capitalize(widget.operativeSystemName),
            style: TextStyle(
              color: appColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: appColors.surface_1,
              borderRadius: const BorderRadius.all(Radius.circular(25.0)),
              border: Border.all(color: appColors.divider, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: StyledInput(
              controller: _controller,
              prefixText: widget.prefixText ?? '\$ ',
              hintText: widget.hintText ?? "firefox 'https://google.com'",
              onInputUpdated: widget.onCommandUpdated,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
