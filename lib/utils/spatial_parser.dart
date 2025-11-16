import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:math' as math;

/// Spatial context parser using bounding box analysis
class SpatialParser {
  /// Parse text using spatial relationships
  static Map<String, TextElement> buildSpatialIndex(
      RecognizedText recognizedText) {
    final index = <String, TextElement>{};

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final textElement = TextElement(
            text: element.text,
            boundingBox: element.boundingBox,
            confidence: element.confidence ?? 0.0,
          );
          index[element.text.toLowerCase()] = textElement;
        }
      }
    }

    return index;
  }

  /// Find value near a label using spatial proximity
  static String? findValueNearLabel(
    String label,
    RecognizedText recognizedText, {
    double maxDistance = 200.0,
  }) {
    TextElement? labelElement;
    final allElements = <TextElement>[];

    // Build element list and find label
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final textElement = TextElement(
            text: element.text,
            boundingBox: element.boundingBox,
            confidence: element.confidence ?? 0.0,
          );
          allElements.add(textElement);

          if (element.text.toLowerCase().contains(label.toLowerCase())) {
            labelElement = textElement;
          }
        }
      }
    }

    if (labelElement == null) return null;

    // Find closest element to the right or below
    TextElement? closestElement;
    double minDistance = maxDistance;

    for (final element in allElements) {
      if (element == labelElement) continue;

      // Calculate distance
      final distance = _calculateDistance(labelElement, element);

      // Check if element is to the right or below
      final isRightOrBelow = _isRightOrBelow(labelElement, element);

      if (isRightOrBelow && distance < minDistance) {
        minDistance = distance;
        closestElement = element;
      }
    }

    return closestElement?.text;
  }

  /// Find value in same line as label
  static String? findValueInSameLine(
    String label,
    RecognizedText recognizedText,
  ) {
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.toLowerCase();
        if (lineText.contains(label.toLowerCase())) {
          // Extract value after label
          final parts = line.text.split(RegExp(r'[:：]'));
          if (parts.length > 1) {
            return parts[1].trim();
          }

          // Try to find numeric value in same line
          final match = RegExp(r'[\d,]+\.?\d*').firstMatch(line.text);
          if (match != null) {
            return match.group(0);
          }
        }
      }
    }

    return null;
  }

  /// Extract table data using column alignment
  static List<List<String>> extractTable(
    RecognizedText recognizedText,
    String tableHeaderKeyword,
  ) {
    final table = <List<String>>[];
    bool inTable = false;
    List<double>? columnPositions;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.toLowerCase();

        // Detect table start
        if (lineText.contains(tableHeaderKeyword.toLowerCase())) {
          inTable = true;
          columnPositions = _detectColumnPositions(line);
          continue;
        }

        // Extract table rows
        if (inTable) {
          // Stop if empty line or new section
          if (line.text.trim().isEmpty || _isNewSection(line.text)) {
            break;
          }

          // Parse row using column positions
          if (columnPositions != null) {
            final row = _parseTableRow(line, columnPositions);
            if (row.isNotEmpty) {
              table.add(row);
            }
          }
        }
      }
    }

    return table;
  }

  /// Detect column positions from header line
  static List<double> _detectColumnPositions(TextLine line) {
    final positions = <double>[];

    for (final element in line.elements) {
      positions.add(element.boundingBox.left.toDouble());
    }

    positions.sort();
    return positions;
  }

  /// Parse table row using column positions
  static List<String> _parseTableRow(
    TextLine line,
    List<double> columnPositions,
  ) {
    final row = <String>[];
    final elements = line.elements.toList();

    // Sort elements by x position
    elements.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    // Group elements by column
    int columnIndex = 0;
    final columnTexts = <String>[];

    for (final element in elements) {
      final elementX = element.boundingBox.left.toDouble();

      // Find which column this element belongs to
      while (columnIndex < columnPositions.length - 1 &&
          elementX > columnPositions[columnIndex + 1]) {
        columnIndex++;
      }

      // Add to column text
      if (columnIndex < columnTexts.length) {
        columnTexts[columnIndex] += ' ${element.text}';
      } else {
        columnTexts.add(element.text);
      }
    }

    return columnTexts.map((t) => t.trim()).toList();
  }

  /// Check if text indicates a new section
  static bool _isNewSection(String text) {
    final sectionKeywords = [
      'notes',
      'remarks',
      'signature',
      'approved',
      'total',
    ];

    final lowerText = text.toLowerCase();
    return sectionKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Calculate distance between two text elements
  static double _calculateDistance(TextElement a, TextElement b) {
    final aCenterX = a.boundingBox.left + a.boundingBox.width / 2;
    final aCenterY = a.boundingBox.top + a.boundingBox.height / 2;
    final bCenterX = b.boundingBox.left + b.boundingBox.width / 2;
    final bCenterY = b.boundingBox.top + b.boundingBox.height / 2;

    final dx = aCenterX - bCenterX;
    final dy = aCenterY - bCenterY;

    return math.sqrt(dx * dx + dy * dy);
  }

  /// Check if element B is to the right or below element A
  static bool _isRightOrBelow(TextElement a, TextElement b) {
    final aRight = a.boundingBox.left + a.boundingBox.width;
    final aBottom = a.boundingBox.top + a.boundingBox.height;

    // To the right
    if (b.boundingBox.left > aRight) {
      return true;
    }

    // Below
    if (b.boundingBox.top > aBottom) {
      return true;
    }

    return false;
  }

  /// Group elements by vertical alignment (same row)
  static List<List<TextElement>> groupByRow(
    List<TextElement> elements, {
    double tolerance = 10.0,
  }) {
    final rows = <List<TextElement>>[];
    final sortedElements = List<TextElement>.from(elements);

    // Sort by Y position
    sortedElements
        .sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    List<TextElement> currentRow = [];
    double? currentY;

    for (final element in sortedElements) {
      final elementY = element.boundingBox.top.toDouble();

      if (currentY == null || (elementY - currentY).abs() <= tolerance) {
        currentRow.add(element);
        currentY ??= elementY;
      } else {
        if (currentRow.isNotEmpty) {
          rows.add(currentRow);
        }
        currentRow = [element];
        currentY = elementY;
      }
    }

    if (currentRow.isNotEmpty) {
      rows.add(currentRow);
    }

    return rows;
  }

  /// Group elements by horizontal alignment (same column)
  static List<List<TextElement>> groupByColumn(
    List<TextElement> elements, {
    double tolerance = 20.0,
  }) {
    final columns = <List<TextElement>>[];
    final sortedElements = List<TextElement>.from(elements);

    // Sort by X position
    sortedElements
        .sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    List<TextElement> currentColumn = [];
    double? currentX;

    for (final element in sortedElements) {
      final elementX = element.boundingBox.left.toDouble();

      if (currentX == null || (elementX - currentX).abs() <= tolerance) {
        currentColumn.add(element);
        currentX ??= elementX;
      } else {
        if (currentColumn.isNotEmpty) {
          columns.add(currentColumn);
        }
        currentColumn = [element];
        currentX = elementX;
      }
    }

    if (currentColumn.isNotEmpty) {
      columns.add(currentColumn);
    }

    return columns;
  }

  /// Find elements within a bounding box region
  static List<TextElement> findElementsInRegion(
    List<TextElement> elements,
    BoundingRect region,
  ) {
    return elements.where((element) {
      final box = element.boundingBox;
      return box.left >= region.left &&
          box.top >= region.top &&
          box.left + box.width <= region.left + region.width &&
          box.top + box.height <= region.top + region.height;
    }).toList();
  }

  /// Detect form sections based on layout
  static Map<String, BoundingRect> detectFormSections(RecognizedText recognizedText) {
    final sections = <String, Rect>{};

    // Analyze layout to detect sections
    final blocks = recognizedText.blocks;
    if (blocks.isEmpty) return sections;

    // Header section (top 20%)
    final firstBlock = blocks.first;
    final lastBlock = blocks.last;
    final totalHeight =
        lastBlock.boundingBox.bottom - firstBlock.boundingBox.top;

    sections['header'] = BoundingRect.fromLTWH(
      firstBlock.boundingBox.left.toDouble(),
      firstBlock.boundingBox.top.toDouble(),
      firstBlock.boundingBox.width.toDouble(),
      totalHeight * 0.2,
    );

    // Body section (middle 60%)
    sections['body'] = BoundingRect.fromLTWH(
      firstBlock.boundingBox.left.toDouble(),
      firstBlock.boundingBox.top + totalHeight * 0.2,
      firstBlock.boundingBox.width.toDouble(),
      totalHeight * 0.6,
    );

    // Footer section (bottom 20%)
    sections['footer'] = BoundingRect.fromLTWH(
      firstBlock.boundingBox.left.toDouble(),
      firstBlock.boundingBox.top + totalHeight * 0.8,
      firstBlock.boundingBox.width.toDouble(),
      totalHeight * 0.2,
    );

    return sections;
  }
}

class TextElement {
  final String text;
  final Rect boundingBox;
  final double confidence;

  TextElement({
    required this.text,
    required this.boundingBox,
    required this.confidence,
  });

  @override
  String toString() => 'TextElement($text, confidence: $confidence)';
}

class BoundingRect {
  final double left;
  final double top;
  final double width;
  final double height;

  BoundingRect.fromLTWH(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;

  bool contains(double x, double y) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }
}
