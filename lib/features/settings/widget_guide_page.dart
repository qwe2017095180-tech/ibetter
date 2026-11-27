import 'package:material_ui/material_ui.dart';

import '../../app/app_brand.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../icon_picker/icon_registry.dart';

/// "调整桌面小部件" guide page previewing Android home screen widgets.
class WidgetGuidePage extends StatelessWidget {
  const WidgetGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: '调整桌面小部件',
        leading: PillIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF9CD8FF), Color(0xFFBDE6FF)],
                ),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const Positioned(
                    left: 24,
                    top: 38,
                    child: Icon(Icons.auto_awesome, color: Color(0xFFFFE566), size: 30),
                  ),
                  const Positioned(
                    right: 22,
                    bottom: 66,
                    child: Icon(Icons.star, color: Color(0xFFFFE566), size: 18),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24, left: 32, right: 32),
                    child: Container(
                      width: 280,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 14,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF284366), Color(0xFF1A283A)],
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.search, size: 16, color: AppColors.primary),
                                    SizedBox(width: 6),
                                    Text(
                                      '桌面长按空白处 · 添加小部件',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _WidgetPreviewBox(
                                child: Column(
                                  children: [
                                    _PreviewRow(
                                      color: const Color(0xFFFF7828),
                                      iconKey: 'health/droplet',
                                      label: '早起喝水',
                                      done: true,
                                    ),
                                    const SizedBox(height: 6),
                                    _PreviewRow(
                                      color: const Color(0xFF2A9DF4),
                                      iconKey: 'study/book',
                                      label: '背单词',
                                      done: false,
                                    ),
                                    const SizedBox(height: 6),
                                    _PreviewRow(
                                      color: const Color(0xFFFFA51F),
                                      iconKey: 'life/guitar',
                                      label: '练吉他',
                                      done: false,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _WidgetPreviewBox(
                                child: Row(
                                  children: const [
                                    Expanded(
                                      child: _CompactChip(
                                        color: Color(0xFFFF7828),
                                        label: '做瑜伽',
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: _CompactChip(
                                        color: Color(0xFF2A9DF4),
                                        label: '练吉他',
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: _CompactChip(
                                        color: Color(0xFFFFA51F),
                                        label: '背单词',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '在主屏长按添加 ${AppBrand.name} 挂件',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '随时打卡，实现每日目标',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetPreviewBox extends StatelessWidget {
  const _WidgetPreviewBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                AppBrand.name,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.color,
    required this.iconKey,
    required this.label,
    required this.done,
  });

  final Color color;
  final String iconKey;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          HabitIcon(iconKey, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: done ? Colors.white.withValues(alpha: 0.3) : Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: done ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
        ],
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
