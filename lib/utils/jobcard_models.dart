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

class JobcardCounters {
  final ConfidenceValue<int> dayCounter;
  final ConfidenceValue<int> dayActual;
  final ConfidenceValue<int> dayScrap;
  final ConfidenceValue<int> nightCounter;
  final ConfidenceValue<int> nightActual;
  final ConfidenceValue<int> nightScrap;

  JobcardCounters({
    required this.dayCounter,
    required this.dayActual,
    required this.dayScrap,
    required this.nightCounter,
    required this.nightActual,
    required this.nightScrap,
  });

  factory JobcardCounters.fromJson(Map<String, dynamic> json) {
    return JobcardCounters(
      dayCounter: ConfidenceValue<int>.fromJson(json['dayCounter']),
      dayActual: ConfidenceValue<int>.fromJson(json['dayActual']),
      dayScrap: ConfidenceValue<int>.fromJson(json['dayScrap']),
      nightCounter: ConfidenceValue<int>.fromJson(json['nightCounter']),
      nightActual: ConfidenceValue<int>.fromJson(json['nightActual']),
      nightScrap: ConfidenceValue<int>.fromJson(json['nightScrap']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayCounter': dayCounter.toJson(),
      'dayActual': dayActual.toJson(),
      'dayScrap': dayScrap.toJson(),
      'nightCounter': nightCounter.toJson(),
      'nightActual': nightActual.toJson(),
      'nightScrap': nightScrap.toJson(),
    };
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
  final ConfidenceValue<String> worksOrderNo;
  final ConfidenceValue<String> barcode;
  final ConfidenceValue<String> fgCode;
  final ConfidenceValue<String> dateStarted;
  final ConfidenceValue<int> quantityToManufacture;
  final ConfidenceValue<int> dailyOutput;
  final ConfidenceValue<int> cycleTimeSeconds;
  final ConfidenceValue<double> cycleWeightGrams;
  final ConfidenceValue<int> cavity;
  final List<RawMaterialEntry> rawMaterials;
  final JobcardCounters counters;
  final ConfidenceValue<String> rawOcrText;
  final List<VerificationIssue> verificationNeeded;
  final ConfidenceValue<String> timestamp;

  JobcardData({
    required this.worksOrderNo,
    required this.barcode,
    required this.fgCode,
    required this.dateStarted,
    required this.quantityToManufacture,
    required this.dailyOutput,
    required this.cycleTimeSeconds,
    required this.cycleWeightGrams,
    required this.cavity,
    required this.rawMaterials,
    required this.counters,
    required this.rawOcrText,
    required this.verificationNeeded,
    required this.timestamp,
  });

  factory JobcardData.fromJson(Map<String, dynamic> json) {
    return JobcardData(
      worksOrderNo: ConfidenceValue<String>.fromJson(json['worksOrderNo']),
      barcode: ConfidenceValue<String>.fromJson(json['barcode']),
      fgCode: ConfidenceValue<String>.fromJson(json['fgCode']),
      dateStarted: ConfidenceValue<String>.fromJson(json['dateStarted']),
      quantityToManufacture:
          ConfidenceValue<int>.fromJson(json['quantityToManufacture']),
      dailyOutput: ConfidenceValue<int>.fromJson(json['dailyOutput']),
      cycleTimeSeconds: ConfidenceValue<int>.fromJson(json['cycleTimeSeconds']),
      cycleWeightGrams:
          ConfidenceValue<double>.fromJson(json['cycleWeightGrams']),
      cavity: ConfidenceValue<int>.fromJson(json['cavity']),
      rawMaterials: (json['rawMaterials'] as List)
          .map((e) => RawMaterialEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      counters: JobcardCounters.fromJson(json['counters']),
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
      'barcode': barcode.toJson(),
      'fgCode': fgCode.toJson(),
      'dateStarted': dateStarted.toJson(),
      'quantityToManufacture': quantityToManufacture.toJson(),
      'dailyOutput': dailyOutput.toJson(),
      'cycleTimeSeconds': cycleTimeSeconds.toJson(),
      'cycleWeightGrams': cycleWeightGrams.toJson(),
      'cavity': cavity.toJson(),
      'rawMaterials': rawMaterials.map((e) => e.toJson()).toList(),
      'counters': counters.toJson(),
      'raw_ocr_text': rawOcrText.toJson(),
      'verificationNeeded': verificationNeeded.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toJson(),
    };
  }

  bool get hasLowConfidenceFields => verificationNeeded.isNotEmpty;

  double get overallConfidence {
    final confidences = [
      worksOrderNo.confidence,
      fgCode.confidence,
      dateStarted.confidence,
      quantityToManufacture.confidence,
      dailyOutput.confidence,
      cycleTimeSeconds.confidence,
    ];
    return confidences.reduce((a, b) => a + b) / confidences.length;
  }
}
