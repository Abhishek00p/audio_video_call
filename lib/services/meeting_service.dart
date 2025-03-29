import 'dart:math';
import 'package:agora_poc/services/storage_service.dart';
import 'package:flutter/material.dart';
import '../../models/call_model.dart';
import '../../models/join_request_model.dart';
import '../../models/user_model.dart';

class MeetingService {
  final StorageService _storageService = StorageService();

  // In-memory storage for calls and requests (in a real app, this would be on the server)
  List<Call> _calls = [];
  List<Call> get calls => _calls;

  List<JoinRequest> _joinRequests = [];
  List<JoinRequest> get joinRequests => _joinRequests;

  // Initialize the service
  Future<void> initialize() async {
    await _loadCalls();
    await _loadJoinRequests();
  }

  // Load calls from storage
  Future<void> _loadCalls() async {
    final callData = await _storageService.getCalls();
    if (callData != null) {
      _calls = callData.map((json) => Call.fromJson(json)).toList();
    } else {
      _calls = [];
    }
  }

  // Load join requests from storage
  Future<void> _loadJoinRequests() async {
    final requestData = await _storageService.getJoinRequests();
    if (requestData != null) {
      _joinRequests =
          requestData.map((json) => JoinRequest.fromJson(json)).toList();
    } else {
      _joinRequests = [];
    }
  }

  // Save calls to storage
  Future<void> _saveCalls() async {
    final callData = _calls.map((call) => call.toJson()).toList();
    await _storageService.saveCalls(callData);
  }

  // Save join requests to storage
  Future<void> _saveJoinRequests() async {
    final requestData =
        _joinRequests.map((request) => request.toJson()).toList();
    await _storageService.saveJoinRequests(requestData);
  }

  // Create a new call (for members)
  Future<Call?> createCall(
    User host,
    String title, {
    String? description,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (!host.isMember) {
      // Only members can create calls
      return null;
    }

    try {
      final now = DateTime.now();

      // Generate a unique call ID and password
      final callId = _generateCallId();
      final password = _generatePassword();

      // Set default times if not provided
      final scheduledStartTime = startTime ?? now;
      final scheduledEndTime = endTime ?? now.add(const Duration(hours: 1));

      // Create the call
      final call = Call(
        id: callId,
        password: password,
        hostId: host.id,
        title: title,
        description: description,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
        participantIds: [host.id], // Add host as first participant
      );

      // Add to the list and save
      _calls.add(call);
      await _saveCalls();

      return call;
    } catch (e) {
      debugPrint('Error creating call: $e');
      return null;
    }
  }

  // Get call by ID
  Call? getCallById(String callId) {
    try {
      return _calls.firstWhere((call) => call.id == callId);
    } catch (e) {
      return null;
    }
  }

  // Get calls hosted by a user
  List<Call> getCallsByHostId(String hostId) {
    return _calls.where((call) => call.hostId == hostId).toList();
  }

  // Get calls where user is a participant
  List<Call> getCallsByParticipantId(String participantId) {
    return _calls
        .where((call) => call.participantIds.contains(participantId))
        .toList();
  }

  // Validate call ID and password
  bool validateCallCredentials(String callId, String password) {
    final call = getCallById(callId);
    if (call == null) return false;

    return call.password == password && call.canBeJoined;
  }

  // Request to join a call
  Future<JoinRequest?> requestToJoinCall(
    String callId,
    String password,
    User user,
  ) async {
    final call = getCallById(callId);
    if (call == null) return null;

    // Check if call can be joined
    if (!call.canBeJoined) {
      return null;
    }

    // Validate password
    if (call.password != password) {
      return null;
    }

    // Check if user is already a participant
    if (call.participantIds.contains(user.id)) {
      return null;
    }

    // Check if call is full
    if (call.isFull) {
      return null;
    }

    try {
      // Create join request
      final request = JoinRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        callId: callId,
        userId: user.id,
        userDisplayName: user.name,
        requestTime: DateTime.now(),
      );

      // Add to the list and save
      _joinRequests.add(request);
      await _saveJoinRequests();

      return request;
    } catch (e) {
      debugPrint('Error requesting to join call: $e');
      return null;
    }
  }

  // Get pending join requests for a call
  List<JoinRequest> getPendingJoinRequests(String callId) {
    return _joinRequests
        .where((request) => request.callId == callId && request.isPending)
        .toList();
  }

  // Approve a join request (host only)
  Future<bool> approveJoinRequest(String requestId, String hostId) async {
    try {
      // Find the request
      final requestIndex = _joinRequests.indexWhere(
        (request) => request.id == requestId,
      );
      if (requestIndex == -1) return false;

      final request = _joinRequests[requestIndex];

      // Find the call
      final callIndex = _calls.indexWhere((call) => call.id == request.callId);
      if (callIndex == -1) return false;

      final call = _calls[callIndex];

      // Check if the user is the host
      if (call.hostId != hostId) return false;

      // Update the request status
      final updatedRequest = request.copyWith(
        status: JoinRequestStatus.approved,
      );
      _joinRequests[requestIndex] = updatedRequest;

      // Add user to participants
      final updatedParticipantIds = List<String>.from(call.participantIds)
        ..add(request.userId);
      final updatedCall = call.copyWith(participantIds: updatedParticipantIds);
      _calls[callIndex] = updatedCall;

      // Save changes
      await _saveJoinRequests();
      await _saveCalls();

      return true;
    } catch (e) {
      debugPrint('Error approving join request: $e');
      return false;
    }
  }

