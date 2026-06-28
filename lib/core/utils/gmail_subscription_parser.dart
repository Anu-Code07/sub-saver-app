import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/utils/subscription_detector.dart';

class GmailSubscriptionCandidate {
  const GmailSubscriptionCandidate({
    required this.provider,
    required this.name,
    required this.amount,
    required this.category,
    required this.snippet,
    this.renewalDate,
  });

  final String provider;
  final String name;
  final double? amount;
  final SubscriptionCategory category;
  final String snippet;
  final DateTime? renewalDate;
}

class GmailSubscriptionParser {
  static final _providers = <String, List<String>>{
    'Netflix': ['netflix'],
    'Prime Video': ['prime video', 'amazon prime'],
    'Disney+ Hotstar': ['hotstar', 'disney+'],
    'JioCinema': ['jiocinema', 'jio cinema'],
    'Spotify': ['spotify'],
    'YouTube Premium': ['youtube premium', 'youtube music'],
    'Apple': ['apple', 'icloud'],
    'ChatGPT': ['chatgpt', 'openai'],
  };

  static List<GmailSubscriptionCandidate> parseMessages(List<String> bodies) {
    final results = <GmailSubscriptionCandidate>[];
    final seen = <String>{};

    for (final body in bodies) {
      final lower = body.toLowerCase();
      for (final entry in _providers.entries) {
        if (!entry.value.any(lower.contains)) continue;
        if (seen.contains(entry.key)) continue;
        seen.add(entry.key);
        results.add(GmailSubscriptionCandidate(
          provider: entry.key,
          name: entry.key,
          amount: _extractAmount(body),
          category: SubscriptionDetector.detectCategory(entry.key),
          snippet: body.length > 120 ? '${body.substring(0, 120)}...' : body,
          renewalDate: _extractDate(body),
        ));
      }
    }
    return results;
  }

  static double? _extractAmount(String text) {
    final match = RegExp(r'(?:₹|rs\.?|inr|\$)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  static DateTime? _extractDate(String text) {
    final match = RegExp(r'(\d{1,2}\s(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s\d{4})', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    try {
      return DateTime.parse(match.group(1)!);
    } catch (_) {
      return null;
    }
  }
}
