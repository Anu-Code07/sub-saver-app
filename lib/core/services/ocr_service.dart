import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeFromFile(String path) async {
    final input = InputImage.fromFile(File(path));
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  Future<void> dispose() => _recognizer.close();
}
