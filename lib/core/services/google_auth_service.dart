import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) => GoogleAuthService());

class GoogleAuthService {
  static const String _clientId = "YOUR_CLIENT_ID_HERE";
  static const String _clientSecret="REMOVED_SECRET";
  static final List<String> _scopes = [drive.DriveApi.driveFileScope];

  AuthClient? _cachedClient;

  Future<File> _getCredentialsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'EnterpriseERP'));
    if (!await folder.exists()) await folder.create(recursive: true);
    return File(p.join(folder.path, 'google_session.json'));
  }

  
  Future<AuthClient> signInWithGoogle() async {
    final id = ClientId(_clientId, _clientSecret);

    final client = await clientViaUserConsent(id, _scopes, (url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('تعذر فتح المتصفح لتسجيل الدخول');
      }
    });

    _cachedClient = client;
    await _saveCredentials(client.credentials);
    return client;
  }

  
  Future<AuthClient?> getActiveClient() async {
    if (_cachedClient != null) return _cachedClient;

    final file = await _getCredentialsFile();
    if (!await file.exists()) return null;

    try {
      final data = jsonDecode(await file.readAsString());
      final credentials = AccessCredentials(
        AccessToken(
          data['accessToken']['type'],
          data['accessToken']['data'],
          DateTime.parse(data['accessToken']['expiry']),
        ),
        data['refreshToken'],
        List<String>.from(data['scopes']),
      );

      final id = ClientId(_clientId, _clientSecret);
      _cachedClient = autoRefreshingClient(id, credentials, http.Client());
      return _cachedClient;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCredentials(AccessCredentials creds) async {
    final file = await _getCredentialsFile();
    final map = {
      'accessToken': {
        'type': creds.accessToken.type,
        'data': creds.accessToken.data,
        'expiry': creds.accessToken.expiry.toIso8601String(),
      },
      'refreshToken': creds.refreshToken,
      'scopes': creds.scopes,
    };
    await file.writeAsString(jsonEncode(map));
  }

  Future<void> signOut() async {
    _cachedClient?.close();
    _cachedClient = null;
    final file = await _getCredentialsFile();
    if (await file.exists()) await file.delete();
  }
}