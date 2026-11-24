
import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

const _apiUrlOverride = String.fromEnvironment('API_URL');

final apiUrl = _apiUrlOverride.isNotEmpty
    ? _apiUrlOverride
    : (kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000');

class Session {
  const Session({
    required this.accessToken,
    required this.userId,
    required this.fullName,
    this.role = 'chw',
    this.healthCenterId,
    this.email,
    this.mustChange = false,
  });

  final String accessToken;
  final String userId;
  final String fullName;
  final String role;
  final String? healthCenterId;
  final String? email;
  final bool mustChange;
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PhoneCode {
  const PhoneCode(this.verificationId) : signedIn = false;

  const PhoneCode.signedIn()
      : verificationId = null,
        signedIn = true;

  final String? verificationId;
  final bool signedIn;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    http.Client? client,
    String? baseUrl,
  })  : _authOverride = auth,
        _client = client ?? http.Client(),
        baseUrl = baseUrl ?? apiUrl;

  final FirebaseAuth? _authOverride;
  final http.Client _client;
  final String baseUrl;

  static const _requestTimeout = Duration(seconds: 10);

  FirebaseAuth get _auth =>
      _authOverride ?? FirebaseAuth.instance;

  Future<Session> login(String id, String secret) {
    final identifier = id.trim();

    return identifier.contains('@')
        ? signInWithEmail(identifier, secret)
        : signInWithPin(identifier, secret);
  }

  Future<Session> signInWithPin(
    String phone,
    String pin,
  ) async {
    final response = await _post('/auth/pin', {
      'phone': normalizePhone(phone),
      'pin': pin,
    });

    if (response.statusCode == 429) {
      throw AuthException(
        'Too many attempts. Try again in 15 minutes.',
      );
    }

    if (response.statusCode != 200) {
      throw AuthException('Wrong phone number or PIN.');
    }

    final token = _responseString(
      response,
      'customToken',
    );

    return _signedIn(
      () => _auth.signInWithCustomToken(token),
    );
  }

  Future<Session> signInWithEmail(
    String email,
    String password,
  ) {
    return _signedIn(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<PhoneCode> sendPhoneCode(String phone) async {
    final completer = Completer<PhoneCode>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: normalizePhone(phone),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (completer.isCompleted) return;

          try {
            await _auth.signInWithCredential(credential);

            if (!completer.isCompleted) {
              completer.complete(
                const PhoneCode.signedIn(),
              );
            }
          } catch (error) {
            if (!completer.isCompleted) {
              completer.completeError(_friendly(error));
            }
          }
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(_friendly(error));
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) {
            completer.complete(
              PhoneCode(verificationId),
            );
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (error) {
      if (!completer.isCompleted) {
        completer.completeError(_friendly(error));
      }
    }

    return completer.future;
  }

  Future<Session> confirmPhoneCode(
    String verificationId,
    String code,
  ) {
    if (verificationId.trim().isEmpty) {
      throw AuthException(
        'Request a verification code first.',
      );
    }

    return _signedIn(
      () => _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: code.trim(),
        ),
      ),
    );
  }

  Future<Session?> restore() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    try {
      return await _session(user);
    } catch (_) {
      return null;
    }
  }

  Future<Session> refresh(Session session) async {
    final user = _auth.currentUser;

    if (user == null || user.uid != session.userId) {
      throw AuthException(
        'Your session has ended. Log in again.',
      );
    }

    try {
      return await _session(
        user,
        forceRefresh: true,
      );
    } on FirebaseAuthException {
      throw AuthException(
        'Your session has ended. Log in again.',
      );
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<void> requestReset({
    String? phone,
    String? email,
  }) async {
    final response = await _post(
      '/auth/reset/request',
      _who(phone, email),
    );

    if (response.statusCode != 200) {
      throw AuthException(
        'Could not send the request. Try again.',
      );
    }
  }

  Future<String> verifyResetCode({
    String? phone,
    String? email,
    required String code,
  }) async {
    final response = await _post(
      '/auth/reset/verify',
      {
        ..._who(phone, email),
        'code': code.trim(),
      },
    );

    if (response.statusCode != 200) {
      throw AuthException(
        'That code is incorrect or has expired. '
        'Check the SMS or request another code.',
      );
    }

    return _responseString(
      response,
      'resetToken',
    );
  }

  Future<void> completeReset(
    String resetToken, {
    String? pin,
    String? password,
  }) async {
    final response = await _post(
      '/auth/reset/complete',
      {
        'resetToken': resetToken,
        'pin': ?pin,
        'password': ?password,
      },
    );

    if (response.statusCode == 400 &&
        response.body.contains('no_email_on_account')) {
      throw AuthException(
        'This account has no email, so it has no password.',
      );
    }

    if (response.statusCode != 200) {
      throw AuthException(
        'The reset has expired or could not be completed. '
        'Please start again.',
      );
    }
  }

  Future<Session> changeOwn({
    String? pin,
    String? password,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw AuthException(
        'Your session has ended. Log in again.',
      );
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw AuthException(
        'Your session has ended. Log in again.',
      );
    }

    final response = await _post(
      '/auth/change',
      {
        'pin': ?pin,
        'password': ?password,
      },
      token: token,
    );

    if (response.statusCode != 200) {
      throw AuthException(
        'Could not save your changes. '
        'Check your connection and try again.',
      );
    }

    return _session(
      user,
      forceRefresh: true,
    );
  }

  Map<String, String> _who(
    String? phone,
    String? email,
  ) {
    if (email != null && email.trim().isNotEmpty) {
      return {'email': email.trim()};
    }

    if (phone != null && phone.trim().isNotEmpty) {
      return {'phone': normalizePhone(phone)};
    }

    throw AuthException(
      'Enter your phone number or email.',
    );
  }

  Future<http.Response> _post(
    String path,
    Map<String, Object?> body, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');

      return await _client.post(
        uri,
        headers: {
          'content-type': 'application/json',
          if (token != null)
            'authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(_requestTimeout);
    } on TimeoutException {
      throw AuthException(
        'The server took too long to respond. '
        'Please try again.',
      );
    } on Exception {
      throw AuthException(
        'Cannot reach the server. '
        'Check your connection and try again.',
      );
    }
  }

  String _responseString(
    http.Response response,
    String key,
  ) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        final value = data[key];

        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    } on FormatException {
      // The response is not valid JSON.
    }

    throw AuthException(
      'The server returned an invalid response. '
      'Please try again.',
    );
  }

  Future<Session> _signedIn(
    Future<UserCredential> Function() signIn,
  ) async {
    try {
      final credential = await signIn();
      final user = credential.user;

      if (user == null) {
        throw AuthException(
          'Sign-in failed. Please try again.',
        );
      }

      return await _session(user);
    } on FirebaseAuthException catch (error) {
      throw _friendly(error);
    }
  }

  Future<Session> _session(
    User user, {
    bool forceRefresh = false,
  }) async {
    final result = await user.getIdTokenResult(
      forceRefresh,
    );

    final token = result.token;

    if (token == null || token.isEmpty) {
      throw AuthException(
        'Could not verify your session. '
        'Please sign in again.',
      );
    }

    final claims = result.claims ?? const {};

    return Session(
      accessToken: token,
      userId: user.uid,
      fullName: user.displayName ?? '',
      role: claims['role'] as String? ?? 'chw',
      healthCenterId: claims['hc'] as String?,
      email: user.email,
      mustChange: claims['mc'] == true,
    );
  }
}

