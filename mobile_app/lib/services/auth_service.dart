import 'storage_service.dart';

class AuthService {
  final StorageService _storageService;

  AuthService(this._storageService);

  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final isValid = await _storageService.validateCredentials(cleanEmail, password);
    
    if (isValid) {
      await _storageService.setActiveUser(cleanEmail);
      return true;
    }
    return false;
  }

  Future<void> signup(String email, String password, String name) async {
    final cleanEmail = email.trim().toLowerCase();
    
    // Check if user already exists
    final exists = await _storageService.userExists(cleanEmail);
    if (!exists) {
      await _storageService.registerUser(cleanEmail, password);
    } else {
      // Update password if they sign up again with the same email
      await _storageService.registerUser(cleanEmail, password);
    }
    
    // Set them as active user
    await _storageService.setActiveUser(cleanEmail);
    
    // Save their display name under their isolated profile
    await _storageService.saveUserName(name.trim());
  }

  Future<void> logout() async {
    await _storageService.logout();
  }

  Future<bool> isAuthenticated() async {
    return await _storageService.isLoggedIn();
  }
}
