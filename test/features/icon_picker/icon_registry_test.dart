import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibetter/app/theme/app_colors.dart';
import 'package:ibetter/features/icon_picker/icon_picker_grid.dart';
import 'package:ibetter/features/icon_picker/icon_picker_page.dart';
import 'package:ibetter/features/icon_picker/icon_registry.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('IconRegistry catalog', () {
    test('every key in categories has an existing PNG file on disk and matches disk exactly', () {
      expect(File('pubspec.yaml').existsSync(), isTrue, reason: 'Run tests from project root');
      expect(IconRegistry.categories, isNotEmpty);

      final seenCategoryKeys = <String>{};
      final seenIconKeys = <String>{};
      final validKeyPattern = RegExp(r'^[a-z0-9_]+/[a-z0-9_]+$');

      for (final category in IconRegistry.categories) {
        expect(seenCategoryKeys.add(category.key), isTrue, reason: 'Duplicate category ${category.key}');
        expect(category.title, isNotEmpty);
        expect(category.iconKeys, isNotEmpty);

        for (final key in category.iconKeys) {
          expect(validKeyPattern.hasMatch(key), isTrue, reason: 'Invalid icon key format: $key');
          expect(key.startsWith('${category.key}/'), isTrue,
              reason: 'Icon key $key does not belong to category ${category.key}');
          expect(seenIconKeys.add(key), isTrue, reason: 'Duplicate icon key: $key');

          final file = File('assets/icons/$key.png');
          expect(file.existsSync(), isTrue, reason: 'Missing asset file for $key at ${file.path}');
          expect(file.lengthSync(), greaterThan(0), reason: 'Empty asset file for $key');
        }
      }

      // Verify no unregistered PNGs exist on disk under assets/icons/.
      final diskKeys = <String>{};
      final iconsRoot = Directory('assets/icons');
      for (final entity in iconsRoot.listSync(recursive: true).whereType<File>()) {
        if (!entity.path.endsWith('.png')) continue;
        final normalized = entity.path.replaceAll('\\', '/');
        final rel = normalized.substring('assets/icons/'.length, normalized.length - '.png'.length);
        diskKeys.add(rel);
      }

      expect(seenIconKeys, equals(diskKeys));
      expect(seenIconKeys.length, greaterThanOrEqualTo(120));
    });

    test('defaultKey and fallbackKey exist in categories and on disk', () {
      final allKeys = {for (final c in IconRegistry.categories) ...c.iconKeys};

      expect(IconRegistry.defaultKey, 'study/book');
      expect(IconRegistry.fallbackKey, 'achievement/star');
      expect(allKeys, contains(IconRegistry.defaultKey));
      expect(allKeys, contains(IconRegistry.fallbackKey));
      expect(File('assets/icons/${IconRegistry.defaultKey}.png').existsSync(), isTrue);
      expect(File('assets/icons/${IconRegistry.fallbackKey}.png').existsSync(), isTrue);
    });
  });

  group('HabitIcon & IconPickerGrid widgets', () {
    testWidgets('HabitIcon renders valid and unknown keys without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                HabitIcon(IconRegistry.defaultKey),
                HabitIcon('nope/none'),
                HabitIcon(''),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, 3);
      expect((images[0].image as AssetImage).assetName, 'assets/icons/study/book.png');
      expect((images[1].image as AssetImage).assetName, 'assets/icons/achievement/star.png');
      expect((images[2].image as AssetImage).assetName, 'assets/icons/achievement/star.png');
    });

    testWidgets('IconPickerGrid renders headers, highlights selection, and calls onSelected on tap', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IconPickerGrid(
                selectedKey: IconRegistry.defaultKey,
                onSelected: (key) => tapped = key,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('追求成就'), findsOneWidget);
      expect(find.text('更健康（早睡早起,每日果蔬,喝牛奶,敷面膜...）'), findsOneWidget);
      expect(find.text('爱学习（读书,背单词,练字...）'), findsOneWidget);

      // Selected tile displays a 2px AppColors.primary border.
      final selectedBorderFinder = find.byWidgetPredicate((widget) {
        if (widget is AnimatedContainer && widget.decoration is BoxDecoration) {
          final border = (widget.decoration! as BoxDecoration).border;
          if (border is Border) {
            return border.top.color == AppColors.primary && border.top.width == 2;
          }
        }
        return false;
      });
      expect(selectedBorderFinder, findsOneWidget);

      final targetTile = find.bySemanticsLabel('achievement/trophy');
      expect(targetTile, findsOneWidget);
      await tester.ensureVisible(targetTile);
      await tester.tap(targetTile);
      await tester.pumpAndSettle();

      expect(tapped, 'achievement/trophy');
    });

    testWidgets('IconPickerPage pushes and returns selected key via Navigator.pop', (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const IconPickerPage(selectedKey: IconRegistry.defaultKey),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('选择图标'), findsOneWidget);

      final targetTile = find.bySemanticsLabel('achievement/rocket');
      await tester.ensureVisible(targetTile);
      await tester.tap(targetTile);
      await tester.pumpAndSettle();

      expect(result, 'achievement/rocket');
    });
  });
}
