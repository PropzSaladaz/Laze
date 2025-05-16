import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mobile_client/core/os_config.dart';
import 'package:mobile_client/presentation/core/ui/wide_styled_button.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';
import 'package:mobile_client/presentation/core/ui/controller_page.dart';
import 'package:mobile_client/presentation/new_shortcut/view_models/add_custom_shortcut_viewmodel.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/shortcut_input_row.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/terminal_command.dart';
import 'package:provider/provider.dart';

class AddCustomShortcut extends StatelessWidget {
  const AddCustomShortcut({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcutVM = context.watch<AddCustomShortcutViewModel>();
    final customColors = Theme.of(context).extension<CustomColors>();
    final textTheme = Theme.of(context).textTheme;

    return ControllerPage(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Main Page
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Column(children: [
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
                  ]),
                ],
              ),
            ),

            // CANCEL / CREATE buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  // CANCEL BUTTON
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: WideStyledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        text: "CANCEL",
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        backgroundColor: customColors!.negativeSecondary,
                      ),
                    ),
                  ),
                  // CREATE BUTTON
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: WideStyledButton(
                        backgroundColor: customColors.negativePrimary,
                        onPressed: () {
                          shortcutVM.saveShortcut.execute();
                          Navigator.of(context).pop();
                        },
                        text: shortcutVM.isNew 
                          ? "CREATE"
                          : "SAVE",
                        // textColor: ColorConstants.darkText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
