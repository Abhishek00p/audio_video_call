import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/call_model.dart';
import '../models/join_request_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference _subscriptionsCollection = FirebaseFirestore
      .instance
      .collection('subscriptions');
  final CollectionReference _callsCollection = FirebaseFirestore.instance
      .collection('calls');
  final CollectionReference _callParticipantsCollection = FirebaseFirestore
      .instance
      .collection('callParticipants');
  final CollectionReference _joinRequestsCollection = FirebaseFirestore.instance
      .collection('joinRequests');
  final CollectionReference _paymentHistoryCollection = FirebaseFirestore
      .instance
      .collection('paymentHistory');

  // User methods
  Future<User?> getCurrentUser() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return null;

    try {
      final userDoc = await _usersCollection.doc(authUser.uid).get();
      if (userDoc.exists) {
        return User.fromJson(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        return User.fromJson(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(User user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Subscription methods
  Future<bool> checkActiveSubscription(String userId) async {
    try {
      final querySnapshot =
          await _subscriptionsCollection
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .where('endDate', isGreaterThan: Timestamp.now())
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  // Call methods
  Future<Call?> createCall(Call call) async {
    try {
      final docRef = await _callsCollection.add(call.toJson());
      final updatedCall = call.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});
      return updatedCall;
    } catch (e) {
      print('Error creating call: $e');
      return null;
    }
  }

  Future<Call?> getCallById(String callId) async {
    try {
      final callDoc = await _callsCollection.doc(callId).get();
      if (callDoc.exists) {
        return Call.fromJson(callDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting call by ID: $e');
      return null;
    }
  }

  Future<List<Call>> getCallsByHostId(String hostId) async {
    try {
      final querySnapshot =
          await _callsCollection
              .where('hostId', isEqualTo: hostId)
              .orderBy('scheduledStartTime', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => Call.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting calls by host ID: $e');
      return [];
    }
  }

  Future<bool> updateCallStatus(String callId, CallStatus status) async {
    try {
      await _callsCollection.doc(callId).update({
        'status': status.toString().split('.').last,
        if (status == CallStatus.active)
          'actualStartTime': FieldValue.serverTimestamp(),
        if (status == CallStatus.completed)
          'actualEndTime': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating call status: $e');
      return false;
    }
  }

  // Call participants tracking
  Future<void> trackParticipantJoin(
    String callId,
    String userId,
    String userDisplayName,
  ) async {
    try {
      await _callParticipantsCollection.add({
        'callId': callId,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userRole':
            userId == (await getCallById(callId))?.hostId
                ? 'host'
                : 'participant',
        'joinTime': FieldValue.serverTimestamp(),
        'hasAudio': true,
        'wasRemoved': false,
        'deviceInfo': {'platform': getPlatform()},
      });
    } catch (e) {
      print('Error tracking participant join: $e');
    }
  }

  Future<void> trackParticipantLeave(String callId, String userId) async {
    try {
      final querySnapshot =
          await _callParticipantsCollection
              .where('callId', isEqualTo: callId)
              .where('userId', isEqualTo: userId)
              .where('leaveTime', isNull: true)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final participantId = querySnapshot.docs.first.id;
        final joinTime = querySnapshot.docs.first['joinTime'] as Timestamp;
        final leaveTime = Timestamp.now();
        final durationInSeconds = leaveTime.seconds - joinTime.seconds;

        await _callParticipantsCollection.doc(participantId).update({
          'leaveTime': leaveTime,
          'durationInSeconds': durationInSeconds,
        });
      }
    } catch (e) {
      print('Error tracking participant leave: $e');
    }
  }

  // Join requests
  Future<JoinRequest?> createJoinRequest(
    String callId,
    String userId,
    String userDisplayName, {
    String? message,
  }) async {
    try {
      final request = JoinRequest(
        id: '',
        callId: callId,
        userId: userId,
        userDisplayName: userDisplayName,
        requestTime: DateTime.now(),
        message: message,
      );

      final docRef = await _joinRequestsCollection.add(request.toJson());
      final updatedRequest = request.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      return updatedRequest;
    } catch (e) {
      print('Error creating join request: $e');
      return null;
    }
  }

  Future<List<JoinRequest>> getPendingJoinRequestsForCall(String callId) async {
    try {
      final querySnapshot =
          await _joinRequestsCollection
              .where('callId', isEqualTo: callId)
              .where('status', isEqualTo: 'pending')
              .orderBy('requestTime')
              .get();

      return querySnapshot.docs
          .map(
            (doc) => JoinRequest.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting pending join requests: $e');
      return [];
    }
  }

  Future<bool> updateJoinRequestStatus(
    String requestId,
    JoinRequestStatus status,
    String respondedBy,
  ) async {
    try {
      await _joinRequestsCollection.doc(requestId).update({
        'status': status.toString().split('.').last,
        'responseTime': FieldValue.serverTimestamp(),
        'respondedBy': respondedBy,
      });

      // If approved, add user to call participants
      if (status == JoinRequestStatus.approved) {
        final request = await _joinRequestsCollection.doc(requestId).get();
        final requestData = request.data() as Map<String, dynamic>;

        // Update the call's participant list
        final callDoc = await _callsCollection.doc(requestData['callId']).get();
        final callData = callDoc.data() as Map<String, dynamic>;
        List<String> participants = List<String>.from(
          callData['participantIds'] ?? [],
        );

        if (!participants.contains(requestData['userId'])) {
          participants.add(requestData['userId']);
          await _callsCollection.doc(requestData['callId']).update({
            'participantIds': participants,
          });
        }
      }

      return true;
    } catch (e) {
      print('Error updating join request status: $e');
      return false;
    }
  }

  // Helper methods
  String getPlatform() {
    // In a real app, determine the platform and return 'iOS', 'Android', 'Web', etc.
    return 'unknown';
  }
}
