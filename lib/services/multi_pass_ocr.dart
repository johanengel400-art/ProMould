import 'dart:convert';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import '../utils/jobcard_models.dart';

/// Multi-pass OCR with ensemble voting for improved accuracy
class MultiPassOCR {
  final TextRecognizer _mlKitRecognizer = TextRecognizer();
  final String? _cloudVisionApiKey;

  MultiPassOCR({String? cloudVisionApiKey})
      : _cloudVisionApiKey = cloudVisionApiKey;

  /// Run multiple OCR engines and merge results
  Future<OCRResult> processWithEnsemble(
    String imagePath, {
    bool useCloud = false,
  }) async {
    final results = <OCRResult>[];

    // Always run ML Kit (on-device, fast)
    final mlKitResult = await _runMLKit(imagePath);
    results.add(mlKitResult);

    // Run cloud OCR if confidence is low or explicitly requested
    if (useCloud &&
        _cloudVisionApiKey != null &&
        mlKitResult.confidence < 0.7) {
      final cloudResult = await _runCloudVision(imagePath);
      if (cloudResult != null) {
        results.add(cloudResult);
      }
    }

    // Merge results using ensemble voting
    return _mergeResults(results);
  }

  /// Run Google ML Kit OCR
  Future<OCRResult> _runMLKit(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _mlKitRecognizer.processImage(inputImage);

      return OCRResult(
        text: recognizedText.text,
        recognizedText: recognizedText,
        confidence: _calculateAverageConfidence(recognizedText),
        engine: 'ML Kit',
      );
    } catch (e) {
      return OCRResult(
        text: '',
        recognizedText: null,
        confidence: 0.0,
        engine: 'ML Kit',
        error: e.toString(),
      );
    }
  }

  /// Run Google Cloud Vision API
  Future<OCRResult?> _runCloudVision(String imagePath) async {
    if (_cloudVisionApiKey == null) return null;

    try {
      // Read image as base64
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Call Cloud Vision API
      final response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=$_cloudVisionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'TEXT_DETECTION'},
                {'type': 'DOCUMENT_TEXT_DETECTION'},
              ],
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final annotations = data['responses'][0]['textAnnotations'];

        if (annotations != null && annotations.isNotEmpty) {
          final fullText = annotations[0]['description'] as String;
          return OCRResult(
            text: fullText,
            recognizedText: null,
            confidence: 0.9, // Cloud Vision typically has high confidence
            engine: 'Cloud Vision',
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate average confidence from ML Kit result
  double _calculateAverageConfidence(RecognizedText recognizedText) {
    double totalConfidence = 0;
    int count = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          if (element.confidence != null) {
            totalConfidence += element.confidence!;
            count++;
          }
        }
      }
    }

    return count > 0 ? totalConfidence / count : 0.5;
  }

  /// Merge multiple OCR results using ensemble voting
  OCRResult _mergeResults(List<OCRResult> results) {
    if (results.isEmpty) {
      return OCRResult(
        text: '',
        recognizedText: null,
        confidence: 0.0,
        engine: 'None',
      );
    }

    if (results.length == 1) {
      return results.first;
    }

    // Use result with highest confidence
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    final bestResult = results.first;

    // For critical fields, use voting
    final mergedText = _voteOnText(results);

    return OCRResult(
      text: mergedText,
      recognizedText: bestResult.recognizedText,
      confidence: bestResult.confidence,
      engine: results.map((r) => r.engine).join(' + '),
      alternativeResults: results.skip(1).toList(),
    );
  }

  /// Vote on text from multiple OCR results
  String _voteOnText(List<OCRResult> results) {
    // Simple voting: use most common text
    final textCounts = <String, int>{};

    for (final result in results) {
      final text = result.text.trim();
      textCounts[text] = (textCounts[text] ?? 0) + 1;
    }

    // Return most common text
    String mostCommon = '';
    int maxCount = 0;

    textCounts.forEach((text, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = text;
      }
    });

    return mostCommon;
  }

  /// Extract field with voting from multiple results
  ConfidenceValue<String> extractFieldWithVoting(
    List<OCRResult> results,
    String Function(String text) extractor,
  ) {
    final values = <String, int>{};
    double totalConfidence = 0;

    for (final result in results) {
      final value = extractor(result.text);
      if (value.isNotEmpty) {
        values[value] = (values[value] ?? 0) + 1;
        totalConfidence += result.confidence;
      }
    }

    if (values.isEmpty) {
      return ConfidenceValue(value: null, confidence: 0.0);
    }

    // Get most voted value
    String mostVoted = '';
    int maxVotes = 0;

    values.forEach((value, votes) {
      if (votes > maxVotes) {
        maxVotes = votes;
        mostVoted = value;
      }
    });

    // Calculate confidence based on agreement
    final agreementRatio = maxVotes / results.length;
    final avgConfidence = totalConfidence / results.length;
    final finalConfidence = agreementRatio * avgConfidence;

    return ConfidenceValue(
      value: mostVoted,
      confidence: finalConfidence,
    );
  }

  void dispose() {
    _mlKitRecognizer.close();
  }
}

class OCRResult {
  final String text;
  final RecognizedText? recognizedText;
  final double confidence;
  final String engine;
  final String? error;
  final List<OCRResult>? alternativeResults;

  OCRResult({
    required this.text,
    required this.recognizedText,
    required this.confidence,
    required this.engine,
    this.error,
    this.alternativeResults,
  });
}