String normalizePhone(String raw) {
  final phone = raw.trim().replaceAll(
    RegExp(r'[\s\-()]'),
    '',
  );

  if (phone.startsWith('+')) {
    return phone;
  }

  if (phone.startsWith('250')) {
    return '+$phone';
  }

  if (phone.startsWith('0')) {
    return '+250${phone.substring(1)}';
  }

  return '+250$phone';
}

AuthException _friendly(Object error) {
  if (error is AuthException) {
    return error;
  }

  final code = error is FirebaseAuthException
      ? error.code
      : '';

  return AuthException(
    switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' =>
        'Wrong email or password.',

      'admin-restricted-operation' =>
        'This phone number has no HealthBridge account. '
            'Contact your administrator.',

      'operation-not-allowed' =>
        'SMS sign-in is unavailable for this number. '
            'Use your PIN or contact your administrator.',

      'user-disabled' =>
        'This account has been deactivated. '
            'Contact your administrator.',

      'invalid-phone-number' =>
        'Check the phone number and try again.',

      'invalid-verification-code' =>
        'That verification code is incorrect.',

      'session-expired' ||
      'code-expired' =>
        'The verification code has expired. '
            'Request another code.',

      'too-many-requests' ||
      'quota-exceeded' =>
        'Too many attempts. Wait a while and try again.',

      'network-request-failed' =>
        'Cannot reach the server. '
            'Check your connection and try again.',

      _ =>
        'Sign-in failed. Please try again.',
    },
  );
}
