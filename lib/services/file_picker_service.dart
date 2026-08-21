import 'package:flutter/services.dart';

class FilePickerService {
  static const _channel = MethodChannel('com.worksapp.works_app/file_picker');

  static Future<String?> pickJsonFile() async {
    try {
      final content = await _channel.invokeMethod<String>('pickJsonFile');
      return content;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'خطأ في اختيار الملف');
    }
  }
}
