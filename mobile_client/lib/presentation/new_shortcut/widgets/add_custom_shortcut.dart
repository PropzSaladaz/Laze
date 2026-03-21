import 'package:flutter/material.dart';
import 'package:laze/core/os_config.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/cta_button.dart';
import 'package:laze/presentation/new_shortcut/view_models/add_custom_shortcut_viewmodel.dart';
import 'package:laze/presentation/new_shortcut/widgets/shortcut_input_row.dart';
import 'package:laze/presentation/new_shortcut/widgets/terminal_command.dart';
import 'package:laze/services/server_connector.dart';
import 'package:provider/provider.dart';

class AddCustomShortcut extends StatelessWidget {
  const AddCustomShortcut({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcutVM = context.watch<AddCustomShortcutViewModel>();
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isSaving = shortcutVM.saveShortcut.running;

    return ControllerPage(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            child: Padding(
              padding: EdgeInsets.only(top: scale.spaceLg),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      clipBehavior: Clip.none,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          scale.spaceXl,
                          scale.spaceXl,
                          scale.spaceXl,
                          scale.spaceXl,
                        ),
                        decoration: BoxDecoration(
                          color: appColors.bg,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: appColors.surface_1,
                            width: 2,
                          ),
                          boxShadow: AppShadows.raisedControl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShortcutInputRow(
                              initShortcutName: shortcutVM.name,
                              initIcon: shortcutVM.icon,
                              onNameChanged: shortcutVM.setName,
                              onIconSelected: shortcutVM.setIcon,
                            ),
                            SizedBox(height: scale.spaceXl),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: scale.spaceLg,
                              ),
                              child: Container(
                                height: 1,
                                color: appColors.divider,
                              ),
                            ),
                            SizedBox(height: scale.spaceXl),
                            Text(
                              "Type the commands to run in the host machine:",
                              style: TextStyle(
                                color: appColors.textMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: scale.spaceXl),
                            for (final os in SUPPORTED_OSES)
                              TerminalCommandInput(
                                operativeSystemName: os.name,
                                initCommand: shortcutVM.commands.containsKey(
                                  os.name,
                                )
                                    ? shortcutVM.commands[os.name]
                                    : '',
                                onCommandUpdated: (newCommand) {
                                  shortcutVM.setCommand(os.name, newCommand);
                                },
                              ),
                            SizedBox(height: scale.spaceXl),
                            _FlatTestButton(
                              onPressed: () {
                                ServerConnector.sendInput(
                                  Input.runCommand(shortcutVM.commands),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: scale.spaceXl),
                  Row(
                    children: [
                      Expanded(
                        child: CtaButton(
                          text: 'CANCEL',
                          widthFactor: 0.92,
                          borderWidth: 4,
                          fontSize: 26,
                          backgroundColor: appColors.bg,
                          foregroundColor: appColors.textMuted,
                          borderColor: appColors.surface_1,
                          onPressed: () {
                            if (!isSaving) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                      SizedBox(width: scale.spaceMd),
                      Expanded(
                        child: CtaButton(
                          text: isSaving
                              ? 'SAVING'
                              : (shortcutVM.isNew ? 'CREATE' : 'SAVE'),
                          widthFactor: 0.92,
                          fontSize: 26,
                          onPressed: () async {
                            if (isSaving) {
                              return;
                            }
                            await shortcutVM.saveShortcut.execute();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: scale.spaceLg + bottomPadding),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlatTestButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FlatTestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appColors.border,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: appColors.divider, width: 1),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: const StadiumBorder(),
          overlayColor: appColors.text,
        ),
        child: Text(
          'TEST',
          style: TextStyle(
            color: appColors.textMuted,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFamily: 'NunitoSans',
          ),
        ),
      ),
    );
  }
}
