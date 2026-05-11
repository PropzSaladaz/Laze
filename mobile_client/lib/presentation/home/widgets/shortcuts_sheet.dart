import 'package:flutter/material.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/domain/models/shortcut/shortcut.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
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
  final ValueNotifier<String>? feedbackNotifier;

  const ShortcutsSheet({super.key, this.feedbackNotifier});

  @override
  State<ShortcutsSheet> createState() => _ShortcutsSheetState();
}

class _ShortcutsSheetState extends State<ShortcutsSheet> {
  static const double _collapsedSheetSize = 0.15;
  static const double _expandedSheetSize = 0.6;
  static const double _expansionThreshold = 0.18;

  late final DraggableScrollableController _controller;
  bool _isExpanded = false;

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
            final shouldExpand = notification.extent > _expansionThreshold;
            if (_isExpanded != shouldExpand) {
              setState(() {
                _isExpanded = shouldExpand;
              });
            }
            return false;
          },
          child: DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: _collapsedSheetSize,
            minChildSize: _collapsedSheetSize,
            maxChildSize: _expandedSheetSize,
            snap: true,
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
    final isExpanded = _isExpanded;

    final borderColor = appColors.bg.computeLuminance() > 0.5
        ? Colors.white
        : appColors.surface_3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimens.radius.large),
          topRight: Radius.circular(Dimens.radius.large),
        ),
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimens.radius.large),
          topRight: Radius.circular(Dimens.radius.large),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Dimens.radius.large),
              topRight: Radius.circular(Dimens.radius.large),
            ),
            color: appColors.bg,
          ),
          child: ListView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 4,
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
                              widget.feedbackNotifier?.value = 'Muted';
                            },
                          ),
                          StyledButton(
                            icon: Icons.skip_previous,
                            onPressed: () {
                              ServerConnector.sendInput(Input.previousTab());
                              widget.feedbackNotifier?.value = 'Prev Tab';
                            },
                          ),
                          StyledButton(
                            icon: Icons.pause,
                            onPressed: () {
                              ServerConnector.sendInput(Input.pause());
                              widget.feedbackNotifier?.value = 'Paused';
                            },
                          ),
                          StyledButton(
                            icon: Icons.skip_next,
                            onPressed: () {
                              ServerConnector.sendInput(Input.nextTab());
                              widget.feedbackNotifier?.value = 'Next Tab';
                            },
                          ),
                          StyledButton(
                            icon: Icons.close,
                            onPressed: () {
                              ServerConnector.sendInput(Input.closeTab());
                              widget.feedbackNotifier?.value = 'Tab Closed';
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 4, 48, 0),
                  child: CustomPaint(
                    painter: _DashedLinePainter(color: appColors.divider),
                    child: const SizedBox(height: 1, width: double.infinity),
                  ),
                ),
              if (isExpanded)
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomPadding),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final contentHeight = constraints.maxHeight.isFinite &&
                              constraints.maxHeight > 0
                          ? constraints.maxHeight
                          : (MediaQuery.of(context).size.height * 0.34)
                              .clamp(240.0, 360.0);

                      return SizedBox(
                        height: contentHeight,
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildShortcutsContent(context, viewModel),
                            ),
                            const SizedBox(height: 36),
                            CtaButton(
                              icon: Icons.add,
                              onPressed: _openShortcutsEditPage,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutsContent(
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    if (viewModel.loadShortcuts.running) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.loadShortcuts.error) {
      return Center(
        child: Text(
          'Failed to load shortcuts.',
          textAlign: TextAlign.center,
          style: TextStyle(color: appColors.textMuted),
        ),
      );
    }

    if (viewModel.shortcuts.isEmpty) {
      return Center(
        child: Text(
          'No shortcuts yet.',
          style: TextStyle(color: appColors.textMuted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 520
            ? 5
            : width >= 420
                ? 4
                : width >= 320
                    ? 3
                    : 2;
        final spacing = Dimens.spacing.xs;

        return GridView.builder(
          primary: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: viewModel.shortcuts.length,
          itemBuilder: (context, index) {
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
              child: ShortcutIcon(
                shortcut: shortcut,
                feedbackNotifier: widget.feedbackNotifier,
              ),
            );
          },
        );
      },
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

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashGap = 5.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, y), Offset((x + dashWidth).clamp(0, size.width), y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
