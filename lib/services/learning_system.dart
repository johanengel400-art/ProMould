import 'package:hive/hive.dart';
import '../utils/jobcard_models.dart';
import 'template_manager.dart';

/// Continuous learning system that improves over time
class LearningSystem {
  static const String _correctionsBox = 'jobcard_corrections';
  static const String _scansBox = 'jobcard_scans';

  /// Record a jobcard scan
  Future<void> recordScan({
    required String imagePath,
    required JobcardData extractedData,
    JobcardTemplate? template,
  }) async {
    final box = await Hive.openBox(_scansBox);

    final scanRecord = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'imagePath': imagePath,
      'extractedData': extractedData.toJson(),
      'templateId': template?.id,
      'confidence': extractedData.overallConfidence,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await box.add(scanRecord);
  }

  /// Record user correction
  Future<void> recordCorrection(
    JobcardData original,
    JobcardData corrected,
  ) async {
    final box = await Hive.openBox(_correctionsBox);

    // Record field-level corrections
    final corrections = <Map<String, dynamic>>[];

    if (original.worksOrderNo.value != corrected.worksOrderNo.value) {
      corrections.add({
        'field': 'worksOrderNo',
        'original': original.worksOrderNo.value,
        'corrected': corrected.worksOrderNo.value,
        'confidence': original.worksOrderNo.confidence,
      });
    }

    if (original.jobName.value != corrected.jobName.value) {
      corrections.add({
        'field': 'jobName',
        'original': original.jobName.value,
        'corrected': corrected.jobName.value,
        'confidence': original.jobName.confidence,
      });
    }

    if (original.color.value != corrected.color.value) {
      corrections.add({
        'field': 'color',
        'original': original.color.value,
        'corrected': corrected.color.value,
        'confidence': original.color.confidence,
      });
    }

    if (original.quantityToManufacture.value !=
        corrected.quantityToManufacture.value) {
      corrections.add({
        'field': 'quantityToManufacture',
        'original': original.quantityToManufacture.value,
        'corrected': corrected.quantityToManufacture.value,
        'confidence': original.quantityToManufacture.confidence,
      });
    }

    // Store corrections
    for (final correction in corrections) {
      await box.add({
        ...correction,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get suggestions based on learning history
  Future<List<String>> getSuggestions(JobcardData data) async {
    final suggestions = <String>[];
    await Hive.openBox(_correctionsBox);

    // Analyze common corrections
    final commonCorrections = await _getCommonCorrections();

    for (final correction in commonCorrections.entries) {
      final field = correction.key;
      final pattern = correction.value;

      suggestions.add(
        'Field "$field" is often corrected. Common pattern: $pattern',
      );
    }

    // Check for similar past scans
    final similarScans = await _findSimilarScans(data);
    if (similarScans.isNotEmpty) {
      suggestions.add(
        'Found ${similarScans.length} similar jobcards in history',
      );
    }

    return suggestions;
  }

  /// Get common correction patterns
  Future<Map<String, String>> _getCommonCorrections() async {
    final box = await Hive.openBox(_correctionsBox);
    final corrections = <String, Map<String, int>>{};

    for (final value in box.values) {
      final correction = Map<String, dynamic>.from(value as Map);
      final field = correction['field'] as String;
      final original = correction['original']?.toString() ?? '';
      final corrected = correction['corrected']?.toString() ?? '';

      if (original.isNotEmpty && corrected.isNotEmpty) {
        corrections[field] ??= {};
        final pattern = '$original→$corrected';
        corrections[field]![pattern] = (corrections[field]![pattern] ?? 0) + 1;
      }
    }

    // Get most common pattern for each field
    final commonPatterns = <String, String>{};
    corrections.forEach((field, patterns) {
      if (patterns.isNotEmpty) {
        final mostCommon = patterns.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        if (mostCommon.value >= 3) {
          // At least 3 occurrences
          commonPatterns[field] = mostCommon.key;
        }
      }
    });

    return commonPatterns;
  }

  /// Find similar past scans
  Future<List<Map<String, dynamic>>> _findSimilarScans(
    JobcardData data,
  ) async {
    final box = await Hive.openBox(_scansBox);
    final similar = <Map<String, dynamic>>[];

    for (final value in box.values) {
      final scan = Map<String, dynamic>.from(value as Map);
      final extractedData = JobcardData.fromJson(
        Map<String, dynamic>.from(scan['extractedData'] as Map),
      );

      // Calculate similarity
      final similarity = _calculateDataSimilarity(data, extractedData);
      if (similarity > 0.7) {
        similar.add(scan);
      }
    }

    return similar;
  }

  /// Calculate similarity between two jobcard data
  double _calculateDataSimilarity(JobcardData a, JobcardData b) {
    int matches = 0;
    int total = 0;

    // Compare job name
    if (a.jobName.value != null && b.jobName.value != null) {
      if (a.jobName.value == b.jobName.value) matches++;
      total++;
    }

    // Compare color
    if (a.color.value != null && b.color.value != null) {
      if (a.color.value == b.color.value) matches++;
      total++;
    }

    // Compare cycle weight
    if (a.cycleWeightGrams.value != null && b.cycleWeightGrams.value != null) {
      final diff =
          (a.cycleWeightGrams.value! - b.cycleWeightGrams.value!).abs();
      if (diff < 100) matches++; // Within 100 grams
      total++;
    }

    return total > 0 ? matches / total : 0.0;
  }

  /// Get analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    final scansBox = await Hive.openBox(_scansBox);
    final correctionsBox = await Hive.openBox(_correctionsBox);

    final scans = scansBox.values.toList();
    final corrections = correctionsBox.values.toList();

    // Calculate average confidence
    double totalConfidence = 0;
    int confidenceCount = 0;

    for (final scan in scans) {
      final scanMap = Map<String, dynamic>.from(scan as Map);
      final confidence = scanMap['confidence'] as double?;
      if (confidence != null) {
        totalConfidence += confidence;
        confidenceCount++;
      }
    }

    final avgConfidence =
        confidenceCount > 0 ? totalConfidence / confidenceCount : 0.0;

    // Calculate correction rate
    final correctionRate =
        scans.isNotEmpty ? corrections.length / scans.length : 0.0;

    // Most corrected fields
    final fieldCorrections = <String, int>{};
    for (final correction in corrections) {
      final correctionMap = Map<String, dynamic>.from(correction as Map);
      final field = correctionMap['field'] as String;
      fieldCorrections[field] = (fieldCorrections[field] ?? 0) + 1;
    }

    return {
      'totalScans': scans.length,
      'totalCorrections': corrections.length,
      'averageConfidence': avgConfidence,
      'correctionRate': correctionRate,
      'mostCorrectedFields': fieldCorrections,
      'improvementTrend': await _calculateImprovementTrend(),
    };
  }

  /// Calculate improvement trend over time
  Future<List<Map<String, dynamic>>> _calculateImprovementTrend() async {
    final box = await Hive.openBox(_scansBox);
    final scans = box.values.toList();

    // Group by week
    final weeklyData = <String, List<double>>{};

    for (final scan in scans) {
      final scanMap = Map<String, dynamic>.from(scan as Map);
      final timestamp = DateTime.parse(scanMap['timestamp'] as String);
      final confidence = scanMap['confidence'] as double?;

      if (confidence != null) {
        final weekKey = '${timestamp.year}-W${_getWeekNumber(timestamp)}';
        weeklyData[weekKey] ??= [];
        weeklyData[weekKey]!.add(confidence);
      }
    }

    // Calculate weekly averages
    final trend = <Map<String, dynamic>>[];
    weeklyData.forEach((week, confidences) {
      final avg = confidences.reduce((a, b) => a + b) / confidences.length;
      trend.add({
        'week': week,
        'averageConfidence': avg,
        'scanCount': confidences.length,
      });
    });

    trend.sort((a, b) => (a['week'] as String).compareTo(b['week'] as String));

    return trend;
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(date
        .difference(
          DateTime(date.year, 1, 1),
        )
        .inDays
        .toString());
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Clear old data (keep last 90 days)
  Future<void> cleanupOldData() async {
    final scansBox = await Hive.openBox(_scansBox);
    final correctionsBox = await Hive.openBox(_correctionsBox);

    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

    // Clean scans
    final scansToDelete = <dynamic>[];
    for (final key in scansBox.keys) {
      final scan = Map<String, dynamic>.from(scansBox.get(key) as Map);
      final timestamp = DateTime.parse(scan['timestamp'] as String);
      if (timestamp.isBefore(cutoffDate)) {
        scansToDelete.add(key);
      }
    }
    for (final key in scansToDelete) {
      await scansBox.delete(key);
    }

    // Clean corrections
    final correctionsToDelete = <dynamic>[];
    for (final key in correctionsBox.keys) {
      final correction =
          Map<String, dynamic>.from(correctionsBox.get(key) as Map);
      final timestamp = DateTime.parse(correction['timestamp'] as String);
      if (timestamp.isBefore(cutoffDate)) {
        correctionsToDelete.add(key);
      }
    }
    for (final key in correctionsToDelete) {
      await correctionsBox.delete(key);
    }
  }
}
