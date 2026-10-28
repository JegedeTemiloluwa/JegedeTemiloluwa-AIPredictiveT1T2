import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';

class ApiService {
  static const String _baseUrl = 'https://jegedetemiloluwa-aipredictivet1t2.onrender.com';

  Future<PredictionResponse> predict(PredictionRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 200) {
        return PredictionResponse.fromJson(jsonDecode(response.body));
      } else {
        String errorMessage = 'Server Error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (_) {
      // If the server is unreachable, return a demo response so the app doesn't crash
      return PredictionResponse(
        diagnosis: 'Demo',
        stage: 'Stage 1',
        confidence: {'Demo': 100.0},
        recommendation: 'This is a demo prediction – no real model was contacted.',
        scientificDisclaimer: null,
        timestamp: DateTime.now(),
        modelVersion: 'offline-demo',
      );
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/info'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] != 'Offline';
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
