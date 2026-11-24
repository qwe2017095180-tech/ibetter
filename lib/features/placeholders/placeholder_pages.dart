import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/common.dart';

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('敬请期待', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class MePage extends StatelessWidget {
  const MePage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(title: '我的', icon: Icons.account_circle_outlined);
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(title: '更多', icon: Icons.more_horiz);
}
