import 'package:flutter/material.dart';
import 'package:mobile_client/presentation/core/ui/styled_input.dart';

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 12,
          ),
          Container(
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: const BorderRadius.all(Radius.circular(25.0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: StyledInput(
                controller: _controller,
                inputTitle: _capitalize(widget.operativeSystemName),
                prefixText: widget.prefixText ?? "\$ ",
                hintText: widget.hintText ?? "firefox 'https://google.com'",
                onInputUpdated: widget.onCommandUpdated,
              ))
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
