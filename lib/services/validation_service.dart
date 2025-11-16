import '../utils/jobcard_models.dart';

/// Validation and auto-correction service
class ValidationService {
  /// Validate and auto-correct jobcard data
  Future<JobcardData> validateAndCorrect(JobcardData data) async {
    // Auto-correct common OCR errors
    var corrected = _autoCorrectOCRErrors(data);

    // Validate business rules
    corrected = _validateBusinessRules(corrected);

    // Normalize data
    corrected = _normalizeData(corrected);

    return corrected;
  }

  /// Auto-correct common OCR errors
  JobcardData _autoCorrectOCRErrors(JobcardData data) {
    // Common OCR substitutions
    final corrections = {
      '0': 'O',
      'O': '0',
      '1': 'I',
      'I': '1',
      '5': 'S',
      'S': '5',
      '8': 'B',
      'B': '8',
    };

    // Correct works order number
    var worksOrderNo = data.worksOrderNo.value;
    if (worksOrderNo != null) {
      // Apply corrections based on context
      worksOrderNo = _applyContextualCorrections(worksOrderNo, isNumeric: true);
    }

    // Correct FG code
    var fgCode = data.fgCode.value;
    if (fgCode != null) {
      fgCode = _applyContextualCorrections(fgCode, isAlphanumeric: true);
    }

    return JobcardData(
      worksOrderNo: ConfidenceValue(
        value: worksOrderNo,
        confidence: data.worksOrderNo.confidence,
      ),
      barcode: data.barcode,
      fgCode: ConfidenceValue(
        value: fgCode,
        confidence: data.fgCode.confidence,
      ),
      dateStarted: data.dateStarted,
      quantityToManufacture: data.quantityToManufacture,
      dailyOutput: data.dailyOutput,
      cycleTimeSeconds: data.cycleTimeSeconds,
      cycleWeightGrams: data.cycleWeightGrams,
      cavity: data.cavity,
      rawMaterials: data.rawMaterials,
      counters: data.counters,
      rawOcrText: data.rawOcrText,
      verificationNeeded: data.verificationNeeded,
      timestamp: data.timestamp,
    );
  }

  /// Apply contextual corrections
  String _applyContextualCorrections(
    String text, {
    bool isNumeric = false,
    bool isAlphanumeric = false,
  }) {
    var corrected = text;

    if (isNumeric) {
      // Replace letters that should be numbers
      corrected = corrected
          .replaceAll('O', '0')
          .replaceAll('o', '0')
          .replaceAll('I', '1')
          .replaceAll('l', '1')
          .replaceAll('S', '5')
          .replaceAll('s', '5')
          .replaceAll('B', '8')
          .replaceAll('b', '8');
    }

    return corrected;
  }

  /// Validate business rules
  JobcardData _validateBusinessRules(JobcardData data) {
    final issues = List<VerificationIssue>.from(data.verificationNeeded);

    // Validate quantity
    if (data.quantityToManufacture.value != null) {
      if (data.quantityToManufacture.value! < 0) {
        issues.add(VerificationIssue(
          field: 'quantityToManufacture',
          reason: 'Quantity cannot be negative',
        ));
      }
      if (data.quantityToManufacture.value! > 1000000) {
        issues.add(VerificationIssue(
          field: 'quantityToManufacture',
          reason: 'Quantity seems unusually high',
        ));
      }
    }

    // Validate cycle time
    if (data.cycleTimeSeconds.value != null) {
      if (data.cycleTimeSeconds.value! < 1 ||
          data.cycleTimeSeconds.value! > 3600) {
        issues.add(VerificationIssue(
          field: 'cycleTimeSeconds',
          reason: 'Cycle time should be between 1-3600 seconds',
        ));
      }
    }

    // Validate date
    if (data.dateStarted.value != null) {
      try {
        final date = DateTime.parse(data.dateStarted.value!);
        final now = DateTime.now();
        final oneYearAgo = now.subtract(const Duration(days: 365));
        final oneMonthAhead = now.add(const Duration(days: 30));

        if (date.isBefore(oneYearAgo) || date.isAfter(oneMonthAhead)) {
          issues.add(VerificationIssue(
            field: 'dateStarted',
            reason: 'Date seems unusual (too far in past or future)',
          ));
        }
      } catch (e) {
        issues.add(VerificationIssue(
          field: 'dateStarted',
          reason: 'Invalid date format',
        ));
      }
    }

    // Validate cavity
    if (data.cavity.value != null) {
      if (data.cavity.value! < 1 || data.cavity.value! > 128) {
        issues.add(VerificationIssue(
          field: 'cavity',
          reason: 'Cavity count should be between 1-128',
        ));
      }
    }

    return JobcardData(
      worksOrderNo: data.worksOrderNo,
      barcode: data.barcode,
      fgCode: data.fgCode,
      dateStarted: data.dateStarted,
      quantityToManufacture: data.quantityToManufacture,
      dailyOutput: data.dailyOutput,
      cycleTimeSeconds: data.cycleTimeSeconds,
      cycleWeightGrams: data.cycleWeightGrams,
      cavity: data.cavity,
      rawMaterials: data.rawMaterials,
      counters: data.counters,
      rawOcrText: data.rawOcrText,
      verificationNeeded: issues,
      timestamp: data.timestamp,
    );
  }

  /// Normalize data
  JobcardData _normalizeData(JobcardData data) {
    // Trim whitespace
    var worksOrderNo = data.worksOrderNo.value?.trim();
    var fgCode = data.fgCode.value?.trim();

    // Uppercase codes
    worksOrderNo = worksOrderNo?.toUpperCase();
    fgCode = fgCode?.toUpperCase();

    return JobcardData(
      worksOrderNo: ConfidenceValue(
        value: worksOrderNo,
        confidence: data.worksOrderNo.confidence,
      ),
      barcode: data.barcode,
      fgCode: ConfidenceValue(
        value: fgCode,
        confidence: data.fgCode.confidence,
      ),
      dateStarted: data.dateStarted,
      quantityToManufacture: data.quantityToManufacture,
      dailyOutput: data.dailyOutput,
      cycleTimeSeconds: data.cycleTimeSeconds,
      cycleWeightGrams: data.cycleWeightGrams,
      cavity: data.cavity,
      rawMaterials: data.rawMaterials,
      counters: data.counters,
      rawOcrText: data.rawOcrText,
      verificationNeeded: data.verificationNeeded,
      timestamp: data.timestamp,
    );
  }

  /// Cross-validate with existing data
  Future<List<String>> crossValidate(
    JobcardData data,
    List<Map<String, dynamic>> existingJobs,
  ) async {
    final warnings = <String>[];

    // Check for duplicate works order
    if (data.worksOrderNo.value != null) {
      final duplicate = existingJobs.any(
        (job) => job['worksOrderNo'] == data.worksOrderNo.value,
      );
      if (duplicate) {
        warnings.add('Works order number already exists');
      }
    }

    // Check for similar FG codes
    if (data.fgCode.value != null) {
      final similar = existingJobs.where((job) {
        final jobFgCode = job['fgCode'] as String?;
        if (jobFgCode == null) return false;
        return _calculateSimilarity(jobFgCode, data.fgCode.value!) > 0.8;
      }).toList();

      if (similar.isNotEmpty) {
        warnings.add('Similar FG code found: ${similar.first['fgCode']}');
      }
    }

    return warnings;
  }

  /// Calculate string similarity (Levenshtein distance)
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final maxLength = a.length > b.length ? a.length : b.length;
    return 1.0 - (matrix[a.length][b.length] / maxLength);
  }
}
