import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../utils/jobcard_models.dart';
import '../utils/advanced_preprocessing.dart';
import '../utils/spatial_parser.dart';
import 'multi_pass_ocr.dart';
import 'template_manager.dart';
import 'validation_service.dart';
import 'learning_system.dart';

/// Enhanced jobcard parser with all improvements integrated
class EnhancedJobcardParser {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final MultiPassOCR _multiPassOCR;
  final TemplateManager _templateManager = TemplateManager();
  final ValidationService _validator = ValidationService();
  final LearningSystem _learningSystem = LearningSystem();

  EnhancedJobcardParser({String? cloudVisionApiKey})
      : _multiPassOCR = MultiPassOCR(cloudVisionApiKey: cloudVisionApiKey);

  /// Parse jobcard with full enhancement pipeline
  Future<EnhancedJobcardResult> parseJobcard(
    String imagePath, {
    bool useCloudFallback = false,
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Preprocessing image...');

      // Step 1: Advanced preprocessing
      final preprocessResult =
          await AdvancedPreprocessing.fullPipeline(imagePath);

      onProgress?.call('Running OCR...');

      // Step 2: Multi-pass OCR
      final ocrResult = await _multiPassOCR.processWithEnsemble(
        preprocessResult.processedPath,
        useCloud: useCloudFallback,
      );

      if (ocrResult.recognizedText == null) {
        return EnhancedJobcardResult(
          jobcardData: null,
          quality: preprocessResult.quality,
          processingSteps: preprocessResult.steps,
          error: 'OCR failed',
        );
      }

      onProgress?.call('Detecting template...');

      // Step 3: Template detection
      final template = await _templateManager.detectTemplate(
        ocrResult.recognizedText!,
      );

      onProgress?.call('Extracting data...');

      // Step 4: Barcode scanning
      final inputImage =
          InputImage.fromFilePath(preprocessResult.processedPath);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      // Step 5: Extract data using spatial parsing
      final jobcardData = await _extractWithSpatialContext(
        ocrResult.recognizedText!,
        barcodes,
        template,
      );

      onProgress?.call('Validating data...');

      // Step 6: Validation and auto-correction
      final validatedData = await _validator.validateAndCorrect(jobcardData);

      onProgress?.call('Complete!');

      // Step 7: Learn from this scan
      await _learningSystem.recordScan(
        imagePath: imagePath,
        extractedData: validatedData,
        template: template,
      );

      // Cleanup
      await AdvancedPreprocessing.cleanup();

      return EnhancedJobcardResult(
        jobcardData: validatedData,
        quality: preprocessResult.quality,
        processingSteps: preprocessResult.steps,
        template: template,
        ocrEngine: ocrResult.engine,
        suggestions: await _learningSystem.getSuggestions(validatedData),
      );
    } catch (e) {
      return EnhancedJobcardResult(
        jobcardData: null,
        quality: 0.0,
        processingSteps: ['Error: $e'],
        error: e.toString(),
      );
    }
  }

