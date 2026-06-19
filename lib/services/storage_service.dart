import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart' as intl;
import 'package:works_app/models/user_data.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  static const _key = 'appData';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveUserData(UserData data) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _writeBackupFiles(data);
    final jsonString = jsonEncode(data.toJson());
    await _prefs!.setString(_key, jsonString);
  }

  Future<void> _writeBackupFiles(UserData data) async {
    final now = DateTime.now();
    final today = intl.DateFormat('yyyy-MM-dd').format(now);
    final isoWeek = _isoWeekKey(now);

    if (data.lastDailyBackup == today && data.lastWeeklyBackup == isoWeek) return;

    final dir = await getApplicationDocumentsDirectory();

    if (data.lastDailyBackup != today) {
      final dailyFile = File('${dir.path}/works_auto_daily.json');
      await dailyFile.writeAsString(jsonEncode(data.toJson()));
      data.lastDailyBackup = today;
    }

    if (data.lastWeeklyBackup != isoWeek) {
      final weeklyFile = File('${dir.path}/works_auto_$isoWeek.json');
      await weeklyFile.writeAsString(jsonEncode(data.toJson()));
      data.lastWeeklyBackup = isoWeek;
    }

    data.lastBackupDate = today;
  }

  Future<UserData?> loadUserData() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonString = _prefs!.getString(_key);
    if (jsonString == null) return null;
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserData.fromJson(map);
  }

  Future<String> exportToJson(UserData data) async {
    final directory = await getTemporaryDirectory();
    final date = DateTime.now().toString().substring(0, 10);
    final file = File('${directory.path}/works_backup_$date.json');
    await file.writeAsString(jsonEncode(data.toJson()));
    return file.path;
  }

  UserData importFromJson(String jsonString) {
    final map = Map<String, dynamic>.from(jsonDecode(jsonString));
    return UserData.fromJson(map);
  }



  Future<void> saveFirebaseCredentials(String email, String password) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('firebase_email', email);
    await _prefs!.setString('firebase_password', password);
  }

  Future<String?> getFirebaseEmail() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString('firebase_email');
  }

  Future<String?> getFirebasePassword() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString('firebase_password');
  }

  Future<void> clearFirebaseCredentials() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove('firebase_email');
    await _prefs!.remove('firebase_password');
  }

  String _isoWeekKey(DateTime d) {
    final weekday = d.weekday;
    final daysToMonday = (weekday - 1) % 7;
    final monday = d.subtract(Duration(days: daysToMonday));
    return intl.DateFormat("yyyy-'W'ww").format(monday);
  }
}
