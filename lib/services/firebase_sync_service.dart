import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:works_app/models/user_data.dart';

class FirebaseSyncService {
  static const apiKey = 'AIzaSyA7hVCo7no6VlCTSDtvz0NEB1WS5bDRau0';
  static const databaseUrl = 'https://worksv3-default-rtdb.firebaseio.com';

  String? _idToken;
  String? _uid;
  String? _email;

  bool get isSignedIn => _idToken != null;

  Future<String?> signIn(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey'),
        body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _idToken = data['idToken'];
        _uid = data['localId'];
        _email = data['email'];
        return null;
      }
      return jsonDecode(res.body)['error']['message'] ?? 'خطأ في تسجيل الدخول';
    } catch (e) {
      return 'خطأ في الاتصال: $e';
    }
  }

  void signOut() {
    _idToken = null;
    _uid = null;
    _email = null;
  }

  String? get uid => _uid;
  String? get email => _email;

  Future<void> saveToFirebase(UserData data) async {
    if (_idToken == null || _uid == null) return;
    try {
      await http.put(
        Uri.parse('$databaseUrl/users/$_uid/data.json?auth=$_idToken'),
        body: jsonEncode({
          'customers': data.customers.map((c) => c.toJson()).toList(),
          'workersByWeek': data.workersByWeek.map((k, v) => MapEntry(k, v.map((w) => w.toJson()).toList())),
          'accounting': data.accounting.toJson(),
          'partnerAccounting': data.partnerAccounting.toJson(),
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {}
  }

  Future<UserData?> loadFromFirebase() async {
    if (_idToken == null || _uid == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$databaseUrl/users/$_uid/data.json?auth=$_idToken'),
      );
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return UserData.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  Future<int?> getLastUpdated() async {
    if (_idToken == null || _uid == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$databaseUrl/users/$_uid/data/lastUpdated.json?auth=$_idToken'),
      );
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        return jsonDecode(res.body) as int;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> register(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'),
        body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _idToken = data['idToken'];
        _uid = data['localId'];
        _email = data['email'];
        return null;
      }
      return jsonDecode(res.body)['error']['message'] ?? 'خطأ في التسجيل';
    } catch (e) {
      return 'خطأ في الاتصال: $e';
    }
  }
}
