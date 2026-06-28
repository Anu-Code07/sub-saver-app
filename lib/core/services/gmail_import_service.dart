import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:subsaver/core/utils/gmail_subscription_parser.dart';

class GmailImportService {
  GmailImportService(this._dio);

  static const _gmailReadonlyScope =
      'https://www.googleapis.com/auth/gmail.readonly';

  final Dio _dio;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', _gmailReadonlyScope],
  );

  Future<List<GmailSubscriptionCandidate>> scanSubscriptions() async {
    final account =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) return const [];

    final headers = await account.authHeaders;
    final messages = await _dio.get<Map<String, dynamic>>(
      'https://gmail.googleapis.com/gmail/v1/users/me/messages',
      queryParameters: {
        'maxResults': 30,
        'q':
            '(subscription OR renewal OR receipt OR invoice OR charged OR payment) newer_than:365d',
      },
      options: Options(headers: headers),
    );

    final ids = ((messages.data?['messages'] as List?) ?? const [])
        .map((item) => (item as Map<String, dynamic>)['id'] as String?)
        .whereType<String>()
        .toList();

    final bodies = <String>[];
    for (final id in ids) {
      final message = await _dio.get<Map<String, dynamic>>(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$id',
        queryParameters: {'format': 'full'},
        options: Options(headers: headers),
      );
      final body = _extractMessageText(message.data?['payload']);
      if (body.trim().isNotEmpty) bodies.add(body);
    }

    return GmailSubscriptionParser.parseMessages(bodies);
  }

  String _extractMessageText(Object? payload) {
    if (payload is! Map<String, dynamic>) return '';
    final fragments = <String>[];

    void visit(Map<String, dynamic> part) {
      final mimeType = part['mimeType'] as String? ?? '';
      final data = (part['body'] as Map<String, dynamic>?)?['data'] as String?;
      if (data != null &&
          (mimeType.startsWith('text/plain') || mimeType.startsWith('text/html'))) {
        fragments.add(_decodeBody(data, isHtml: mimeType.startsWith('text/html')));
      }

      final parts = part['parts'] as List?;
      if (parts == null) return;
      for (final child in parts.whereType<Map<String, dynamic>>()) {
        visit(child);
      }
    }

    visit(payload);
    return fragments.join('\n\n');
  }

  String _decodeBody(String data, {required bool isHtml}) {
    final normalized = data.replaceAll('-', '+').replaceAll('_', '/');
    final padded = normalized.padRight(
      normalized.length + ((4 - normalized.length % 4) % 4),
      '=',
    );
    final decoded = utf8.decode(base64.decode(padded), allowMalformed: true);
    if (!isHtml) return decoded;
    return decoded
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
