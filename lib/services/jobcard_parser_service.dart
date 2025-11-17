import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../utils/jobcard_models.dart';

class JobcardParserService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  /// Parse a jobcard image and extract structured data
  Future<JobcardData?> parseJobcard(String imagePath) async {
    try {
      print('JobcardParser: Creating input image from $imagePath');
      final inputImage = InputImage.fromFilePath(imagePath);

      print('JobcardParser: Running OCR and barcode scanning...');
      // Run OCR and barcode scanning in parallel
      final results = await Future.wait([
        _textRecognizer.processImage(inputImage),
        _barcodeScanner.processImage(inputImage),
      ]);

      final recognizedText = results[0] as RecognizedText;
      final barcodes = results[1] as List<Barcode>;

      print('JobcardParser: OCR text length: ${recognizedText.text.length}');
      print('JobcardParser: Barcodes found: ${barcodes.length}');

      // Return partial data even if text is minimal
      if (recognizedText.text.isEmpty && barcodes.isEmpty) {
        print('JobcardParser: No text or barcodes found');
        return null;
      }

      // Extract data from OCR text
      print('JobcardParser: Extracting data...');
      final jobcardData = _extractJobcardData(
        recognizedText,
        barcodes,
      );

      print('JobcardParser: Extraction complete');
      return jobcardData;
    } catch (e) {
      print('JobcardParser ERROR: $e');
      return null;
    }
  }

  JobcardData _extractJobcardData(
    RecognizedText recognizedText,
    List<Barcode> barcodes,
  ) {
    final fullText = recognizedText.text;
    final lines = fullText.split('\n');
    final verificationNeeded = <VerificationIssue>[];

    print('JobcardParser: Full text (${fullText.length} chars):');
    print(fullText.substring(0, fullText.length > 200 ? 200 : fullText.length));
    print('JobcardParser: Lines: ${lines.length}');

    // Extract barcode
    String? barcodeValue;
    double barcodeConfidence = 0.0;
    if (barcodes.isNotEmpty) {
      barcodeValue = barcodes.first.displayValue;
      barcodeConfidence = 1.0;
      print('JobcardParser: Barcode found: $barcodeValue');
    }

    // Extract works order number (from barcode or text)
    final worksOrderNo = _extractWorksOrderNo(lines, barcodeValue);
    if (worksOrderNo.confidence < 0.6) {
      verificationNeeded.add(VerificationIssue(
        field: 'worksOrderNo',
        reason: 'Low confidence: ${worksOrderNo.confidence.toStringAsFixed(2)}',
      ));
    }

    // Extract FG Code
    final fgCode = _extractFgCode(lines);
    if (fgCode.confidence < 0.6) {
      verificationNeeded.add(VerificationIssue(
        field: 'fgCode',
        reason: 'Low confidence: ${fgCode.confidence.toStringAsFixed(2)}',
      ));
    }

    // Extract date started
    final dateStarted = _extractDateStarted(lines);
    if (dateStarted.confidence < 0.6) {
      verificationNeeded.add(VerificationIssue(
        field: 'dateStarted',
        reason: 'Low confidence: ${dateStarted.confidence.toStringAsFixed(2)}',
      ));
    }

    // Extract numeric fields
    final quantityToManufacture = _extractQuantityToManufacture(lines);
    final dailyOutput = _extractDailyOutput(lines);
    final cycleTimeSeconds = _extractCycleTime(lines);
    final cycleWeightGrams = _extractCycleWeight(lines);
    final cavity = _extractCavity(lines);

    // Extract raw materials table
    final rawMaterials = _extractRawMaterials(lines);

    // Extract counters
    final counters = _extractCounters(lines);

    return JobcardData(
      worksOrderNo: worksOrderNo,
      barcode: ConfidenceValue(
        value: barcodeValue,
        confidence: barcodeConfidence,
      ),
      fgCode: fgCode,
      dateStarted: dateStarted,
      quantityToManufacture: quantityToManufacture,
      dailyOutput: dailyOutput,
      cycleTimeSeconds: cycleTimeSeconds,
      cycleWeightGrams: cycleWeightGrams,
      cavity: cavity,
      rawMaterials: rawMaterials,
      counters: counters,
      rawOcrText: ConfidenceValue(
        value: fullText,
        confidence: 1.0,
      ),
      verificationNeeded: verificationNeeded,
      timestamp: ConfidenceValue(
        value: DateTime.now().toIso8601String(),
        confidence: 1.0,
      ),
    );
  }

  ConfidenceValue<String> _extractWorksOrderNo(
    List<String> lines,
    String? barcodeValue,
  ) {
    // If barcode exists, use it as authoritative
    if (barcodeValue != null && barcodeValue.isNotEmpty) {
      print('Using barcode as works order: $barcodeValue');
      return ConfidenceValue(value: barcodeValue, confidence: 1.0);
    }

    // Look for "Works Order No" label, then check next line for value
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Check if this line contains the label
      if (RegExp(r'works?\s*order\s*no\.?:?\s*$', caseSensitive: false).hasMatch(line)) {
        // Value is on next line
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          // Extract alphanumeric code (e.g., JC031351)
          final match = RegExp(r'^([A-Z]{2}\d+)', caseSensitive: false).firstMatch(nextLine);
          if (match != null) {
            final value = match.group(1)!;
            print('Found works order on next line: $value');
            return ConfidenceValue(value: value, confidence: 0.9);
          }
        }
      }
      
      // Also try same-line patterns
      final sameLinePatterns = [
        RegExp(r'works?\s*order\s*no\.?\s*:?\s*([A-Z]{2}\d+)', caseSensitive: false),
        RegExp(r'order\s*no\.?\s*:?\s*([A-Z]{2}\d+)', caseSensitive: false),
        RegExp(r'wo\s*:?\s*([A-Z]{2}\d+)', caseSensitive: false),
      ];
      
      for (final pattern in sameLinePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null && match.group(1) != null) {
          final value = match.group(1)!.trim();
          print('Found works order same line: $value');
          return ConfidenceValue(value: value, confidence: 0.85);
        }
      }
    }

    // Fallback: Look for JC followed by digits anywhere
    for (final line in lines) {
      final match = RegExp(r'\b(JC\d{6})\b', caseSensitive: false).firstMatch(line);
      if (match != null) {
        final value = match.group(1)!;
        print('Found works order pattern: $value');
        return ConfidenceValue(value: value, confidence: 0.7);
      }
    }

    print('No works order found');
    return ConfidenceValue(value: null, confidence: 0.0);
  }

  ConfidenceValue<String> _extractFgCode(List<String> lines) {
    // Look for "FG Code:" label, then check next line for value
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Check if this line contains the label
      if (RegExp(r'fg\s*code\s*:?\s*$', caseSensitive: false).hasMatch(line)) {
        // Value is on next line
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          // Extract code with dashes and slashes (e.g., CMP-DR-CB50/2-CBL)
          final match = RegExp(r'^([A-Z]{2,}[-/\w]+)', caseSensitive: false).firstMatch(nextLine);
          if (match != null) {
            final value = match.group(1)!;
            print('Found FG code on next line: $value');
            return ConfidenceValue(value: value, confidence: 0.9);
          }
        }
      }
      
      // Also try same-line patterns
      final sameLinePatterns = [
        RegExp(r'fg\s*code\s*:?\s*([A-Z]{2,}[-/\w]+)', caseSensitive: false),
        RegExp(r'finished\s*goods?\s*code\s*:?\s*([A-Z]{2,}[-/\w]+)', caseSensitive: false),
        RegExp(r'product\s*code\s*:?\s*([A-Z]{2,}[-/\w]+)', caseSensitive: false),
      ];
      
      for (final pattern in sameLinePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null && match.group(1) != null) {
          final value = match.group(1)!.trim();
          print('Found FG code same line: $value');
          return ConfidenceValue(value: value, confidence: 0.85);
        }
      }
    }

    // Fallback: Look for codes with pattern XXX-XX-XXXX anywhere
    for (final line in lines) {
      final match = RegExp(r'\b([A-Z]{2,}[-/][A-Z]{2,}[-/][\w/-]+)\b', caseSensitive: false).firstMatch(line);
      if (match != null) {
        final value = match.group(1)!;
        print('Found FG code pattern: $value');
        return ConfidenceValue(value: value, confidence: 0.7);
      }
    }

    print('No FG code found');
    return ConfidenceValue(value: null, confidence: 0.0);
  }

  ConfidenceValue<String> _extractDateStarted(List<String> lines) {
    final datePattern = RegExp(
      r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})',
    );

    // Look for "Date Started:" label, then check next line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (RegExp(r'date\s*started\s*:?\s*$', caseSensitive: false).hasMatch(line)) {
        // Value is on next line
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          final match = datePattern.firstMatch(nextLine);
          if (match != null) {
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            var year = int.parse(match.group(3)!);
            if (year < 100) year += 2000;

            final isoDate = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            print('Found date started on next line: $isoDate');
            return ConfidenceValue(value: isoDate, confidence: 0.9);
          }
        }
      }
      
      // Also try same-line pattern
      if (RegExp(r'date\s*started\s*:?', caseSensitive: false).hasMatch(line)) {
        final match = datePattern.firstMatch(line);
        if (match != null) {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          var year = int.parse(match.group(3)!);
          if (year < 100) year += 2000;

          final isoDate = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          print('Found date started same line: $isoDate');
          return ConfidenceValue(value: isoDate, confidence: 0.85);
        }
      }
    }

    // Fallback: Look for "Opened" status with date
    for (final line in lines) {
      if (line.contains('Opened')) {
        final match = datePattern.firstMatch(line);
        if (match != null) {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          var year = int.parse(match.group(3)!);
          if (year < 100) year += 2000;

          final isoDate = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          print('Found date from Opened status: $isoDate');
          return ConfidenceValue(value: isoDate, confidence: 0.7);
        }
      }
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  ConfidenceValue<int> _extractQuantityToManufacture(List<String> lines) {
    // Look for "Quantity to Manufacture:" label, then check next line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (RegExp(r'quantity\s*to\s*manufacture\s*:?\s*$', caseSensitive: false).hasMatch(line)) {
        // Value is on next line
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          // Extract number with commas and decimals (e.g., 3,000.00)
          final match = RegExp(r'^([\d,]+\.?\d*)').firstMatch(nextLine);
          if (match != null) {
            final valueStr = match.group(1)!.replaceAll(',', '');
            final value = double.tryParse(valueStr)?.toInt();
            if (value != null) {
              print('Found quantity on next line: $value');
              return ConfidenceValue(value: value, confidence: 0.9);
            }
          }
        }
      }
    }
    
    // Fallback to same-line patterns
    return _extractNumericField(
      lines,
      [
        RegExp(r'quantity\s*to\s*manufacture\s*:?\s*([\d,]+\.?\d*)',
            caseSensitive: false),
        RegExp(r'qty\s*to\s*mfg\s*:?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'target\s*qty\s*:?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    );
  }

  ConfidenceValue<int> _extractDailyOutput(List<String> lines) {
    // Look for "Daily Output (Units):" label, then check next line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (RegExp(r'daily\s*output.*:?\s*$', caseSensitive: false).hasMatch(line)) {
        // Value is on next line
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          // Extract number with commas and decimals (e.g., 1016.00)
          final match = RegExp(r'^([\d,]+\.?\d*)').firstMatch(nextLine);
          if (match != null) {
            final valueStr = match.group(1)!.replaceAll(',', '');
            final value = double.tryParse(valueStr)?.toInt();
            if (value != null) {
              print('Found daily output on next line: $value');
              return ConfidenceValue(value: value, confidence: 0.9);
            }
          }
        }
      }
    }
    
    // Fallback to same-line patterns
    return _extractNumericField(
      lines,
      [
        RegExp(r'daily\s*output\s*:?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'daily\s*target\s*:?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    );
  }

  ConfidenceValue<int> _extractCycleTime(List<String> lines) {
    // Look for patterns like "85 seconds" or "Cycle Time: 85"
    final patterns = [
      RegExp(r'cycle\s*time\s*:?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'([\d,]+)\s*seconds?', caseSensitive: false),
      RegExp(r'cycle\s*:?\s*([\d,]+)\s*s', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null && match.group(1) != null) {
          final valueStr = match.group(1)!.replaceAll(',', '').replaceAll(' ', '');
          final value = int.tryParse(valueStr);
          if (value != null && value > 0 && value < 1000) {
            print('Extracted cycle time: $value from line: $line');
            return ConfidenceValue(value: value, confidence: 0.8);
          }
        }
      }
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  ConfidenceValue<double> _extractCycleWeight(List<String> lines) {
    // Look for patterns like "1767 gram" or "Cycle Weight: 1767"
    final patterns = [
      RegExp(r'cycle\s*weight\s*:?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'([\d,]+\.?\d*)\s*grams?', caseSensitive: false),
      RegExp(r'weight\s*:?\s*([\d,]+\.?\d*)\s*g', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null && match.group(1) != null) {
          final valueStr = match.group(1)!.replaceAll(',', '');
          final value = double.tryParse(valueStr);
          if (value != null && value > 0 && value < 100000) {
            print('Extracted cycle weight: $value from line: $line');
            return ConfidenceValue(value: value, confidence: 0.8);
          }
        }
      }
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  ConfidenceValue<int> _extractCavity(List<String> lines) {
    return _extractNumericField(
      lines,
      [
        RegExp(r'cavity\s*:?\s*([\d,]+)', caseSensitive: false),
        RegExp(r'cavities\s*:?\s*([\d,]+)', caseSensitive: false),
      ],
    );
  }

  ConfidenceValue<int> _extractNumericField(
    List<String> lines,
    List<RegExp> patterns,
  ) {
    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null && match.group(1) != null) {
          final valueStr =
              match.group(1)!.replaceAll(',', '').replaceAll(' ', '');
          // Handle decimals by parsing as double then converting to int
          final doubleValue = double.tryParse(valueStr);
          if (doubleValue != null) {
            final value = doubleValue.toInt();
            print('Extracted numeric value: $value from line: $line');
            return ConfidenceValue(value: value, confidence: 0.75);
          }
        }
      }

      // Try to find any number in lines containing the keywords
      for (final pattern in patterns) {
        if (pattern.hasMatch(line)) {
          // Found the label, now look for any number in this line
          final numberMatch = RegExp(r'([\d,]+\.?\d*)').firstMatch(line);
          if (numberMatch != null) {
            final valueStr =
                numberMatch.group(1)!.replaceAll(',', '').replaceAll(' ', '');
            final doubleValue = double.tryParse(valueStr);
            if (doubleValue != null) {
              final value = doubleValue.toInt();
              print(
                  'Extracted numeric value (fallback): $value from line: $line');
              return ConfidenceValue(value: value, confidence: 0.6);
            }
          }
        }
      }
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  List<RawMaterialEntry> _extractRawMaterials(List<String> lines) {
    final materials = <RawMaterialEntry>[];

    // Find the raw materials table section
    int tableStartIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('raw material') ||
          lines[i].toLowerCase().contains('materials')) {
        tableStartIndex = i + 1;
        break;
      }
    }

    if (tableStartIndex == -1) return materials;

    // Parse table rows (simplified - assumes space-separated columns)
    for (int i = tableStartIndex;
        i < lines.length && i < tableStartIndex + 10;
        i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Split by multiple spaces (column separator)
      final parts = line.split(RegExp(r'\s{2,}'));
      if (parts.length >= 4) {
        materials.add(RawMaterialEntry(
          store: ConfidenceValue(
            value: parts.length > 0 ? parts[0] : null,
            confidence: 0.6,
          ),
          code: ConfidenceValue(
            value: parts.length > 1 ? parts[1] : null,
            confidence: 0.6,
          ),
          description: ConfidenceValue(
            value: parts.length > 2 ? parts[2] : null,
            confidence: 0.6,
          ),
          uoi: ConfidenceValue(
            value: parts.length > 3 ? parts[3] : null,
            confidence: 0.6,
          ),
          stdQty: ConfidenceValue(
            value: parts.length > 4 ? double.tryParse(parts[4]) : null,
            confidence: 0.6,
          ),
          dailyQty: ConfidenceValue(
            value: parts.length > 5 ? double.tryParse(parts[5]) : null,
            confidence: 0.6,
          ),
        ));
      }
    }

    return materials;
  }

  JobcardCounters _extractCounters(List<String> lines) {
    return JobcardCounters(
      dayCounter: _extractCounter(lines, ['day counter', 'day count']),
      dayActual: _extractCounter(lines, ['day actual', 'day act']),
      dayScrap: _extractCounter(lines, ['day scrap', 'day reject']),
      nightCounter: _extractCounter(lines, ['night counter', 'night count']),
      nightActual: _extractCounter(lines, ['night actual', 'night act']),
      nightScrap: _extractCounter(lines, ['night scrap', 'night reject']),
    );
  }

  ConfidenceValue<int> _extractCounter(
    List<String> lines,
    List<String> labels,
  ) {
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      for (final label in labels) {
        if (lowerLine.contains(label)) {
          final match = RegExp(r'(\d+)').firstMatch(line);
          if (match != null) {
            final value = int.tryParse(match.group(1)!);
            if (value != null) {
              return ConfidenceValue(value: value, confidence: 0.7);
            }
          }
        }
      }
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
  }
}
