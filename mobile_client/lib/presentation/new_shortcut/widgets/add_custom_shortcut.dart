import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mobile_client/core/os_config.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/presentation/core/ui/wide_styled_button.dart';
import 'package:mobile_client/presentation/home/view_models/home_viewmodel.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';
import 'package:mobile_client/presentation/core/ui/controller_page.dart';
import 'package:mobile_client/presentation/new_shortcut/view_models/add_custom_shortcut_viewmodel.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/shortcut_input_row.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/terminal_command.dart';
import 'package:provider/provider.dart';

class AddCustomShortcut extends StatefulWidget {
  final HomeViewModel viewModel;

  final Shortcut? shortcut;

  const AddCustomShortcut({
    super.key,
    required this.viewModel,
    this.shortcut
  });

  @override
  State<AddCustomShortcut> createState() => _AddCustomShortcutState();
}

class _AddCustomShortcutState extends State<AddCustomShortcut> {
  late String shortcutId;
  late IconData icon;
  late String shortcutName;
  late Map<String, String> commands;
  late bool isNewShortcut;

  @override
  void initState() {
    super.initState();

    // init shortcut data
    if (widget.shortcut != null) {
      shortcutId = widget.shortcut!.id;
      icon = (icon == Icons.abc) ? widget.shortcut!.icon : Icons.abc;
      shortcutName = widget.shortcut!.name;
      commands = widget.shortcut!.commands;
    }
    else {
      shortcutId = "";
      icon = Icons.abc;
      shortcutName = "";
      commands = HashMap();
    }

    isNewShortcut = widget.shortcut == null;
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    final textTheme = Theme.of(context).textTheme;

    return ChangeNotifierProvider<AddCustomShortcutViewModel>(
      create: (_) => AddCustomShortcutViewModel(homeViewModel: widget.viewModel),
      child: ControllerPage(
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
                          initShortcutName: shortcutName,
                          initIcon: icon,
                          onNameChanged: _onShortcutNameChanged,
                          onIconSelected: _onIconSelected),

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
                            initCommand: commands.containsKey(os.name)
                                ? commands[os.name]
                                : "",
                            onCommandUpdated: (newCommand) {
                              commands[os.name] = newCommand;
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
                          onPressed: () => _saveShortcutData(isNewShortcut),
                          text: isNewShortcut 
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
      )
    );
  }

  void _onShortcutNameChanged(String newName) {
    setState(() => shortcutName = newName);
  }

  void _onIconSelected(IconData newIcon) {
    setState(() => icon = newIcon);
    print("New Icon set");
  }

  void _saveShortcutData(bool isNewShortcut) {
    Shortcut toBeSaved = isNewShortcut 
      ? Shortcut(commands: commands, icon: icon, name: shortcutName)
      : Shortcut.withId(id: shortcutId, name: shortcutName, icon: icon, commands: commands);

    bool saveInPlace = !isNewShortcut;
    widget.viewModel.saveShortcut.execute(toBeSaved, saveInPlace);

    Navigator.of(context).pop();
  }
}
