import 'dart:ui';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class AutoTranslate {
  static late OnDeviceTranslator _translator;

  static Future<void> init() async {
    final deviceLanguage = window.locale.languageCode;

    _translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: _mapLanguage(deviceLanguage),
    );
  }

  static Future<String> translateText(String input) async {
    try {
      return await _translator.translateText(input);
    } catch (_) {
      return input;
    }
  }

  static TranslateLanguage _mapLanguage(String code) {
    return TranslateLanguage.values.firstWhere(
          (e) => e.bcpCode == code,
      orElse: () => TranslateLanguage.english,
    );
  }

  static Future<void> close() async {
    await _translator.close();
  }
}
