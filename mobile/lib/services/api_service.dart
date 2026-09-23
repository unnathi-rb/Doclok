import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'secure_storage_service.dart';
import '../models/document_item.dart';
import '../models/folder_item.dart';

/// Thrown for any non-2xx response. `message` is the backend's `detail`
/// field (FastAPI's HTTPException format) when available.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await SecureStorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Decodes a response, throwing ApiException with the backend's detail
  /// message on any error status.
  static dynamic _decode(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final detail = body is Map && body['detail'] != null
        ? body['detail'].toString()
        : 'Something went wrong (${res.statusCode}).';
    throw ApiException(res.statusCode, detail);
  }

  // ── Signup ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String pin,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.signup),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'pin': pin,
      }),
    );
    return _decode(res);
  }

  // ── Login step 1: password ─────────────────────────────────────────
  /// Returns {login_session_token, message}
  static Future<Map<String, dynamic>> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.loginPassword),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decode(res);
  }

  // ── Login step 2: OTP ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp({
    required String loginSessionToken,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.verifyOtp),
      headers: _jsonHeaders,
      body: jsonEncode({
        'login_session_token': loginSessionToken,
        'otp': otp,
      }),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> resendOtp({
    required String loginSessionToken,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.resendOtp),
      headers: _jsonHeaders,
      body: jsonEncode({'login_session_token': loginSessionToken}),
    );
    return _decode(res);
  }

  // ── Login step 3: PIN → access_token ─────────────────────────────
  static Future<Map<String, dynamic>> verifyPin({
    required String loginSessionToken,
    required String pin,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.verifyPin),
      headers: _jsonHeaders,
      body: jsonEncode({
        'login_session_token': loginSessionToken,
        'pin': pin,
      }),
    );
    final data = _decode(res);
    if (data['access_token'] != null) {
      await SecureStorageService.saveAccessToken(data['access_token']);
    }
    return data;
  }

  // ── Profile (home screen) ────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse(ApiConfig.profile),
      headers: await _authHeaders(),
    );
    return _decode(res);
  }

  static Future<void> logout() async {
    await SecureStorageService.clearAccessToken();
  }

  // ── Documents ─────────────────────────────────────────────────────

  /// Uploads a file. Backend re-checks PIN + password server-side even
  /// though the user already unlocked the app — matches your Phase 1
  /// per-action security model.
  static Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String pin,
    required String password,
    String? folder,
  }) async {
    final token = await SecureStorageService.getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/documents/upload'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['pin'] = pin;
    request.fields['password'] = password;
    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  static Future<List<DocumentItem>> listDocuments() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/documents'),
      headers: await _authHeaders(),
    );
    final data = _decode(res) as List;
    return data.map((e) => DocumentItem.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> verifyDocumentPin({
    required String docId,
    required String pin,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/documents/$docId/verify-pin'),
      headers: await _authHeaders(),
      body: jsonEncode({'pin': pin}),
    );
    return _decode(res);
  }

  /// Returns {filename, file_base64, integrity}. Throws ApiException with
  /// statusCode 409 specifically when the tamper check fails.
  static Future<Map<String, dynamic>> decryptDocument({
    required String docId,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/documents/$docId/decrypt'),
      headers: await _authHeaders(),
      body: jsonEncode({'password': password}),
    );
    return _decode(res);
  }

  static Future<void> deleteDocument(String docId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/documents/$docId'),
      headers: await _authHeaders(),
    );
    _decode(res);
  }

  // ── PIN reset mid-login (forgot PIN, after password+OTP verified) ──
  /// Backend takes these as query params, not a JSON body. Returns an
  /// access_token directly — this skips the normal PIN-verify step.
  static Future<Map<String, dynamic>> forgotPin({
    required String loginSessionToken,
    required String newPin,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/forgot-pin').replace(
      queryParameters: {
        'login_session_token': loginSessionToken,
        'new_pin': newPin,
      },
    );
    final res = await http.post(uri);
    final data = _decode(res);
    if (data['access_token'] != null) {
      await SecureStorageService.saveAccessToken(data['access_token']);
    }
    return data;
  }

  // ── Forgot password (via recovery key, before login) ────────────────
  /// Returns {password} in plaintext — that's the backend's recovery
  /// design, not something the client controls.
  static Future<Map<String, dynamic>> recoverPassword({
    required String email,
    required String recoveryKey,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/recover-password'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'recovery_key': recoveryKey}),
    );
    return _decode(res);
  }

  // ── Change PIN while already logged in (Profile/Security) ──────────
  static Future<Map<String, dynamic>> updatePin({
    required String currentPin,
    required String newPin,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/security/update-pin'),
      headers: await _authHeaders(),
      body: jsonEncode({'current_pin': currentPin, 'new_pin': newPin}),
    );
    return _decode(res);
  }

  // ── Folders ───────────────────────────────────────────────────────

  static Future<List<FolderItem>> listFolders() async {
    final res = await http.get(
      Uri.parse(ApiConfig.folders),
      headers: await _authHeaders(),
    );
    final data = _decode(res) as List;
    return data.map((e) => FolderItem.fromJson(e)).toList();
  }

  static Future<void> createFolder(String name) async {
    final res = await http.post(
      Uri.parse(ApiConfig.folders),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name}),
    );
    _decode(res);
  }

  static Future<void> deleteFolder(String name) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.folders}/${Uri.encodeComponent(name)}'),
      headers: await _authHeaders(),
    );
    _decode(res);
  }

  // ── Account ───────────────────────────────────────────────────────

  static Future<void> deleteAccount() async {
    final res = await http.delete(
      Uri.parse(ApiConfig.account),
      headers: await _authHeaders(),
    );
    _decode(res);
    await SecureStorageService.clearAccessToken();
  }
}
