import 'package:flutter/material.dart';
import 'package:mobile_client/data/state/shortcuts_provider.dart';
import 'package:mobile_client/presentation/widgets/buttons/wide_styled_button.dart';
import 'package:mobile_client/services/server_connector.dart';
import 'package:mobile_client/core/constants/color_constants.dart';
import 'package:mobile_client/controller_page.dart';
import 'package:mobile_client/data/model/shortcut.dart';
import 'package:provider/provider.dart';

class AddCustomShortcut extends StatefulWidget {

  const AddCustomShortcut({super.key});

  @override
  State<AddCustomShortcut> createState() => _AddCustomShortcutState();
}

class _AddCustomShortcutState extends State<AddCustomShortcut> {
  Shortcut shortcut = Shortcut.empty();

  @override
  Widget build(BuildContext context) {
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
                  Column(
                    children: [
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
                                  color: ColorConstants.darkText,
                                  fontSize: 39,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "Shortcut Name"
                                ),
                                onChanged: (shortcutName) {
                                  setState(() {
                                    shortcut.name = shortcutName;
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
                          color: ColorConstants.darkText,
                          fontSize: 24
                        ),
                        "Type the commands to run in the host machine's terminal"
                      ),
                      const SizedBox(height: 40.0),
                          
                      // add input box for all supported OSes
                      for (String os in ServerConnector.SUPPORTED_OSES) 
                        _terminalCommand(os),  
                    ]
                  ),
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
                        backgroundColor: ColorConstants.darkActionBtn,
                        onPressed: () { 
                          
                          Navigator.of(context).pop(); 
                        },
                        text: "CANCEL",
                        textColor: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  // CREATE BUTTON
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Consumer<ShortcutsProvider>(
                        builder: (context, shortcuts, child) {
                          return WideStyledButton(
                            backgroundColor: Colors.white,
                            onPressed: () { 
                              shortcuts.addShortcut(shortcut);
                              print("Shortcut added!");
                              Navigator.of(context).pop(); 
                            },
                            text: "CREATE",
                            textColor: ColorConstants.darkText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          );
                        }
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

  Widget _terminalCommand(String os) {
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
                color: ColorConstants.darkText,
              ),
              os
            ),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (command) => _updateCommandText(command, os),
              style: const TextStyle(
                color: ColorConstants.darkText
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

  void _updateCommandText(String command, String os) {
    shortcut.commands[os] = command;
  }
}