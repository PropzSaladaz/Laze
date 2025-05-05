import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mobile_client/core/os_config.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/presentation/core/ui/wide_styled_button.dart';
import 'package:mobile_client/presentation/home/view_models/home_viewmodel.dart';
import 'package:mobile_client/presentation/new_shortcut/view_models/add_custom_shortcut_viewmodel.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';
import 'package:mobile_client/presentation/core/ui/controller_page.dart';
import 'package:provider/provider.dart';

class AddCustomShortcut extends StatefulWidget {
  const AddCustomShortcut({super.key});

  @override
  State<AddCustomShortcut> createState() => _AddCustomShortcutState();
}

class _AddCustomShortcutState extends State<AddCustomShortcut> {
  // initial shortcut data
  IconData icon = Icons.abc;
  String shortcutName = "";
  Map<String, String> commands = HashMap();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildWidget(context);
  }

  AddCustomShortcutViewModel _createViewModel(BuildContext context) {
    final repo = context.read<ShortcutsRepository>();
    return AddCustomShortcutViewModel(shortcutsRepository: repo);
  }

  Widget _buildWidget(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();

    return ControllerPage(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Column(children: [
                    const SizedBox(height: 20.0),
                    // Shortcut Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FractionallySizedBox(
                            widthFactor: 0.7,
                            child: TextField(
                              style: const TextStyle(
                                // color: ColorConstants.darkText,
                                fontSize: 39,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                  hintText: "Shortcut Name"),
                              onChanged: (name) {
                                setState(() {
                                  shortcutName = name;
                                });
                              },
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.abc,
                          size: 50,
                        )
                      ],
                    ),
                    const SizedBox(height: 40.0),
                    const Text(
                        style: TextStyle(
                            // color: ColorConstants.darkText,
                            fontSize: 24),
                        "Type the commands to run in the host machine's terminal"),
                    const SizedBox(height: 40.0),

                    // add input box for all supported OSes
                    for (var os in SUPPORTED_OSES)
                      _terminalCommand(os.name, context),
                  ]),
                ],
              ),
            ),
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
                      child: Consumer<HomeViewModel>(
                          builder: (context, shortcutsViewModel, child) {
                        return WideStyledButton(
                          backgroundColor: customColors.negativePrimary,
                          onPressed: () =>
                              _saveShortcutData(shortcutsViewModel),
                          text: "CREATE",
                          // textColor: ColorConstants.darkText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        );
                      }),
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

  void _saveShortcutData(HomeViewModel shortcutsViewModel) {
    Shortcut toBeSaved =
        Shortcut(commands: commands, icon: icon, name: shortcutName);
    shortcutsViewModel.saveShortcut.execute(toBeSaved);
    print("Shortcut added!");
    Navigator.of(context).pop();
  }

  Widget _terminalCommand(String os, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
                style: const TextStyle(
                  fontSize: 20,
                  // color: ColorConstants.darkText,
                ),
                os),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: const BorderRadius.all(Radius.circular(25.0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (command) {
                setState(() {
                  commands[os] = command;
                });
              },
              style: const TextStyle(
                  // color: ColorConstants.darkText
                  ),
              maxLines: 2,
              maxLength: 256,
              decoration: const InputDecoration(
                prefixText: "\$ ",
                hintText: "firefox 'https://google.com'",
                border: InputBorder.none,
              ),
            ),
          )
        ],
      ),
    );
  }
}
