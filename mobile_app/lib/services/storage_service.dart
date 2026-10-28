import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prediction_model.dart';

class StorageService {
  static const String _usersDataKey = 'auth_users_data';
  static const String _activeUserEmailKey = 'active_user_email';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _isLoggedInKey = 'auth_is_logged_in';

  // --- Core Methods ---
  
  Future<String?> getActiveUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeUserEmailKey);
  }

  Future<String> _getUserKeyPrefix() async {
    final email = await getActiveUserEmail() ?? 'default';
    return '${email}_';
  }

  // --- Prediction History (Isolated per User) ---
  
  Future<void> savePrediction(PredictionResponse prediction) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = await _getUserKeyPrefix();
    final key = '${prefix}prediction_history';
    
    final List<String> history = prefs.getStringList(key) ?? [];
    history.insert(0, jsonEncode(prediction.toJson()));
    
    if (history.length > 20) {
      history.removeLast();
    }
    
    await prefs.setStringList(key, history);
  }

  Future<List<PredictionResponse>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = await _getUserKeyPrefix();
    final key = '${prefix}prediction_history';
    
    final List<String> history = prefs.getStringList(key) ?? [];
    return history.map((item) => PredictionResponse.fromJson(jsonDecode(item))).toList();
  }

  // --- User Profile (Isolated per User) ---
  
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = await _getUserKeyPrefix();
    await prefs.setString('${prefix}user_name', name);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = await _getUserKeyPrefix();
    return prefs.getString('${prefix}user_name');
  }

  // --- Global App State ---
  
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  // --- Authentication State (Multi-Account) ---
  
  Future<void> registerUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersDataKey) ?? '{}';
    final Map<String, dynamic> users = jsonDecode(usersJson);
    
    users[email] = {
      'password': password,
    };
    
    await prefs.setString(_usersDataKey, jsonEncode(users));
  }

  Future<bool> validateCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersDataKey) ?? '{}';
    final Map<String, dynamic> users = jsonDecode(usersJson);
    
    if (users.containsKey(email)) {
      return users[email]['password'] == password;
    }
    return false;
  }
  
  Future<bool> userExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersDataKey) ?? '{}';
    final Map<String, dynamic> users = jsonDecode(usersJson);
    return users.containsKey(email);
  }

  Future<void> setActiveUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeUserEmailKey, email);
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserEmailKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}
