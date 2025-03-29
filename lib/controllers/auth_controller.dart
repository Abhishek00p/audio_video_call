import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthService {
  final StorageService _storageService = StorageService();

  // Mock API URL - in a real app, this would be your backend API
  // For this POC, we're simulating the backend responses
  final String _baseUrl = 'https://api.example.com';

  // In-memory OTP storage (in a real app, this would be on the server)
  final Map<String, String> _otpStore = {};

  // Current logged in user
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Auth state stream
  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Method to check if the user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    final userData = await _storageService.getUserData();

    if (token != null && userData != null) {
      _currentUser = User.fromJson(userData);
      _authStateController.add(_currentUser);
      return true;
    }
    return false;
  }

  // Login method
  Future<User?> login(String email, String password) async {
    // Simulate API call
    try {
      // In a real app, send request to your backend
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/login'),
      //   body: {'email': email, 'password': password},
      // );

      // For POC, simulate successful response
      await Future.delayed(const Duration(seconds: 1));

      // Create a mock user
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test User',
        email: email,
        phoneNumber: '+1234567890',
        role:
            email.contains('admin')
                ? UserRole.admin
                : email.contains('member')
                ? UserRole.member
                : UserRole.user,
      );

      // Generate and store OTP
      final otp = _generateOTP();
      _otpStore[email] = otp;

      // In a real app, the OTP would be sent via SMS or email
      debugPrint('OTP for $email: $otp');

      // Return the user without fully authenticating (waiting for OTP verification)
      return user;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // Register method
  Future<User?> register(
    String name,
    String email,
    String password,
    String phoneNumber,
  ) async {
    // Simulate API call
    try {
      // In a real app, send request to your backend
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/register'),
      //   body: {
      //     'name': name,
      //     'email': email,
      //     'password': password,
      //     'phoneNumber': phoneNumber,
      //   },
      // );

      // For POC, simulate successful response
      await Future.delayed(const Duration(seconds: 1));

      // Create a mock user
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: UserRole.user, // New registrations are regular users by default
      );

      // Generate and store OTP
      final otp = _generateOTP();
      _otpStore[email] = otp;

      // In a real app, the OTP would be sent via SMS or email
      debugPrint('OTP for $email: $otp');

      // Return the user without fully authenticating (waiting for OTP verification)
      return user;
    } catch (e) {
      debugPrint('Registration error: $e');
      return null;
    }
  }

  // OTP verification method
  Future<bool> verifyOTP(String email, String otp) async {
    // Check if OTP matches
    final storedOTP = _otpStore[email];
    if (storedOTP == null || storedOTP != otp) {
      return false;
    }

    // Simulate API call for OTP verification
    try {
      // In a real app, send request to your backend
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/verify-otp'),
      //   body: {'email': email, 'otp': otp},
      // );

      // For POC, simulate successful response
      await Future.delayed(const Duration(seconds: 1));

      // Mock response data
      final userData = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Test User',
        'email': email,
        'phoneNumber': '+1234567890',
        'role':
            email.contains('admin')
                ? 'admin'
                : email.contains('member')
                ? 'member'
                : 'user',
        'isActive': true,
        'subscriptionExpiryDate':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };

      final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

      // Save user data and token
      await _storageService.saveUserData(userData);
      await _storageService.saveToken(token);

      // Update current user
      _currentUser = User.fromJson(userData);
      _authStateController.add(_currentUser);

      // Clear OTP
      _otpStore.remove(email);

      return true;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    await _storageService.removeUserData();
    await _storageService.deleteToken();
    _currentUser = null;
    _authStateController.add(null);
  }

  // Generate a random 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Dispose method to clean up resources
  void dispose() {
    _authStateController.close();
  }
}
