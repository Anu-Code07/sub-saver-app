class ParsedReceipt {
  const ParsedReceipt({
    this.amount,
    this.referenceId,
    this.date,
    this.receiver,
    this.rawText = '',
  });

  final double? amount;
  final String? referenceId;
  final DateTime? date;
  final String? receiver;
  final String rawText;
}

class PaymentReceiptParser {
  static ParsedReceipt parse(String text) {
    final amount = _extractAmount(text);
    final referenceId = _extractReference(text);
    final receiver = _extractReceiver(text);
    return ParsedReceipt(
      amount: amount,
      referenceId: referenceId,
      receiver: receiver,
      rawText: text,
    );
  }

  static double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'(?:₹|rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:₹|rs\.?|inr)', caseSensitive: false),
      RegExp(r'amount[:\s]+([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', ''));
      }
    }
    return null;
  }

  static String? _extractReference(String text) {
    final patterns = [
      RegExp(r'(?:upi ref|ref(?:erence)?|txn|transaction)\s*(?:no\.?|id)?[:\s#-]*([A-Z0-9]{8,})', caseSensitive: false),
      RegExp(r'\b([0-9]{12,})\b'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _extractReceiver(String text) {
    final match = RegExp(r'(?:paid to|to|receiver)[:\s]+([A-Za-z0-9 @._-]{3,})', caseSensitive: false).firstMatch(text);
    return match?.group(1)?.trim();
  }
}
