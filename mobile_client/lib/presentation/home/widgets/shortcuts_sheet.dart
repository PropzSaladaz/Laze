import 'package:flutter/material.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/domain/models/shortcut/shortcut.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/cta_button.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/home/view_models/home_viewmodel.dart';
import 'package:laze/presentation/home/widgets/shortcut_icon.dart';
import 'package:laze/presentation/new_shortcut/view_models/add_custom_shortcut_viewmodel.dart';
import 'package:laze/presentation/new_shortcut/widgets/add_custom_shortcut.dart';
import 'package:laze/services/server_connector.dart';
import 'package:provider/provider.dart';

class ShortcutsSheet extends StatefulWidget {
  const ShortcutsSheet({super.key});

  @override
  State<ShortcutsSheet> createState() => _ShortcutsSheetState();
}

class _ShortcutsSheetState extends State<ShortcutsSheet> {
  late final DraggableScrollableController _controller;
  double _currentSheetSize = 0.15;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            if (_currentSheetSize != notification.extent) {
              setState(() {
                _currentSheetSize = notification.extent;
              });
            }
            return false;
          },
          child: DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return _buildShortcutsSheet(
                context,
                viewModel,
                scrollController,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShortcutsSheet(
    BuildContext context,
    HomeViewModel viewModel,
    ScrollController scrollController,
  ) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isExpanded = _currentSheetSize > 0.18;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(82),
          topRight: Radius.circular(82),
        ),
        boxShadow: [
          BoxShadow(
            color: appColors.border.withValues(alpha: 0.01),
            offset: const Offset(0, -19),
            blurRadius: 5,
          ),
          BoxShadow(
            color: appColors.border.withValues(alpha: 0.07),
            offset: const Offset(0, -12),
            blurRadius: 5,
          ),
          BoxShadow(
            color: appColors.border.withValues(alpha: 0.23),
            offset: const Offset(0, -7),
            blurRadius: 4,
          ),
          BoxShadow(
            color: appColors.border.withValues(alpha: 0.38),
            offset: const Offset(0, -3),
            blurRadius: 3,
          ),
          BoxShadow(
            color: appColors.border.withValues(alpha: 0.44),
            offset: const Offset(0, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(82),
          topRight: Radius.circular(82),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(82),
              topRight: Radius.circular(82),
            ),
            border: Border(
              left: BorderSide(color: appColors.textInverse, width: 3),
              top: BorderSide(color: appColors.textInverse, width: 3),
              right: BorderSide(color: appColors.textInverse, width: 3),
            ),
            color: appColors.bg,
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 6,
                      decoration: BoxDecoration(
                        color: appColors.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StyledButton(
                            icon: Icons.volume_off,
                            onPressed: () {
                              ServerConnector.sendInput(Input.mute());
                            },
                          ),
                          StyledButton(
                            icon: Icons.skip_previous,
                            onPressed: () {
                              ServerConnector.sendInput(Input.previousTab());
                            },
                          ),
                          StyledButton(
                            icon: Icons.pause,
                            onPressed: () {
                              ServerConnector.sendInput(Input.pause());
                            },
                          ),
                          StyledButton(
                            icon: Icons.skip_next,
                            onPressed: () {
                              ServerConnector.sendInput(Input.nextTab());
                            },
                          ),
                          StyledButton(
                            icon: Icons.close,
                            onPressed: () {
                              ServerConnector.sendInput(Input.closeTab());
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Shortcuts',
                    style: TextStyle(
                      fontSize: 25,
                      color: appColors.text,
                    ),
                  ),
                ),
              ),
            if (isExpanded && viewModel.loadShortcuts.running)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (isExpanded &&
                !viewModel.loadShortcuts.running &&
                viewModel.loadShortcuts.error)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Failed to load shortcuts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: appColors.textMuted),
                  ),
                ),
              ),
            if (isExpanded &&
                !viewModel.loadShortcuts.running &&
                !viewModel.loadShortcuts.error)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shortcut = viewModel.shortcuts[index];
                      return GestureDetector(
                        onLongPressStart: (details) {
                          _showOptionsMenu(
                            context,
                            viewModel,
                            details.globalPosition,
                            shortcut,
                          );
                        },
                        child: ShortcutIcon(shortcut: shortcut),
                      );
                    },
                    childCount: viewModel.shortcuts.length,
                  ),
                ),
              ),
            if (isExpanded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
                  child: CtaButton(
                    text: 'Add Shortcut',
                    onPressed: () {
                      _openShortcutsEditPage();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(
    BuildContext context,
    HomeViewModel viewModel,
    Offset position,
    Shortcut shortcut,
  ) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      elevation: 20,
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );

    if (!mounted) {
      return;
    }

    if (result == 'edit') {
      _openShortcutsEditPage(shortcut: shortcut);
    } else if (result == 'delete') {
      await viewModel.deleteShortcut.execute(shortcut);
    }
  }

  void _openShortcutsEditPage({Shortcut? shortcut}) {
    final model = context.read<HomeViewModel>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AddCustomShortcutViewModel(
            homeViewModel: model,
            shortcut: shortcut,
          ),
          child: const AddCustomShortcut(),
        ),
      ),
    );
  }
}
