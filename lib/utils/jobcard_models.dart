/// Jobcard data models matching ONA_jobcard_parser_spec.md

class ConfidenceValue<T> {
  final T? value;
  final double confidence;

  ConfidenceValue({
    required this.value,
    required this.confidence,
  });

  factory ConfidenceValue.fromJson(Map<String, dynamic> json) {
    return ConfidenceValue(
      value: json['value'] as T?,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'confidence': confidence,
    };
  }

  bool get needsVerification => confidence < 0.6;
}

class RawMaterialEntry {
  final ConfidenceValue<String> store;
  final ConfidenceValue<String> code;
  final ConfidenceValue<String> description;
  final ConfidenceValue<String> uoi;
  final ConfidenceValue<double> stdQty;
  final ConfidenceValue<double> dailyQty;

  RawMaterialEntry({
    required this.store,
    required this.code,
    required this.description,
    required this.uoi,
    required this.stdQty,
    required this.dailyQty,
  });

  factory RawMaterialEntry.fromJson(Map<String, dynamic> json) {
    return RawMaterialEntry(
      store: ConfidenceValue<String>.fromJson(json['store']),
      code: ConfidenceValue<String>.fromJson(json['code']),
      description: ConfidenceValue<String>.fromJson(json['description']),
      uoi: ConfidenceValue<String>.fromJson(json['uoi']),
      stdQty: ConfidenceValue<double>.fromJson(json['stdQty']),
      dailyQty: ConfidenceValue<double>.fromJson(json['dailyQty']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store': store.toJson(),
      'code': code.toJson(),
      'description': description.toJson(),
      'uoi': uoi.toJson(),
      'stdQty': stdQty.toJson(),
      'dailyQty': dailyQty.toJson(),
    };
  }
}

class ProductionTableRow {
  final ConfidenceValue<String> date;
  final ConfidenceValue<int> dayCounterStart;
  final ConfidenceValue<int> dayCounterEnd;
  final ConfidenceValue<int> dayActual;
  final ConfidenceValue<int> dayScrap;
  final ConfidenceValue<int> nightCounterStart;
  final ConfidenceValue<int> nightCounterEnd;
  final ConfidenceValue<int> nightActual;
  final ConfidenceValue<int> nightScrap;

  ProductionTableRow({
    required this.date,
    required this.dayCounterStart,
    required this.dayCounterEnd,
    required this.dayActual,
    required this.dayScrap,
    required this.nightCounterStart,
    required this.nightCounterEnd,
    required this.nightActual,
    required this.nightScrap,
  });

  factory ProductionTableRow.fromJson(Map<String, dynamic> json) {
    return ProductionTableRow(
      date: ConfidenceValue<String>.fromJson(json['date']),
      dayCounterStart: ConfidenceValue<int>.fromJson(json['dayCounterStart']),
      dayCounterEnd: ConfidenceValue<int>.fromJson(json['dayCounterEnd']),
      dayActual: ConfidenceValue<int>.fromJson(json['dayActual']),
      dayScrap: ConfidenceValue<int>.fromJson(json['dayScrap']),
      nightCounterStart:
          ConfidenceValue<int>.fromJson(json['nightCounterStart']),
      nightCounterEnd: ConfidenceValue<int>.fromJson(json['nightCounterEnd']),
      nightActual: ConfidenceValue<int>.fromJson(json['nightActual']),
      nightScrap: ConfidenceValue<int>.fromJson(json['nightScrap']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toJson(),
      'dayCounterStart': dayCounterStart.toJson(),
      'dayCounterEnd': dayCounterEnd.toJson(),
      'dayActual': dayActual.toJson(),
      'dayScrap': dayScrap.toJson(),
      'nightCounterStart': nightCounterStart.toJson(),
      'nightCounterEnd': nightCounterEnd.toJson(),
      'nightActual': nightActual.toJson(),
      'nightScrap': nightScrap.toJson(),
    };
  }

  double get dayScrapRate {
    final actual = dayActual.value ?? 0;
    final scrap = dayScrap.value ?? 0;
    if (actual == 0) return 0.0;
    return (scrap / actual) * 100;
  }

  double get nightScrapRate {
    final actual = nightActual.value ?? 0;
    final scrap = nightScrap.value ?? 0;
    if (actual == 0) return 0.0;
    return (scrap / actual) * 100;
  }
}

class VerificationIssue {
  final String field;
  final String reason;

