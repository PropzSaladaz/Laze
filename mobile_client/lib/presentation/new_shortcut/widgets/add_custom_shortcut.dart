import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mobile_client/core/os_config.dart';
import 'package:mobile_client/data/services/input.dart';
import 'package:mobile_client/presentation/core/ui/wide_styled_button.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';
import 'package:mobile_client/presentation/core/ui/controller_page.dart';
import 'package:mobile_client/presentation/new_shortcut/view_models/add_custom_shortcut_viewmodel.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/shortcut_input_row.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/terminal_command.dart';
import 'package:mobile_client/services/server_connector.dart';
import 'package:provider/provider.dart';

class AddCustomShortcut extends StatelessWidget {
  const AddCustomShortcut({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcutVM = context.watch<AddCustomShortcutViewModel>();
    final customColors = Theme.of(context).extension<CustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return ControllerPage(
      body: LayoutBuilder(
        builder: (context, constraints) { 
          return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 20.0),
              
                            ShortcutInputRow(
                                initShortcutName: shortcutVM.name,
                                initIcon: shortcutVM.icon,
                                onNameChanged: shortcutVM.setName,
                                onIconSelected: shortcutVM.setIcon),
              
                            const SizedBox(height: 40.0),
              
                            Text(
                              "Type the commands to run in the host machine's terminal",
                              style: textTheme.titleSmall,
                            ),
              
                            const SizedBox(height: 20.0),
              
                            // add input box for all supported OSes
                            for (var os in SUPPORTED_OSES)
                              TerminalCommandInput(
                                  operativeSystemName: os.name,
                                  initCommand: shortcutVM.commands.containsKey(os.name)
                                      ? shortcutVM.commands[os.name]
                                      : "",
                                  onCommandUpdated: (newCommand) {
                                    shortcutVM.setCommand(os.name, newCommand);
                                  })
                          ],
                        ),
              
                        const SizedBox(height: 20.0),
              
                        // TEST COMMAND
                        WideStyledButton(
                          backgroundColor:  customColors.negativeOnSecondary,
                          onPressed: () => {
                            ServerConnector.sendInput(Input.runCommand(shortcutVM.commands))
                          },
                          text:  "Test Command",
                          // textColor: ColorConstants.darkText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ],
                    ),
                  ),
              
                  Row(
                    children: [
                      _expandedFractionalButton(
                          text: "CANCEL",
                          backgroundColor:  customColors.negativeSecondary,
                          onPressed: () => Navigator.of(context).pop(),
                      ),
              
                      _expandedFractionalButton(
                          text: shortcutVM.isNew 
                            ? "CREATE"
                            : "SAVE",
                          backgroundColor:  customColors.negativePrimary,
                          onPressed: () {
                            shortcutVM.saveShortcut.execute();
                            Navigator.of(context).pop();
                          },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        );
        }
      ),
    );
  }

  Widget _expandedFractionalButton({
    Color? backgroundColor,
    required void Function() onPressed,
    String? text 
  }) {
    return Expanded(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: WideStyledButton(
          backgroundColor: backgroundColor,
          onPressed: onPressed,
          text: text,
          // textColor: ColorConstants.darkText,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
