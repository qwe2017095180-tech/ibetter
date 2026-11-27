import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';

/// Displays an animated top floating celebration banner (when user picks "横幅" style).
/// Auto-dismisses after 3.2 seconds or when tapped/dismissed.
Future<void> showCelebrationBanner(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Color color,
  Widget? leading,
  VoidCallback? onTap,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    onTap?.call();
    return;
  }

  final completer = Completer<void>();
  late OverlayEntry entry;
  var closed = false;

  void close() {
    if (closed) return;
    closed = true;
    if (entry.mounted) {
      entry.remove();
    }
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  entry = OverlayEntry(
    builder: (ctx) => _CelebrationBannerOverlay(
      title: title,
      subtitle: subtitle,
      color: color,
      leading: leading,
      onDismiss: close,
      onTap: () {
        close();
        onTap?.call();
      },
    ),
  );

  overlay.insert(entry);
  final timer = Timer(const Duration(milliseconds: 3200), close);
  await completer.future;
  timer.cancel();
}

class _CelebrationBannerOverlay extends StatelessWidget {
  const _CelebrationBannerOverlay({
    required this.title,
    required this.subtitle,
    required this.color,
    this.leading,
    required this.onDismiss,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Widget? leading;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: topPad + 10,
      left: 14,
      right: 14,
      child: Material(
        color: Colors.transparent,
        child: Dismissible(
          key: const ValueKey('celebration_top_banner'),
          direction: DismissDirection.up,
          onDismissed: (_) => onDismiss(),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      '查看',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