  /// Extract data using spatial context
  Future<JobcardData> _extractWithSpatialContext(
    RecognizedText recognizedText,
    List<Barcode> barcodes,
    JobcardTemplate? template,
  ) async {
    final verificationNeeded = <VerificationIssue>[];

    // Extract barcode
    String? barcodeValue;
    double barcodeConfidence = 0.0;
    if (barcodes.isNotEmpty) {
      barcodeValue = barcodes.first.displayValue;
      barcodeConfidence = 1.0;
    }

    // Use spatial parsing for better accuracy
    final worksOrderNo = _extractWithSpatial(
          recognizedText,
          ['works order', 'order no', 'wo'],
          template?.fieldPositions['worksOrderNo'],
        ) ??
        ConfidenceValue(value: barcodeValue, confidence: barcodeConfidence);

    final fgCode = _extractWithSpatial(
      recognizedText,
      ['fg code', 'product code', 'part no'],
      template?.fieldPositions['fgCode'],
    );

    final dateStarted = _extractDateWithSpatial(
      recognizedText,
      ['date started', 'start date'],
      template?.fieldPositions['dateStarted'],
    );

    final quantityToManufacture = _extractNumericWithSpatial(
      recognizedText,
      ['quantity to manufacture', 'qty to mfg', 'target qty'],
      template?.fieldPositions['quantityToManufacture'],
    );

    final dailyOutput = _extractNumericWithSpatial(
      recognizedText,
      ['daily output', 'daily target'],
      template?.fieldPositions['dailyOutput'],
    );

    final cycleTimeSeconds = _extractNumericWithSpatial(
      recognizedText,
      ['cycle time', 'cycle'],
      template?.fieldPositions['cycleTimeSeconds'],
    );

    final cycleWeightGrams = _extractDecimalWithSpatial(
      recognizedText,
      ['cycle weight', 'weight'],
      template?.fieldPositions['cycleWeightGrams'],
    );

    final cavity = _extractNumericWithSpatial(
      recognizedText,
      ['cavity', 'cavities'],
      template?.fieldPositions['cavity'],
    );

    // Extract raw materials table
    final rawMaterials = SpatialParser.extractTable(
      recognizedText,
      'raw material',
    ).map((row) => _parseRawMaterialRow(row)).toList();

    // Extract production rows (not implemented in enhanced parser)
    final productionRows = _extractProductionRows(recognizedText);

    // Check for low confidence fields
    final fields = [
      ('worksOrderNo', worksOrderNo.confidence),
      ('fgCode', fgCode.confidence),
      ('dateStarted', dateStarted.confidence),
      ('quantityToManufacture', quantityToManufacture.confidence),
    ];

    for (final field in fields) {
      if (field.$2 < 0.6) {
        verificationNeeded.add(VerificationIssue(
          field: field.$1,
          reason: 'Low confidence: ${(field.$2 * 100).toInt()}%',
        ));
      }
    }

    return JobcardData(
      worksOrderNo: worksOrderNo,
      jobName: ConfidenceValue(value: null, confidence: 0.0),
      color: ConfidenceValue(value: null, confidence: 0.0),
      cycleWeightGrams: cycleWeightGrams,
      quantityToManufacture: quantityToManufacture,
      dailyOutput: dailyOutput,
      targetCycleDay: ConfidenceValue(value: null, confidence: 0.0),
      targetCycleNight: ConfidenceValue(value: null, confidence: 0.0),
      productionRows: [],
      rawMaterials: rawMaterials,
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

  /// Extract field using spatial context
  ConfidenceValue<String> _extractWithSpatial(
    RecognizedText recognizedText,
    List<String> labels,
    FieldPosition? templatePosition,
  ) {
    // Try template position first
    if (templatePosition != null) {
      final value = _extractFromPosition(recognizedText, templatePosition);
      if (value != null) {
        return ConfidenceValue(value: value, confidence: 0.9);
      }
    }

    // Fall back to spatial search
    for (final label in labels) {
      final value = SpatialParser.findValueNearLabel(label, recognizedText);
      if (value != null && value.isNotEmpty) {
        return ConfidenceValue(value: value, confidence: 0.75);
      }

      final inLine = SpatialParser.findValueInSameLine(label, recognizedText);
      if (inLine != null && inLine.isNotEmpty) {
        return ConfidenceValue(value: inLine, confidence: 0.8);
      }
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  /// Extract numeric field with spatial context
  ConfidenceValue<int> _extractNumericWithSpatial(
    RecognizedText recognizedText,
    List<String> labels,
    FieldPosition? templatePosition,
  ) {
    final stringValue = _extractWithSpatial(
      recognizedText,
      labels,
      templatePosition,
    );

    if (stringValue.value == null) {
      return ConfidenceValue(value: null, confidence: 0.0);
    }

    final cleaned = stringValue.value!.replaceAll(RegExp(r'[^\d]'), '');
    final intValue = int.tryParse(cleaned);

    return ConfidenceValue(
      value: intValue,
      confidence: intValue != null ? stringValue.confidence : 0.0,
    );
  }

  /// Extract decimal field with spatial context
  ConfidenceValue<double> _extractDecimalWithSpatial(
    RecognizedText recognizedText,
    List<String> labels,
    FieldPosition? templatePosition,
  ) {
    final stringValue = _extractWithSpatial(
      recognizedText,
      labels,
      templatePosition,
    );

    if (stringValue.value == null) {
      return ConfidenceValue(value: null, confidence: 0.0);
    }

    final cleaned = stringValue.value!.replaceAll(RegExp(r'[^\d.]'), '');
    final doubleValue = double.tryParse(cleaned);

    return ConfidenceValue(
      value: doubleValue,
      confidence: doubleValue != null ? stringValue.confidence : 0.0,
    );
  }

  /// Extract date with spatial context
  ConfidenceValue<String> _extractDateWithSpatial(
    RecognizedText recognizedText,
    List<String> labels,
    FieldPosition? templatePosition,
  ) {
    final stringValue = _extractWithSpatial(
      recognizedText,
      labels,
      templatePosition,
    );

    if (stringValue.value == null) {
      return ConfidenceValue(value: null, confidence: 0.0);
    }

    // Parse and normalize date
    final dateMatch = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})')
        .firstMatch(stringValue.value!);

    if (dateMatch != null) {
      final day = int.parse(dateMatch.group(1)!);
      final month = int.parse(dateMatch.group(2)!);
      var year = int.parse(dateMatch.group(3)!);
      if (year < 100) year += 2000;

      final isoDate =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

      return ConfidenceValue(
          value: isoDate, confidence: stringValue.confidence);
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  /// Extract value from template position
  String? _extractFromPosition(
    RecognizedText recognizedText,
    FieldPosition position,
  ) {
    // Find text elements at this position
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineX = line.boundingBox.left /
            recognizedText.blocks.first.boundingBox.width;
        final lineY = line.boundingBox.top /
            recognizedText.blocks.last.boundingBox.bottom;

        // Check if position matches
        if ((lineX - position.x).abs() < 0.1 &&
            (lineY - position.y).abs() < 0.1) {
          return line.text;
        }
      }
    }

    return null;
  }

  /// Parse raw material row
  RawMaterialEntry _parseRawMaterialRow(List<String> row) {
    return RawMaterialEntry(
      store: ConfidenceValue(
        value: row.length > 0 ? row[0] : null,
        confidence: 0.7,
      ),
      code: ConfidenceValue(
        value: row.length > 1 ? row[1] : null,
        confidence: 0.7,
      ),
      description: ConfidenceValue(
        value: row.length > 2 ? row[2] : null,
        confidence: 0.7,
      ),
      uoi: ConfidenceValue(
        value: row.length > 3 ? row[3] : null,
        confidence: 0.7,
      ),
      stdQty: ConfidenceValue(
        value: row.length > 4 ? double.tryParse(row[4]) : null,
        confidence: 0.7,
      ),
      dailyQty: ConfidenceValue(
        value: row.length > 5 ? double.tryParse(row[5]) : null,
        confidence: 0.7,
      ),
    );
  }

  /// Extract production rows (placeholder - not implemented in enhanced parser)
  List<ProductionTableRow> _extractProductionRows(
      RecognizedText recognizedText) {
    // This enhanced parser doesn't extract production table
    // Use the main jobcard_parser_service.dart instead
    return [];
  }

  ConfidenceValue<int> _extractCounter(
    RecognizedText recognizedText,
    List<String> labels,
  ) {
    for (final label in labels) {
      final value = SpatialParser.findValueNearLabel(label, recognizedText);
      if (value != null) {
        final intValue = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
        if (intValue != null) {
          return ConfidenceValue(value: intValue, confidence: 0.7);
        }
      }
    }

    return ConfidenceValue(value: null, confidence: 0.0);
  }

  /// Record user corrections for learning
  Future<void> recordCorrection(
    JobcardData original,
    JobcardData corrected,
  ) async {
    await _learningSystem.recordCorrection(original, corrected);
  }

  void dispose() {
    _barcodeScanner.close();
    _multiPassOCR.dispose();
  }
}

class EnhancedJobcardResult {
  final JobcardData? jobcardData;
  final double quality;
  final List<String> processingSteps;
  final JobcardTemplate? template;
  final String? ocrEngine;
  final List<String>? suggestions;
  final String? error;

  EnhancedJobcardResult({
    required this.jobcardData,
    required this.quality,
    required this.processingSteps,
    this.template,
    this.ocrEngine,
    this.suggestions,
    this.error,
  });
}
