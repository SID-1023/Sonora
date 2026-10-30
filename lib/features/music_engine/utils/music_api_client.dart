import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class MusicProviderException implements Exception {
  const MusicProviderException(
    this.message, {
    this.statusCode,
    this.retryAfter,
  });

  final String message;
  final int? statusCode;
  final Duration? retryAfter;

  @override
  String toString() => message;
}

class MusicApiClient {
  MusicApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    if (uri.scheme != 'https') {
      throw const MusicProviderException(
        'Only HTTPS API requests are allowed.',
      );
    }

    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Accept': 'application/json', ...headers})
          .timeout(timeout);
    } on TimeoutException {
      throw const MusicProviderException('The music service timed out.');
    } on http.ClientException catch (error) {
      throw MusicProviderException('Network error: ${error.message}');
    }

    if (response.statusCode == 429) {
      throw MusicProviderException(
        'The provider rate limit was reached. Please try again later.',
        statusCode: response.statusCode,
        retryAfter: _retryAfter(response.headers['retry-after']),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MusicProviderException(
        'The provider returned HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const MusicProviderException(
        'The provider returned an invalid response.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const MusicProviderException(
        'The provider returned an unexpected response.',
      );
    }

    return decoded;
  }

  Duration? _retryAfter(String? value) {
    if (value == null) return null;

    final seconds = int.tryParse(value);
    if (seconds != null && seconds > 0) {
      return Duration(seconds: seconds);
    }

    final retryDate = DateTime.tryParse(value);
    if (retryDate == null) return null;

    final delay = retryDate.difference(DateTime.now());
    return delay.isNegative ? Duration.zero : delay;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
