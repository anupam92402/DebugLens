import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_bottom_sheet.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/glass.dart';
import '../../data/bubble_store.dart';
import '../../domain/bubble_style.dart';

/// Bottom sheet for the bubble that opens the panel: which icon it shows, and
/// which edge anchor it rests at.
class BubbleSheet extends StatelessWidget {
  const BubbleSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showDebugBottomSheet<void>(context, builder: (_) => const BubbleSheet());

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      squareBottom: true,
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: BubbleStore.instance,
          builder: (context, _) {
            final store = BubbleStore.instance;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DebugStrings.settingsBubble, style: monoStyle(size: 14)),
                  const SizedBox(height: 2),
                  Text(
                    DebugStrings.bubbleHint,
                    style: monoStyle(size: 11, color: DebugColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  _header(DebugStrings.bubbleIconHeader),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option in BubbleIcon.values)
                        _IconChoice(
                          option: option,
                          selected: option == store.icon,
                          onTap: () => store.setIcon(option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _header(DebugStrings.bubblePositionHeader),
                  const SizedBox(height: 8),
                  // Two columns mirroring the screen's left and right edges, so
                  // the layout of the choices matches what they do.
                  Column(
                    children: [
                      for (final row in const [
                        [BubbleCorner.topLeft, BubbleCorner.topRight],
                        [BubbleCorner.centerLeft, BubbleCorner.centerRight],
                        [BubbleCorner.bottomLeft, BubbleCorner.bottomRight],
                      ])
                        Row(
                          children: [
                            for (final corner in row)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: _CornerChoice(
                                    corner: corner,
                                    selected: corner == store.corner,
                                    onTap: () => store.setCorner(corner),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(String text) => Text(
    text,
    style: monoStyle(
      size: 11,
      weight: FontWeight.w700,
      color: DebugColors.textMuted,
    ),
  );
}

/// One icon in the picker, ringed when selected.
class _IconChoice extends StatelessWidget {
  final BubbleIcon option;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: option.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? Colors.white : DebugColors.surfaceAlt,
            border: Border.all(
              color: selected ? DebugColors.success : DebugColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: option.glyph(
              size: 22,
              color: selected ? Colors.black : DebugColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// One anchor in the picker — a miniature screen with a dot where the bubble
/// would sit, so the choice reads without the label.
class _CornerChoice extends StatelessWidget {
  final BubbleCorner corner;
  final bool selected;
  final VoidCallback onTap;

  const _CornerChoice({
    required this.corner,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = selected ? DebugColors.success : DebugColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected ? DebugColors.surfaceAlt : Colors.transparent,
          border: Border.all(
            color: selected ? DebugColors.success : DebugColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: DebugColors.border),
              ),
              child: Align(
                alignment: corner.alignment,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                corner.label,
                maxLines: 2,
                style: monoStyle(size: 11, color: tone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
