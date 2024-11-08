import 'package:flutter/material.dart';
import 'package:mobile_client/buttons/styled_button.dart';
import 'package:mobile_client/buttons/wide_styled_button.dart';
import 'package:mobile_client/color_constants.dart';
import 'package:mobile_client/shortcuts/add_custom_shortcut.dart';
import 'package:mobile_client/shortcuts/shortcut.dart';
import 'package:mobile_client/shortcuts/shortcut_icon.dart';

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
  List<Shortcut> shortcuts = [
    Shortcut(
      icon: Icons.web, 
      name: "firefox",
      commands: {'Linux' : "firefox"}),
    Shortcut(
      icon: Icons.web,
      name: "Wareztuga",
      commands: {'Linux' : 'firefox "https://wareztuga.pt/"'},
    )
  ];


  late DraggableScrollableController _controller;
  final double _closeThreshold = 0.2;
  final double _defaultOpenSize = 0.4;

  // animation times
  final _openAnimationTime = const Duration(milliseconds: 500);

  bool _sheetIsFullyOpen = false;
  bool _isClosingAnimation = false; // specifies if we are playing the closing animation
  
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

  // animate when slide down 
  void _onScroll() {
    if (_sheetIsFullyOpen && _controller.size <= _closeThreshold && !_isClosingAnimation) {
      setState(() {
        _isClosingAnimation = true;
      });

      _controller.animateTo(
        0, 
        duration: const Duration(milliseconds: 500), 
        curve: Curves.easeInOut
      ).then((_) => widget.closeScrollableSheets());
    }
  }

// animate when opening sheet
  void _onOpen() {
    _controller.animateTo(
        _defaultOpenSize, 
        duration: _openAnimationTime, 
        curve: Curves.easeInOut
      ).then((_) {
        _sheetIsFullyOpen = true;
      });
  }
  
  @override
  Widget build(BuildContext context) {
    return  SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
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
                      color: Colors.white,
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
                              style: TextStyle(
                                fontSize: 25.0
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            controller: scrollController,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 15.0,
                              mainAxisSpacing: 15.0,
                            ), 
                            itemCount: shortcuts.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ShortcutIcon(
                                shortcut: shortcuts[index],
                              );
                            }
                          ),
                        ),
                      ],
                    )
                  ),
                );
              }
            ),
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
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => AddCustomShortcut(
                        onCreateNewSHortcut: (shortcut) {
                          setState(() {
                            shortcuts.add(shortcut);
                            print("Shortcut added: ${shortcut.name}  ${shortcut.commands}");
                          });
                        },
                      )));
                  }, 
                  backgroundColor: ColorConstants.darkActionBtn, 
                  iconColor: Colors.white,
                ),
              ),
            )
          )
        ],
      ),
    );
  }
}