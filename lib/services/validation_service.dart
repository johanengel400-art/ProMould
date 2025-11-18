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
    // Correct works order number
    var worksOrderNo = data.worksOrderNo.value;
    if (worksOrderNo != null) {
      // Apply corrections based on context
      worksOrderNo = _applyContextualCorrections(worksOrderNo, isNumeric: true);
    }

    // Correct job name
    var jobName = data.jobName.value;
    if (jobName != null) {
      jobName = _applyContextualCorrections(jobName, isAlphanumeric: true);
    }

    return JobcardData(
      worksOrderNo: ConfidenceValue(
        value: worksOrderNo,
        confidence: data.worksOrderNo.confidence,
      ),
      jobName: ConfidenceValue(
        value: jobName,
        confidence: data.jobName.confidence,
      ),
      color: data.color,
      cycleWeightGrams: data.cycleWeightGrams,
      quantityToManufacture: data.quantityToManufacture,
      dailyOutput: data.dailyOutput,
      targetCycleDay: data.targetCycleDay,
      targetCycleNight: data.targetCycleNight,
      productionRows: data.productionRows,
      rawMaterials: data.rawMaterials,
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

    // Validate cycle weight
    if (data.cycleWeightGrams.value != null) {
      if (data.cycleWeightGrams.value! < 1 ||
          data.cycleWeightGrams.value! > 100000) {
        issues.add(VerificationIssue(
          field: 'cycleWeightGrams',
          reason: 'Cycle weight should be between 1-100000 grams',
        ));
      }
    }

    // Validate target cycles
    if (data.targetCycleDay.value != null) {
      if (data.targetCycleDay.value! < 0 ||
          data.targetCycleDay.value! > 10000) {
        issues.add(VerificationIssue(
          field: 'targetCycleDay',
          reason: 'Target cycle day seems unusual',
        ));
      }
    }

    if (data.targetCycleNight.value != null) {
      if (data.targetCycleNight.value! < 0 ||
          data.targetCycleNight.value! > 10000) {
        issues.add(VerificationIssue(
          field: 'targetCycleNight',
          reason: 'Target cycle night seems unusual',
        ));
      }
    }

    return JobcardData(
      worksOrderNo: data.worksOrderNo,
      jobName: data.jobName,
      color: data.color,
      cycleWeightGrams: data.cycleWeightGrams,
      quantityToManufacture: data.quantityToManufacture,
      dailyOutput: data.dailyOutput,
      targetCycleDay: data.targetCycleDay,
      targetCycleNight: data.targetCycleNight,
      productionRows: data.productionRows,
      rawMaterials: data.rawMaterials,
      rawOcrText: data.rawOcrText,
      verificationNeeded: issues,
      timestamp: data.timestamp,
    );
  }

  /// Normalize data
  JobcardData _normalizeData(JobcardData data) {
    // Trim whitespace
    var worksOrderNo = data.worksOrderNo.value?.trim();
    var jobName = data.jobName.value?.trim();

    // Uppercase codes
    worksOrderNo = worksOrderNo?.toUpperCase();

    return JobcardData(
      worksOrderNo: ConfidenceValue(
        value: worksOrderNo,
        confidence: data.worksOrderNo.confidence,
      ),
      jobName: data.jobName,
      color: data.color,
      cycleWeightGrams: data.cycleWeightGrams,
      quantityToManufacture: data.quantityToManufacture,
      dailyOutput: data.dailyOutput,
      targetCycleDay: data.targetCycleDay,
      targetCycleNight: data.targetCycleNight,
      productionRows: data.productionRows,
      rawMaterials: data.rawMaterials,
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

    // Check for similar job names
    if (data.jobName.value != null) {
      final similar = existingJobs.where((job) {
        final jobName = job['productName'] as String?;
        if (jobName == null) return false;
        return _calculateSimilarity(jobName, data.jobName.value!) > 0.8;
      }).toList();

      if (similar.isNotEmpty) {
        warnings.add('Similar job name found: ${similar.first['productName']}');
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
