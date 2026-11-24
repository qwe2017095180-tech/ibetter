import 'package:material_ui/material_ui.dart';

import '../../core/widgets/common.dart';

/// STUB — owned by WP6 (创建/编辑项目). Replace entirely.
/// [habitId] null = create, otherwise edit.
class ProjectEditorPage extends StatelessWidget {
  const ProjectEditorPage({super.key, this.habitId});

  final int? habitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: habitId == null ? '创建项目' : '编辑项目'),
      body: const Center(child: Text('Editor (WP6)')),
    );
  }
}