  VerificationIssue({
    required this.field,
    required this.reason,
  });

  factory VerificationIssue.fromJson(Map<String, dynamic> json) {
    return VerificationIssue(
      field: json['field'] as String,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'reason': reason,
    };
  }
}

class JobcardData {
  // Required fields
  final ConfidenceValue<String> worksOrderNo;
  final ConfidenceValue<String> jobName;
  final ConfidenceValue<String> color;
  final ConfidenceValue<double> cycleWeightGrams;
  final ConfidenceValue<int> quantityToManufacture;
  final ConfidenceValue<int> dailyOutput;
  final ConfidenceValue<int> targetCycleDay;
  final ConfidenceValue<int> targetCycleNight;

  // Production table (all rows)
  final List<ProductionTableRow> productionRows;

  // Raw materials (for future use)
  final List<RawMaterialEntry> rawMaterials;

  // Metadata
  final ConfidenceValue<String> rawOcrText;
  final List<VerificationIssue> verificationNeeded;
  final ConfidenceValue<String> timestamp;

  JobcardData({
    required this.worksOrderNo,
    required this.jobName,
    required this.color,
    required this.cycleWeightGrams,
    required this.quantityToManufacture,
    required this.dailyOutput,
    required this.targetCycleDay,
    required this.targetCycleNight,
    required this.productionRows,
    required this.rawMaterials,
    required this.rawOcrText,
    required this.verificationNeeded,
    required this.timestamp,
  });

  factory JobcardData.fromJson(Map<String, dynamic> json) {
    return JobcardData(
      worksOrderNo: ConfidenceValue<String>.fromJson(json['worksOrderNo']),
      jobName: ConfidenceValue<String>.fromJson(json['jobName']),
      color: ConfidenceValue<String>.fromJson(json['color']),
      cycleWeightGrams:
          ConfidenceValue<double>.fromJson(json['cycleWeightGrams']),
      quantityToManufacture:
          ConfidenceValue<int>.fromJson(json['quantityToManufacture']),
      dailyOutput: ConfidenceValue<int>.fromJson(json['dailyOutput']),
      targetCycleDay: ConfidenceValue<int>.fromJson(json['targetCycleDay']),
      targetCycleNight: ConfidenceValue<int>.fromJson(json['targetCycleNight']),
      productionRows: (json['productionRows'] as List)
          .map((e) => ProductionTableRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawMaterials: (json['rawMaterials'] as List)
          .map((e) => RawMaterialEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawOcrText: ConfidenceValue<String>.fromJson(json['raw_ocr_text']),
      verificationNeeded: (json['verificationNeeded'] as List)
          .map((e) => VerificationIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: ConfidenceValue<String>.fromJson(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worksOrderNo': worksOrderNo.toJson(),
      'jobName': jobName.toJson(),
      'color': color.toJson(),
      'cycleWeightGrams': cycleWeightGrams.toJson(),
      'quantityToManufacture': quantityToManufacture.toJson(),
      'dailyOutput': dailyOutput.toJson(),
      'targetCycleDay': targetCycleDay.toJson(),
      'targetCycleNight': targetCycleNight.toJson(),
      'productionRows': productionRows.map((e) => e.toJson()).toList(),
      'rawMaterials': rawMaterials.map((e) => e.toJson()).toList(),
      'raw_ocr_text': rawOcrText.toJson(),
      'verificationNeeded': verificationNeeded.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toJson(),
    };
  }

  bool get hasLowConfidenceFields => verificationNeeded.isNotEmpty;

  double get overallConfidence {
    final confidences = [
      worksOrderNo.confidence,
      jobName.confidence,
      color.confidence,
      cycleWeightGrams.confidence,
      quantityToManufacture.confidence,
      dailyOutput.confidence,
    ];
    return confidences.reduce((a, b) => a + b) / confidences.length;
  }
}
