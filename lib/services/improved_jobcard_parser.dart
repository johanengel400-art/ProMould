import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../utils/jobcard_models.dart';
import 'log_service.dart';

/// Improved jobcard parser using spatial context and better pattern matching
class ImprovedJobcardParser {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  Future<JobcardData?> parseJobcard(String imagePath) async {
    try {
      LogService.info('ImprovedParser: Starting parse of $imagePath');
      final inputImage = InputImage.fromFilePath(imagePath);

      // Run OCR and barcode scanning in parallel
      final results = await Future.wait([
        _textRecognizer.processImage(inputImage),
        _barcodeScanner.processImage(inputImage),
      ]);

      final recognizedText = results[0] as RecognizedText;
      final barcodes = results[1] as List<Barcode>;

      LogService.info('OCR text length: ${recognizedText.text.length}');
      LogService.info('Barcodes found: ${barcodes.length}');

      if (recognizedText.text.isEmpty && barcodes.isEmpty) {
        LogService.warning('No text or barcodes detected');
        return null;
      }

      // Extract data using spatial context
      return _extractWithSpatialContext(recognizedText, barcodes);
    } catch (e) {
      LogService.error('ImprovedParser error', e);
      return null;
    }
  }

  JobcardData _extractWithSpatialContext(
    RecognizedText recognizedText,
    List<Barcode> barcodes,
  ) {
    final verificationNeeded = <VerificationIssue>[];

    // Create a map of all text elements with their positions
    final textElements = <TextElementWithPosition>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          textElements.add(TextElementWithPosition(
            text: element.text,
            boundingBox: element.boundingBox,
            confidence: element.confidence ?? 0.5,
          ));
        }
      }
    }

    LogService.debug('Total text elements: ${textElements.length}');

    // Extract barcode
    String? barcodeValue;
    if (barcodes.isNotEmpty) {
      barcodeValue = barcodes.first.displayValue;
      LogService.info('Barcode detected: $barcodeValue');
    }

    // Extract fields using spatial proximity
    final worksOrderNo = _extractFieldByLabel(
      textElements,
      ['works order no', 'works order', 'wo no', 'batch sheet'],
      barcodeValue,
    );

    final jobName = _extractFieldByLabel(
      textElements,
      ['fg code', 'product', 'description'],
      null,
    );

    final color = _extractFieldByLabel(
      textElements,
      ['colour', 'color', 'type'],
      null,
    );

    final quantityToManufacture = _extractNumericFieldByLabel(
      textElements,
      ['quantity to manufacture', 'quantity', 'qty to manufacture'],
    );

    final dailyOutput = _extractNumericFieldByLabel(
      textElements,
      ['daily output', 'daily qty'],
    );

    final cycleWeightGrams = _extractNumericFieldByLabel(
      textElements,
      ['cycle weight', 'weight'],
    );

    final targetCycleDay = _extractNumericFieldByLabel(
      textElements,
      ['target cycle day', 'cycle day'],
    );

    final targetCycleNight = _extractNumericFieldByLabel(
      textElements,
      ['target cycle night', 'traget cycle night', 'cycle night'],
    );

    // Extract production table
    final productionRows = _extractProductionTable(textElements);

    LogService.info('Extracted fields:');
    LogService.info('  Works Order: ${worksOrderNo.value}');
    LogService.info('  Job Name: ${jobName.value}');
    LogService.info('  Color: ${color.value}');
    LogService.info('  Quantity: ${quantityToManufacture.value}');
    LogService.info('  Production rows: ${productionRows.length}');

    // Convert int to double for cycleWeightGrams
    final cycleWeightDouble = cycleWeightGrams.value != null
        ? ConfidenceValue<double>(
            value: cycleWeightGrams.value!.toDouble(),
            confidence: cycleWeightGrams.confidence,
          )
        : ConfidenceValue<double>(value: null, confidence: 0.0);

    return JobcardData(
      worksOrderNo: worksOrderNo,
      jobName: jobName,
      color: color,
      quantityToManufacture: quantityToManufacture,
      dailyOutput: dailyOutput,
      cycleWeightGrams: cycleWeightDouble,
      targetCycleDay: targetCycleDay,
      targetCycleNight: targetCycleNight,
      productionRows: productionRows,
      rawMaterials: [],
      rawOcrText: ConfidenceValue(
        value: recognizedText.text,
        confidence: 1.0,
      ),
      verificationNeeded: verificationNeeded,
      timestamp: ConfidenceValue(
        value: DateTime.now().toIso8601String(),
        confidence: 1.0,
      ),
    );
  }

  /// Extract field value by finding label and getting nearby text
  ConfidenceValue<String> _extractFieldByLabel(
    List<TextElementWithPosition> elements,
    List<String> labelPatterns,
    String? fallbackValue,
  ) {
    // Find label element
    TextElementWithPosition? labelElement;
    String? matchedPattern;

    for (final pattern in labelPatterns) {
      for (final element in elements) {
        if (element.text.toLowerCase().contains(pattern.toLowerCase())) {
          labelElement = element;
          matchedPattern = pattern;
          break;
        }
      }
      if (labelElement != null) break;
    }

    if (labelElement == null) {
      LogService.debug('Label not found for patterns: $labelPatterns');
      if (fallbackValue != null) {
        return ConfidenceValue(value: fallbackValue, confidence: 1.0);
      }
      return ConfidenceValue(value: null, confidence: 0.0);
    }

    LogService.debug(
        'Found label "$matchedPattern" at position ${labelElement.boundingBox.left}, ${labelElement.boundingBox.top}');

    // Find value element (to the right or below the label)
    final valueElement = _findNearbyValue(elements, labelElement);

    if (valueElement != null) {
      final cleanValue = _cleanText(valueElement.text);
      LogService.debug(
          'Found value: $cleanValue (confidence: ${valueElement.confidence})');
      return ConfidenceValue(
        value: cleanValue,
        confidence: valueElement.confidence,
      );
    }

    if (fallbackValue != null) {
      return ConfidenceValue(value: fallbackValue, confidence: 1.0);
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  /// Extract numeric field by label
  ConfidenceValue<int> _extractNumericFieldByLabel(
    List<TextElementWithPosition> elements,
    List<String> labelPatterns,
  ) {
    final textValue = _extractFieldByLabel(elements, labelPatterns, null);

    if (textValue.value == null) {
      return ConfidenceValue(value: null, confidence: 0.0);
    }

    // Extract number from text
    final numberMatch = RegExp(r'[\d,]+\.?\d*').firstMatch(textValue.value!);
    if (numberMatch != null) {
      final numberStr = numberMatch.group(0)!.replaceAll(',', '');
      final number = int.tryParse(numberStr.split('.').first);
      if (number != null) {
        return ConfidenceValue(value: number, confidence: textValue.confidence);
      }
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  /// Find value element near a label (to the right or below)
  /// Collects multiple nearby elements and combines them
  TextElementWithPosition? _findNearbyValue(
    List<TextElementWithPosition> elements,
    TextElementWithPosition label,
  ) {
    const maxDistance = 300.0; // Increased from 200
    const maxVerticalOffset = 80.0; // Increased from 50

    // Collect all nearby elements
    final nearbyElements = <TextElementWithPosition>[];

    for (final element in elements) {
      if (element == label) continue;
      if (element.text.trim().isEmpty) continue;

      final dx = element.boundingBox.left - label.boundingBox.right;
      final dy = element.boundingBox.top - label.boundingBox.top;

      // Check if element is to the right (same line or close)
      if (dx > -50 && dx < maxDistance && dy.abs() < maxVerticalOffset) {
        nearbyElements.add(element);
      }
      // Or below (next line)
      else if (dy > 0 && dy < maxDistance && dx.abs() < maxDistance) {
        nearbyElements.add(element);
      }
    }

    if (nearbyElements.isEmpty) {
      return null;
    }

    // Sort by position (left to right, top to bottom)
    nearbyElements.sort((a, b) {
      final dyDiff = a.boundingBox.top - b.boundingBox.top;
      if (dyDiff.abs() < 20) {
        // Same line, sort by x
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return dyDiff.compareTo(0);
    });

    // Combine text from nearby elements
    final combinedText = nearbyElements.map((e) => e.text).join(' ');
    final avgConfidence = nearbyElements.fold<double>(
          0.0,
          (sum, e) => sum + e.confidence,
        ) /
        nearbyElements.length;

    // Return combined element
    return TextElementWithPosition(
      text: combinedText,
      boundingBox: nearbyElements.first.boundingBox,
      confidence: avgConfidence,
    );
  }

  /// Extract production table using spatial alignment
  List<ProductionTableRow> _extractProductionTable(
    List<TextElementWithPosition> elements,
  ) {
    final rows = <ProductionTableRow>[];

    // Find table header
    final headerKeywords = [
      'day-counter',
      'day-actual',
      'night-counter',
      'night-actual'
    ];
    final headerElements = <TextElementWithPosition>[];

    for (final keyword in headerKeywords) {
      for (final element in elements) {
        if (element.text.toLowerCase().contains(keyword.toLowerCase())) {
          headerElements.add(element);
          break;
        }
      }
    }

    if (headerElements.isEmpty) {
      LogService.warning('Production table header not found');
      return rows;
    }

    LogService.info('Found ${headerElements.length} table header elements');

    // Find data rows (elements below the header)
    final headerBottom = headerElements
        .map((e) => e.boundingBox.bottom)
        .reduce((a, b) => a > b ? a : b);

    final dataElements =
        elements.where((e) => e.boundingBox.top > headerBottom).toList();

    // Group elements by row (similar Y position)
    final rowGroups = <List<TextElementWithPosition>>[];
    dataElements.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    List<TextElementWithPosition> currentRow = [];
    double? lastY;

    for (final element in dataElements) {
      if (lastY == null || (element.boundingBox.top - lastY).abs() < 20) {
        currentRow.add(element);
        lastY = element.boundingBox.top;
      } else {
        if (currentRow.isNotEmpty) {
          rowGroups.add(List.from(currentRow));
        }
        currentRow = [element];
        lastY = element.boundingBox.top;
      }
    }
    if (currentRow.isNotEmpty) {
      rowGroups.add(currentRow);
    }

    LogService.info('Found ${rowGroups.length} potential data rows');

    // Parse each row
    for (final rowElements in rowGroups) {
      if (rowElements.length < 4) continue; // Need at least 4 values

      // Sort elements by X position
      rowElements
          .sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

      // Extract numbers
      final numbers = <int>[];
      for (final element in rowElements) {
        final match = RegExp(r'\d+').firstMatch(element.text);
        if (match != null) {
          final num = int.tryParse(match.group(0)!);
          if (num != null) numbers.add(num);
        }
      }

      if (numbers.isNotEmpty && numbers.length >= 4) {
        // Assume order: dayCounterStart, dayCounterEnd, dayActual, dayScrap, nightCounterStart, nightCounterEnd, nightActual, nightScrap
        rows.add(ProductionTableRow(
          date: ConfidenceValue(value: null, confidence: 0.0),
          dayCounterStart: ConfidenceValue(
              value: numbers.length > 0 ? numbers[0] : null, confidence: 0.7),
          dayCounterEnd: ConfidenceValue(
              value: numbers.length > 1 ? numbers[1] : null, confidence: 0.7),
          dayActual: ConfidenceValue(
              value: numbers.length > 2 ? numbers[2] : null, confidence: 0.7),
          dayScrap: ConfidenceValue(
              value: numbers.length > 3 ? numbers[3] : null, confidence: 0.7),
          nightCounterStart: ConfidenceValue(
              value: numbers.length > 4 ? numbers[4] : null, confidence: 0.7),
          nightCounterEnd: ConfidenceValue(
              value: numbers.length > 5 ? numbers[5] : null, confidence: 0.7),
          nightActual: ConfidenceValue(
              value: numbers.length > 6 ? numbers[6] : null, confidence: 0.7),
          nightScrap: ConfidenceValue(
              value: numbers.length > 7 ? numbers[7] : null, confidence: 0.7),
        ));
      }
    }

    LogService.info('Extracted ${rows.length} production rows');
    return rows;
  }

  String _cleanText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(':', '')
        .trim();
  }

  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
  }
}

/// Helper class to store text element with position
class TextElementWithPosition {
  final String text;
  final Rect boundingBox;
  final double confidence;

  TextElementWithPosition({
    required this.text,
    required this.boundingBox,
    required this.confidence,
  });
}
