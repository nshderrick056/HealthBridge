
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';

class ApiException implements Exception {
  ApiException(this.status, this.code);

  final int status;
  final String code;

  @override
  String toString() => 'ApiException($status, $code)';
}

class ApiClient {
  ApiClient({
    required this.auth,
    required this.session,
    required this.onSession,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final AuthService auth;
  final Session? Function() session;
  final void Function(Session) onSession;
  final http.Client _client;

  static const _timeout = Duration(seconds: 20);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) {
    return _call('GET', path, query: query);
  }

  Future<Map<String, dynamic>> post(
    String path, [
    Object? body,
  ]) {
    return _call('POST', path, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Object body,
  ) {
    return _call('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> _call(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    var currentSession = session();

    if (currentSession == null) {
      throw ApiException(401, 'signed_out');
    }

    var response = await _send(
      method,
      path,
      currentSession,
      body,
      query,
    );

    if (response.statusCode == 401) {
      try {
        currentSession = await auth.refresh(currentSession);
      } on AuthException {
        throw ApiException(401, 'session_expired');
      } catch (_) {
        throw ApiException(401, 'session_expired');
      }

      onSession(currentSession);

      response = await _send(
        method,
        path,
        currentSession,
        body,
        query,
      );
    }

    final data = _decodeResponse(response);

    if (response.statusCode >= 400) {
      final error = data['error'];

      throw ApiException(
        response.statusCode,
        error is String && error.isNotEmpty
            ? error
            : 'error',
      );
    }

    return data;
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw ApiException(
        response.statusCode,
        'invalid_response',
      );
    } on FormatException {
      throw ApiException(
        response.statusCode,
        'invalid_response',
      );
    }
  }

  Future<http.Response> _send(
    String method,
    String path,
    Session currentSession,
    Object? body,
    Map<String, String>? query,
  ) async {
    final uri = Uri.parse(
      '${auth.baseUrl}$path',
    ).replace(queryParameters: query);

    final request = http.Request(method, uri);

    request.headers['authorization'] =
        'Bearer ${currentSession.accessToken}';

    request.headers['accept'] = 'application/json';

    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(_timeout);

      return await http.Response.fromStream(
        streamedResponse,
      ).timeout(_timeout);
    } on TimeoutException {
      throw ApiException(0, 'timeout');
    } on Exception {
      throw ApiException(0, 'network');
    }
  }
}
