import 'package:flutter/material.dart';
import 'package:mobile_client/core/constants/color_constants.dart';

class ControllerPage extends StatelessWidget {
  final Widget body;
  final Widget? stackedBody;
  final bool? resizeToAvoidBottomInset;

  const ControllerPage({
    super.key,
    this.stackedBody,
    this.resizeToAvoidBottomInset,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset != null ? resizeToAvoidBottomInset! : true,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        toolbarHeight: 0,
      ),
      body: Center(
        child: Stack( // for scrollable shortcuts
          children: [
            // MAIN PAGE
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 24, vertical: 24),
              alignment: Alignment.topCenter,
              child: body,
            ),
            if (stackedBody != null) stackedBody!,
          ]
        )
      )
    );
  }
}