import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';

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
      resizeToAvoidBottomInset:
          resizeToAvoidBottomInset != null ? resizeToAvoidBottomInset! : true,
      appBar: AppBar(
        // backgroundColor: ColorConstants.background,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SizedBox(
                  width: double.infinity,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: Dimens.padding.screenHorizontal,
                          vertical: Dimens.padding.screenVertical,
                        ),
                        alignment: Alignment.topCenter,
                        child: body,
                      ),
                      if (stackedBody != null) stackedBody!,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