  // Reject a join request (host only)
  Future<bool> rejectJoinRequest(
    String requestId,
    String hostId, {
    String? reason,
  }) async {
    try {
      // Find the request
      final requestIndex = _joinRequests.indexWhere(
        (request) => request.id == requestId,
      );
      if (requestIndex == -1) return false;

      final request = _joinRequests[requestIndex];

      // Find the call
      final call = getCallById(request.callId);
      if (call == null) return false;

      // Check if the user is the host
      if (call.hostId != hostId) return false;

      // Update the request status
      final updatedRequest = request.copyWith(
        status: JoinRequestStatus.rejected,
        message: reason,
      );
      _joinRequests[requestIndex] = updatedRequest;

      // Save changes
      await _saveJoinRequests();

      return true;
    } catch (e) {
      debugPrint('Error rejecting join request: $e');
      return false;
    }
  }

  // Start a call (host only)
  Future<Call?> startCall(String callId, String hostId) async {
    try {
      // Find the call
      final callIndex = _calls.indexWhere((call) => call.id == callId);
      if (callIndex == -1) return null;

      final call = _calls[callIndex];

      // Check if the user is the host
      if (call.hostId != hostId) return null;

      // Update call status
      final updatedCall = call.copyWith(
        status: CallStatus.active,
        actualStartTime: DateTime.now(),
      );
      _calls[callIndex] = updatedCall;

      // Save changes
      await _saveCalls();

      return updatedCall;
    } catch (e) {
      debugPrint('Error starting call: $e');
      return null;
    }
  }

  // End a call (host only)
  Future<Call?> endCall(String callId, String hostId) async {
    try {
      // Find the call
      final callIndex = _calls.indexWhere((call) => call.id == callId);
      if (callIndex == -1) return null;

      final call = _calls[callIndex];

      // Check if the user is the host
      if (call.hostId != hostId) return null;

      // Update call status
      final updatedCall = call.copyWith(
        status: CallStatus.completed,
        actualEndTime: DateTime.now(),
      );
      _calls[callIndex] = updatedCall;

      // Save changes
      await _saveCalls();

      return updatedCall;
    } catch (e) {
      debugPrint('Error ending call: $e');
      return null;
    }
  }

  // Extend call duration (host only)
  Future<Call?> extendCallDuration(
    String callId,
    String hostId,
    Duration extension,
  ) async {
    try {
      // Find the call
      final callIndex = _calls.indexWhere((call) => call.id == callId);
      if (callIndex == -1) return null;

      final call = _calls[callIndex];

      // Check if the user is the host
      if (call.hostId != hostId) return null;

      // Extend scheduled end time
      final updatedCall = call.copyWith(
        scheduledEndTime: call.scheduledEndTime.add(extension),
      );
      _calls[callIndex] = updatedCall;

      // Save changes
      await _saveCalls();

      return updatedCall;
    } catch (e) {
      debugPrint('Error extending call duration: $e');
      return null;
    }
  }

  // Remove a participant from a call (host only)
  Future<bool> removeParticipant(
    String callId,
    String hostId,
    String participantId,
  ) async {
    try {
      // Find the call
      final callIndex = _calls.indexWhere((call) => call.id == callId);
      if (callIndex == -1) return false;

      final call = _calls[callIndex];

      // Check if the user is the host
      if (call.hostId != hostId) return false;

      // Remove participant
      final updatedParticipantIds = List<String>.from(call.participantIds)
        ..remove(participantId);
      final updatedCall = call.copyWith(participantIds: updatedParticipantIds);
      _calls[callIndex] = updatedCall;

      // Save changes
      await _saveCalls();

      return true;
    } catch (e) {
      debugPrint('Error removing participant: $e');
      return false;
    }
  }

  // Toggle call recording (host only)
  Future<Call?> toggleCallRecording(String callId, String hostId) async {
    try {
      // Find the call
      final callIndex = _calls.indexWhere((call) => call.id == callId);
      if (callIndex == -1) return null;

      final call = _calls[callIndex];

      // Check if the user is the host
      if (call.hostId != hostId) return null;

      // Toggle recording state
      final updatedCall = call.copyWith(isRecording: !call.isRecording);
      _calls[callIndex] = updatedCall;

      // Save changes
      await _saveCalls();

      return updatedCall;
    } catch (e) {
      debugPrint('Error toggling call recording: $e');
      return null;
    }
  }

  // Generate a random 6-character call ID
  String _generateCallId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Generate a random 6-character password
  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
