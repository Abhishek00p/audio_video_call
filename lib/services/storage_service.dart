import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _callsKey = 'calls';
  static const String _joinRequestsKey = 'join_requests';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Secure storage methods for sensitive data
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // SharedPreferences methods for non-sensitive data
  Future<void> saveData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data is String) {
      await prefs.setString(key, data);
    } else if (data is bool) {
      await prefs.setBool(key, data);
    } else if (data is int) {
      await prefs.setInt(key, data);
    } else if (data is double) {
      await prefs.setDouble(key, data);
    } else if (data is List<String>) {
      await prefs.setStringList(key, data);
    } else {
      await prefs.setString(key, jsonEncode(data));
    }
  }

  Future<dynamic> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }

  Future<void> removeData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }

  // User specific methods
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await saveData(_userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userData = await getData(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<void> removeUserData() async {
    await removeData(_userKey);
  }

  // Call specific methods
  Future<void> saveCalls(List<Map<String, dynamic>> calls) async {
    await saveData(_callsKey, jsonEncode(calls));
  }

  Future<List<Map<String, dynamic>>?> getCalls() async {
    final callsData = await getData(_callsKey);
    if (callsData != null) {
      final List<dynamic> decodedCalls = jsonDecode(callsData);
      return decodedCalls.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Join request specific methods
  Future<void> saveJoinRequests(List<Map<String, dynamic>> requests) async {
    await saveData(_joinRequestsKey, jsonEncode(requests));
  }

  Future<List<Map<String, dynamic>>?> getJoinRequests() async {
    final requestsData = await getData(_joinRequestsKey);
    if (requestsData != null) {
      final List<dynamic> decodedRequests = jsonDecode(requestsData);
      return decodedRequests.cast<Map<String, dynamic>>();
    }
    return null;
  }
}
