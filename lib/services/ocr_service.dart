import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Process image and extract text
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to extract text: $e');
    }
  }

  // Extract text with block information (for advanced parsing)
  Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return recognizedText.blocks;
    } catch (e) {
      throw Exception('Failed to extract text blocks: $e');
    }
  }

  // Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
