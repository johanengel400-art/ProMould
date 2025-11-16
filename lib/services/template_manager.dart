import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/spatial_parser.dart';

/// Template detection and learning system for jobcards
class TemplateManager {
  static const String _boxName = 'jobcard_templates';

  /// Detect which template matches the current jobcard
  Future<JobcardTemplate?> detectTemplate(
    RecognizedText recognizedText,
  ) async {
    final templates = await _loadTemplates();

    if (templates.isEmpty) {
      return null;
    }

    // Calculate similarity scores for each template
    final scores = <JobcardTemplate, double>{};

    for (final template in templates) {
      final score = _calculateSimilarity(recognizedText, template);
      scores[template] = score;
    }

    // Return best matching template (if score > threshold)
    final bestMatch = scores.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    if (bestMatch.value > 0.6) {
      return bestMatch.key;
    }

    return null;
  }

  /// Learn from a verified jobcard scan
  Future<void> learnFromVerification(
    RecognizedText recognizedText,
    Map<String, dynamic> verifiedData,
  ) async {
    // Extract field positions from OCR result
    final fieldPositions = _extractFieldPositions(
      recognizedText,
      verifiedData,
    );

    // Check if this matches an existing template
    final existingTemplate = await detectTemplate(recognizedText);

    if (existingTemplate != null) {
      // Update existing template
      await _updateTemplate(existingTemplate, fieldPositions);
    } else {
      // Create new template
      await _createTemplate(recognizedText, fieldPositions);
    }
  }

  /// Calculate similarity between OCR result and template
  double _calculateSimilarity(
    RecognizedText recognizedText,
    JobcardTemplate template,
  ) {
    double score = 0.0;
    int checks = 0;

    // Check for key labels
    final text = recognizedText.text.toLowerCase();
    for (final label in template.keyLabels) {
      if (text.contains(label.toLowerCase())) {
        score += 1.0;
      }
      checks++;
    }

    // Check layout similarity (number of blocks, lines)
    final blockCountDiff = (recognizedText.blocks.length - template.blockCount).abs();
    final blockSimilarity = 1.0 - (blockCountDiff / template.blockCount).clamp(0.0, 1.0);
    score += blockSimilarity;
    checks++;

    // Check field position similarity
    for (final field in template.fieldPositions.entries) {
      final foundPosition = _findFieldPosition(recognizedText, field.key);
      if (foundPosition != null) {
        final positionSimilarity = _calculatePositionSimilarity(
          foundPosition,
          field.value,
        );
        score += positionSimilarity;
        checks++;
      }
    }

    return checks > 0 ? score / checks : 0.0;
  }

  /// Extract field positions from verified data
  Map<String, FieldPosition> _extractFieldPositions(
    RecognizedText recognizedText,
    Map<String, dynamic> verifiedData,
  ) {
    final positions = <String, FieldPosition>{};

    for (final entry in verifiedData.entries) {
      final fieldName = entry.key;
      final fieldValue = entry.value?.toString() ?? '';

      if (fieldValue.isEmpty) continue;

      // Find this value in the OCR result
      final position = _findTextPosition(recognizedText, fieldValue);
      if (position != null) {
        positions[fieldName] = position;
      }
    }

    return positions;
  }

