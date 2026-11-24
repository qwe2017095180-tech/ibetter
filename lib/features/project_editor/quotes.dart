import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fallback motivational lines used if loading `assets/quotes.json` fails.
const List<String> fallbackQuotes = [
  '自己来选择，不会后悔的道路。',
  '每天进步一点点，时间会给出答案。',
  '把想做的事，变成每天的习惯。',
  '坚持不是硬撑，而是温和地重复。',
  '慢一点没关系，只要方向对了就好。',
  '每一次打卡，都是对自己的郑重承诺。',
  '保持热爱，也保持日复一日的耐心。',
  '今天的汗水，会变成明天的底气。',
];

/// Loads motivational quotes from `assets/quotes.json`, falling back to
/// [fallbackQuotes] when the asset is missing or malformed.
Future<List<String>> loadQuotes({AssetBundle? bundle}) async {
  try {
    final raw = await (bundle ?? rootBundle).loadString('assets/quotes.json');
    final decoded = jsonDecode(raw);
    if (decoded is! List) return fallbackQuotes;
    final parsed = decoded
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length <= 40)
        .toList(growable: false);
    return parsed.isEmpty ? fallbackQuotes : parsed;
  } catch (_) {
    return fallbackQuotes;
  }
}

/// Picks a random quote from [quotes] that differs from [current] whenever possible.
String pickRandomQuote(
  List<String> quotes, {
  String? current,
  Random? random,
}) {
  final pool = quotes.isEmpty ? fallbackQuotes : quotes;
  final candidates = current != null && current.isNotEmpty
      ? pool.where((q) => q != current).toList(growable: false)
      : pool;
  final source = candidates.isEmpty ? pool : candidates;
  final rng = random ?? Random();
  return source[rng.nextInt(source.length)];
}

/// Injectable quote loader so widget/unit tests can override if needed.
final quotesLoaderProvider = Provider<Future<List<String>> Function()>((ref) => loadQuotes);
