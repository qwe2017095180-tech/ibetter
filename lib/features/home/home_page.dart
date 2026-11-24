import 'package:material_ui/material_ui.dart';

import '../../core/widgets/common.dart';

/// STUB — owned by WP4 (Home: calendar + today's check-in list). Replace entirely.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar(title: 'iBetter'),
      body: Center(child: Text('Home (WP4)')),
    );
  }
}
