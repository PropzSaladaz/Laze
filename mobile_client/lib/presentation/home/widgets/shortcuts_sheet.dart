import 'package:flutter/material.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/presentation/core/ui/wide_styled_button.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';
import 'package:mobile_client/presentation/home/view_models/home_viewmodel.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/add_custom_shortcut.dart';
import 'package:mobile_client/presentation/home/widgets/shortcut_icon.dart';
import 'package:provider/provider.dart';

class ShortcutsSheet extends StatefulWidget {
  final void Function() closeScrollableSheets;
  final bool isVisible;

  const ShortcutsSheet({
    super.key,
    required this.closeScrollableSheets,
    required this.isVisible,
  });

  @override
  State<ShortcutsSheet> createState() => _ShortcutsSheetState();
}

class _ShortcutsSheetState extends State<ShortcutsSheet> {
  late DraggableScrollableController _controller;
  final double _closeThreshold = 0.2;
  final double _defaultOpenSize = 0.4;

  // animation times
  final _openAnimationTime = const Duration(milliseconds: 500);

  bool _sheetIsFullyOpen = false;
  bool _isClosingAnimation =
      false; // specifies if we are playing the closing animation

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _controller.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) => _onOpen());
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building shortcut sheet");

    return Consumer<HomeViewModel>(builder: (context, viewModel, child) {
      if (viewModel.loadShortcuts.running) {
        print("loading is running");
        return const Center(child: CircularProgressIndicator());
      }

      if (viewModel.loadShortcuts.error) {
        print("Some error" +
            viewModel.loadShortcuts.result!.asError.error.toString());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  viewModel.loadShortcuts.result!.asError.error.toString())));
        });
        return const SizedBox.shrink();
      }

      print("Building shortcuts");
      return _buildShortcutsSheet(context, viewModel.shortcuts);
    });
  }

  Widget _buildShortcutsSheet(BuildContext context, List<Shortcut> shortcuts) {
    final customColors = Theme.of(context).extension<CustomColors>();
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.linear,
            child: DraggableScrollableSheet(
                controller: _controller,
                initialChildSize: 0.0,
                minChildSize: 0,
                maxChildSize: 0.6,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      ),
                      border: Border.all(
                        width: 3.0,
                        color: customColors!.border,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 60,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "Shortcuts",
                                style: TextStyle(fontSize: 25.0),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView(
                              controller: scrollController,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 15.0,
                                mainAxisSpacing: 15.0,
                              ),
                              children: shortcuts.map((shortcut) {
                                return ShortcutIcon(shortcut: shortcut);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          ),

          // ADD BUTTON
          Positioned(
              left: 0,
              right: 0,
              bottom: 30.0,
              child: FractionallySizedBox(
                widthFactor: 0.8,
                alignment: Alignment.center,
                child: Center(
                  child: WideStyledButton(
                    icon: Icons.add,
                    onPressed: () {
                      final model = context.read<HomeViewModel>();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddCustomShortcut(viewModel: model)));
                    },
                    iconColor: Theme.of(context).colorScheme.onSecondary,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ))
        ],
      ),
    );
  }

  // animate when slide down
  void _onScroll() {
    // Check constraints to start the animation
    // 1. Sheet is open
    // 2. Sheet size is less than the closing threshold
    // 3. Closing animation isn't on yet
    if (_sheetIsFullyOpen &&
        _controller.size <= _closeThreshold &&
        !_isClosingAnimation) {
      setState(() {
        _isClosingAnimation = true;
      });

      _controller
          .animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut)
          .then((_) => widget.closeScrollableSheets());
    }
  }

// animate when opening sheet
  void _onOpen() {
    // This check is needed since the DraggableScrollableController is only attached
    // after the DraggableScrollableSheet is built into the widget tree.
    if (_controller.isAttached) {
      _controller
          .animateTo(_defaultOpenSize,
              duration: _openAnimationTime, curve: Curves.easeInOut)
          .then((_) {
        _sheetIsFullyOpen = true;
      });
    } else {
      // try again next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _onOpen());
    }
  }
}
