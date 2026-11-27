import 'package:material_ui/material_ui.dart';

import '../../../app/app_brand.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/prefs/app_prefs.dart';

/// Mini-phone preview choices for "选择卡片风格" (彩色 vs 纯白).
class CardStyleChoiceRow extends StatelessWidget {
  const CardStyleChoiceRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CardStyle selected;
  final ValueChanged<CardStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _PhoneChoiceTile(
              key: const ValueKey('card_style_colorful'),
              label: '彩色',
              isSelected: selected == CardStyle.colorful,
              onTap: () => onSelected(CardStyle.colorful),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _MiniBar(color: const Color(0xFF1D9BF0), checkColor: Colors.white),
                  const SizedBox(height: 4),
                  _MiniBar(color: const Color(0xFFFF7A21), checkColor: Colors.white),
                  const SizedBox(height: 4),
                  _MiniBar(color: const Color(0xFFFFA51F), checkColor: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _PhoneChoiceTile(
              key: const ValueKey('card_style_white'),
              label: '纯白',
              isSelected: selected == CardStyle.white,
              onTap: () => onSelected(CardStyle.white),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _MiniBar(
                    color: Colors.white,
                    borderColor: const Color(0xFFE5E5E5),
                    checkColor: AppColors.done,
                  ),
                  const SizedBox(height: 4),
                  _MiniBar(
                    color: Colors.white,
                    borderColor: const Color(0xFFE5E5E5),
                    checkColor: AppColors.done,
                  ),
                  const SizedBox(height: 4),
                  _MiniBar(
                    color: Colors.white,
                    borderColor: const Color(0xFFE5E5E5),
                    checkColor: AppColors.done,
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

/// 3-column layout choices for "选择卡片布局" (标准 / 紧凑 / 超紧凑).
class CardLayoutChoiceRow extends StatelessWidget {
  const CardLayoutChoiceRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CardLayout selected;
  final ValueChanged<CardLayout> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _LayoutOption(
              key: const ValueKey('card_layout_standard'),
              label: '标准',
              isSelected: selected == CardLayout.standard,
              onTap: () => onSelected(CardLayout.standard),
              thumbnail: Column(
                children: const [
                  _ThumbRect(color: Color(0xFF42A5F5), height: 18),
                  SizedBox(height: 4),
                  _ThumbRect(color: Color(0xFFFF7043), height: 18),
                  SizedBox(height: 4),
                  _ThumbRect(color: Color(0xFFFFA726), height: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _LayoutOption(
              key: const ValueKey('card_layout_compact'),
              label: '紧凑',
              isSelected: selected == CardLayout.compact,
              onTap: () => onSelected(CardLayout.compact),
              thumbnail: Column(
                children: [
                  for (final pair in const [
                    [Color(0xFF42A5F5), Color(0xFF9FA8DA)],
                    [Color(0xFF9CCC65), Color(0xFFFFA726)],
                    [Color(0xFFFF7043), Color(0xFF29B6F6)],
                    [Color(0xFFF06292), Color(0xFF7E57C2)],
                  ]) ...[
                    Row(
                      children: [
                        Expanded(child: _ThumbRect(color: pair[0], height: 12)),
                        const SizedBox(width: 3),
                        Expanded(child: _ThumbRect(color: pair[1], height: 12)),
                      ],
                    ),
                    const SizedBox(height: 3),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _LayoutOption(
              key: const ValueKey('card_layout_ultraCompact'),
              label: '超紧凑',
              isSelected: selected == CardLayout.ultraCompact,
              onTap: () => onSelected(CardLayout.ultraCompact),
              thumbnail: Column(
                children: [
                  for (final row in const [
                    [Color(0xFF42A5F5), Color(0xFF9FA8DA), Color(0xFFFFA726)],
                    [Color(0xFF9CCC65), Color(0xFF29B6F6), Color(0xFFFF7043)],
                    [Color(0xFF3F51B5), Color(0xFFF06292), Color(0xFF7E57C2)],
                  ]) ...[
                    Row(
                      children: [
                        Expanded(child: _ThumbRect(color: row[0], height: 17)),
                        const SizedBox(width: 3),
                        Expanded(child: _ThumbRect(color: row[1], height: 17)),
                        const SizedBox(width: 3),
                        Expanded(child: _ThumbRect(color: row[2], height: 17)),
                      ],
                    ),
                    const SizedBox(height: 3),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2-column mini-phone preview choices for "卡片" vs "横幅" celebration styles.
class CelebrationStyleChoiceRow extends StatelessWidget {
  const CelebrationStyleChoiceRow({
    super.key,
    required this.prefixKey,
    required this.selected,
    required this.onSelected,
  });

  final String prefixKey;
  final CelebrationStyle selected;
  final ValueChanged<CelebrationStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _SimplePhoneChoiceTile(
              key: ValueKey('${prefixKey}_card'),
              label: '卡片',
              isSelected: selected == CelebrationStyle.card,
              onTap: () => onSelected(CelebrationStyle.card),
              overlay: Center(
                child: Container(
                  width: 68,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFF399BFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _SimplePhoneChoiceTile(
              key: ValueKey('${prefixKey}_banner'),
              label: '横幅',
              isSelected: selected == CelebrationStyle.banner,
              onTap: () => onSelected(CelebrationStyle.banner),
              overlay: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 68,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF399BFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneChoiceTile extends StatelessWidget {
  const _PhoneChoiceTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.body,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 146,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  AppBrand.name,
                  style: TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                body,
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SelectionPill(label: label, isSelected: isSelected),
        ],
      ),
    );
  }
}

class _SimplePhoneChoiceTile extends StatelessWidget {
  const _SimplePhoneChoiceTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.overlay,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget overlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 136,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: overlay,
            ),
          ),
          const SizedBox(height: 10),
          _SelectionPill(label: label, isSelected: isSelected),
        ],
      ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  const _LayoutOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.thumbnail,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget thumbnail;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 82,
            height: 66,
            child: Center(child: thumbnail),
          ),
          const SizedBox(height: 8),
          _SelectionPill(label: label, isSelected: isSelected),
        ],
      ),
    );
  }
}

class _SelectionPill extends StatelessWidget {
  const _SelectionPill({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF5698DF) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isSelected ? const Color(0xFF5698DF) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(Icons.check, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.color,
    this.borderColor,
    required this.checkColor,
  });

  final Color color;
  final Color? borderColor;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      alignment: Alignment.centerRight,
      child: Icon(Icons.check_box_outlined, size: 10, color: checkColor),
    );
  }
}

class _ThumbRect extends StatelessWidget {
  const _ThumbRect({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