  /// Find position of text in OCR result
  FieldPosition? _findTextPosition(
    RecognizedText recognizedText,
    String searchText,
  ) {
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        if (line.text.contains(searchText)) {
          return FieldPosition(
            x: line.boundingBox.left / recognizedText.blocks.first.boundingBox.width,
            y: line.boundingBox.top / recognizedText.blocks.last.boundingBox.bottom,
            width: line.boundingBox.width / recognizedText.blocks.first.boundingBox.width,
            height: line.boundingBox.height / recognizedText.blocks.last.boundingBox.bottom,
          );
        }
      }
    }

    return null;
  }

  /// Find field position in OCR result
  FieldPosition? _findFieldPosition(
    RecognizedText recognizedText,
    String fieldName,
  ) {
    // Look for field label
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        if (line.text.toLowerCase().contains(fieldName.toLowerCase())) {
          return FieldPosition(
            x: line.boundingBox.left / recognizedText.blocks.first.boundingBox.width,
            y: line.boundingBox.top / recognizedText.blocks.last.boundingBox.bottom,
            width: line.boundingBox.width / recognizedText.blocks.first.boundingBox.width,
            height: line.boundingBox.height / recognizedText.blocks.last.boundingBox.bottom,
          );
        }
      }
    }

    return null;
  }

  /// Calculate similarity between two positions
  double _calculatePositionSimilarity(
    FieldPosition a,
    FieldPosition b,
  ) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    final distance = dx + dy;

    return (1.0 - distance).clamp(0.0, 1.0);
  }

  /// Create new template
  Future<void> _createTemplate(
    RecognizedText recognizedText,
    Map<String, FieldPosition> fieldPositions,
  ) async {
    final box = await Hive.openBox(_boxName);

    final template = JobcardTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Template ${box.length + 1}',
      keyLabels: _extractKeyLabels(recognizedText),
      blockCount: recognizedText.blocks.length,
      fieldPositions: fieldPositions,
      usageCount: 1,
      accuracy: 1.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await box.put(template.id, template.toJson());
  }

  /// Update existing template
  Future<void> _updateTemplate(
    JobcardTemplate template,
    Map<String, FieldPosition> newPositions,
  ) async {
    final box = await Hive.openBox(_boxName);

    // Merge field positions (weighted average)
    final mergedPositions = <String, FieldPosition>{};

    for (final entry in template.fieldPositions.entries) {
      final fieldName = entry.key;
      final oldPosition = entry.value;
      final newPosition = newPositions[fieldName];

      if (newPosition != null) {
        // Weighted average (favor existing data)
        final weight = template.usageCount / (template.usageCount + 1);
        mergedPositions[fieldName] = FieldPosition(
          x: oldPosition.x * weight + newPosition.x * (1 - weight),
          y: oldPosition.y * weight + newPosition.y * (1 - weight),
          width: oldPosition.width * weight + newPosition.width * (1 - weight),
          height: oldPosition.height * weight + newPosition.height * (1 - weight),
        );
      } else {
        mergedPositions[fieldName] = oldPosition;
      }
    }

    // Add new fields
    for (final entry in newPositions.entries) {
      if (!mergedPositions.containsKey(entry.key)) {
        mergedPositions[entry.key] = entry.value;
      }
    }

    final updatedTemplate = JobcardTemplate(
      id: template.id,
      name: template.name,
      keyLabels: template.keyLabels,
      blockCount: template.blockCount,
      fieldPositions: mergedPositions,
      usageCount: template.usageCount + 1,
      accuracy: template.accuracy,
      createdAt: template.createdAt,
      updatedAt: DateTime.now(),
    );

    await box.put(template.id, updatedTemplate.toJson());
  }

  /// Extract key labels from OCR result
  List<String> _extractKeyLabels(RecognizedText recognizedText) {
    final labels = <String>[];
    final keywordPatterns = [
      'works order',
      'fg code',
      'date started',
      'quantity',
      'cycle time',
      'raw material',
    ];

    final text = recognizedText.text.toLowerCase();

    for (final pattern in keywordPatterns) {
      if (text.contains(pattern)) {
        labels.add(pattern);
      }
    }

    return labels;
  }

  /// Load all templates
  Future<List<JobcardTemplate>> _loadTemplates() async {
    final box = await Hive.openBox(_boxName);
    final templates = <JobcardTemplate>[];

    for (final value in box.values) {
      try {
        final template = JobcardTemplate.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
        templates.add(template);
      } catch (e) {
        // Skip invalid templates
      }
    }

    return templates;
  }

  /// Get template statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final templates = await _loadTemplates();

    return {
      'totalTemplates': templates.length,
      'totalUsage': templates.fold<int>(0, (sum, t) => sum + t.usageCount),
      'averageAccuracy': templates.isEmpty
          ? 0.0
          : templates.fold<double>(0, (sum, t) => sum + t.accuracy) /
              templates.length,
      'templates': templates.map((t) => t.toJson()).toList(),
    };
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(templateId);
  }

  /// Clear all templates
  Future<void> clearAllTemplates() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}

class JobcardTemplate {
  final String id;
  final String name;
  final List<String> keyLabels;
  final int blockCount;
  final Map<String, FieldPosition> fieldPositions;
  final int usageCount;
  final double accuracy;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobcardTemplate({
    required this.id,
    required this.name,
    required this.keyLabels,
    required this.blockCount,
    required this.fieldPositions,
    required this.usageCount,
    required this.accuracy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobcardTemplate.fromJson(Map<String, dynamic> json) {
    final fieldPositionsMap = <String, FieldPosition>{};
    final positions = json['fieldPositions'] as Map<String, dynamic>?;

    if (positions != null) {
      positions.forEach((key, value) {
        fieldPositionsMap[key] = FieldPosition.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
      });
    }

    return JobcardTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      keyLabels: List<String>.from(json['keyLabels'] as List),
      blockCount: json['blockCount'] as int,
      fieldPositions: fieldPositionsMap,
      usageCount: json['usageCount'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keyLabels': keyLabels,
      'blockCount': blockCount,
      'fieldPositions': fieldPositions.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'usageCount': usageCount,
      'accuracy': accuracy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class FieldPosition {
  final double x; // Normalized 0-1
  final double y; // Normalized 0-1
  final double width; // Normalized 0-1
  final double height; // Normalized 0-1

  FieldPosition({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory FieldPosition.fromJson(Map<String, dynamic> json) {
    return FieldPosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}
