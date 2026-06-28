import 'package:cloud_functions/cloud_functions.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';

class ReminderService {
  ReminderService(this._functions);

  final FirebaseFunctions _functions;

  Future<String> generateReminder({
    required String subscriptionName,
    required double amount,
    required AiTone tone,
    required String memberName,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateAiReminder').call({
        'subscriptionName': subscriptionName,
        'amount': amount,
        'tone': tone.name,
        'memberName': memberName,
      });
      final data = result.data as Map<dynamic, dynamic>;
      return data['message'] as String? ?? _fallback(subscriptionName, amount, tone, memberName);
    } catch (_) {
      return _fallback(subscriptionName, amount, tone, memberName);
    }
  }

  String _fallback(String name, double amount, AiTone tone, String member) {
    return switch (tone) {
      AiTone.funny => 'Yo $member 😄 $name renewal is coming. Your share is ₹${amount.toStringAsFixed(0)}. Pay up before Netflix judges us!',
      AiTone.professional => 'Dear $member, your share of ₹${amount.toStringAsFixed(0)} for $name is due soon.',
      AiTone.aggressive => '$member! Pay ₹${amount.toStringAsFixed(0)} for $name NOW.',
      AiTone.passiveAggressive => 'Oh $member... $name is renewing again. Just ₹${amount.toStringAsFixed(0)}. No rush. (There is rush.)',
      _ => 'Hey $member 👋 $name renewal is coming up. Your share is ₹${amount.toStringAsFixed(0)}.',
    };
  }
}
