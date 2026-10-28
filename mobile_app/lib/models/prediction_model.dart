class PredictionRequest {
  final double glucose;
  final double bloodPressure;
  final double insulin;
  final double bmi;
  final double age;
  final double hbA1c;
  final int hypertension;
  final int heartDisease;
  final int smoking;
  final int gender;

  PredictionRequest({
    required this.glucose,
    required this.bloodPressure,
    required this.insulin,
    required this.bmi,
    required this.age,
    required this.hbA1c,
    required this.hypertension,
    required this.heartDisease,
    required this.smoking,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'Glucose': glucose,
      'BloodPressure': bloodPressure,
      'Insulin': insulin,
      'BMI': bmi,
      'Age': age,
      'HbA1c': hbA1c,
      'Hypertension': hypertension,
      'HeartDisease': heartDisease,
      'Smoking': smoking,
      'Gender': gender,
    };
  }
}

class PredictionResponse {
  final String diagnosis;
  final String stage;
  final Map<String, double> confidence;
  final String recommendation;
  final String? scientificDisclaimer;
  final String? modelVersion;
  final DateTime timestamp;

  PredictionResponse({
    required this.diagnosis,
    required this.stage,
    required this.confidence,
    required this.recommendation,
    this.scientificDisclaimer,
    this.modelVersion,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      diagnosis: json['diagnosis'] ?? 'Unknown',
      stage: json['stage'] ?? 'Unknown',
      confidence: (json['confidence'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ?? {},
      recommendation: json['recommendation'] ?? '',
      scientificDisclaimer: json['disclaimer'],
      modelVersion: json['model_version']?.toString(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diagnosis': diagnosis,
      'stage': stage,
      'confidence': confidence,
      'recommendation': recommendation,
      'disclaimer': scientificDisclaimer,
      'model_version': modelVersion,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
