import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_model.dart';
import '../models/call_participant_model.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final CollectionReference _callsCollection = FirebaseFirestore.instance
      .collection('calls');
  final CollectionReference _callParticipantsCollection = FirebaseFirestore
      .instance
      .collection('callParticipants');
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Get user participation analytics
  Future<Map<String, dynamic>> getUserParticipationAnalytics(
    String userId, {
    int daysBack = 30,
  }) async {
    try {
      final DateTime startDate = DateTime.now().subtract(
        Duration(days: daysBack),
      );
      final startTimestamp = Timestamp.fromDate(startDate);

      // Get all call participations
      final querySnapshot =
          await _callParticipantsCollection
              .where('userId', isEqualTo: userId)
              .where('joinTime', isGreaterThan: startTimestamp)
              .get();

      final participations =
          querySnapshot.docs
              .map(
                (doc) => CallParticipant.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

      // Calculate total calls and total duration
      final Set<String> uniqueCalls = {};
      int totalDurationSeconds = 0;
      int hostDurationSeconds = 0;
      int participantDurationSeconds = 0;
      int numberOfCallsAsHost = 0;

      for (final participation in participations) {
        uniqueCalls.add(participation.callId);

        final durationSec = participation.durationInSeconds ?? 0;
        totalDurationSeconds += durationSec;

        if (participation.userRole == UserRole.host) {
          hostDurationSeconds += durationSec;
          numberOfCallsAsHost++;
        } else {
          participantDurationSeconds += durationSec;
        }
      }

      return {
        'totalCalls': uniqueCalls.length,
        'totalCallsJoined': participations.length,
        'totalDurationMinutes': (totalDurationSeconds / 60).round(),
        'averageCallDurationMinutes':
            participations.isEmpty
                ? 0
                : (totalDurationSeconds / participations.length / 60).round(),
        'hostDurationMinutes': (hostDurationSeconds / 60).round(),
        'participantDurationMinutes': (participantDurationSeconds / 60).round(),
        'numberOfCallsAsHost': numberOfCallsAsHost,
        'numberOfCallsAsParticipant':
            participations.length - numberOfCallsAsHost,
      };
    } catch (e) {
      print('Error getting user participation analytics: $e');
      return {};
    }
  }

  // Get call analytics
  Future<Map<String, dynamic>> getCallAnalytics(String callId) async {
    try {
      // Get call details
      final callDoc = await _callsCollection.doc(callId).get();
      if (!callDoc.exists) {
        return {};
      }

      final call = Call.fromJson(callDoc.data() as Map<String, dynamic>);

      // Get all participants
      final querySnapshot =
          await _callParticipantsCollection
              .where('callId', isEqualTo: callId)
              .get();

      final participants =
          querySnapshot.docs
              .map(
                (doc) => CallParticipant.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

      // Calculate analytics
      final int totalParticipants = participants.length;
      int totalDurationSeconds = 0;
      int maxDurationSeconds = 0;
      int minDurationSeconds = participants.isNotEmpty ? 999999 : 0;
      final Set<String> uniqueParticipants = {};
      final Map<String, int> platformCounts = {};

      for (final participant in participants) {
        uniqueParticipants.add(participant.userId);

        final durationSec = participant.durationInSeconds ?? 0;
        totalDurationSeconds += durationSec;

        if (durationSec > maxDurationSeconds) {
          maxDurationSeconds = durationSec;
        }

        if (durationSec < minDurationSeconds && durationSec > 0) {
          minDurationSeconds = durationSec;
        }

        // Count by platform
        final platform = participant.deviceInfo.platform;
        platformCounts[platform] = (platformCounts[platform] ?? 0) + 1;
      }

      // Calculate actual call duration if available
      int? actualCallDurationMinutes;
      if (call.actualStartTime != null && call.actualEndTime != null) {
        actualCallDurationMinutes =
            call.actualEndTime!.difference(call.actualStartTime!).inMinutes;
      }

      return {
        'callTitle': call.title,
        'scheduledDurationMinutes': call.scheduledDuration.inMinutes,
        'actualDurationMinutes': actualCallDurationMinutes,
        'totalParticipants': totalParticipants,
        'uniqueParticipants': uniqueParticipants.length,
        'averageParticipationMinutes':
            totalParticipants > 0
                ? (totalDurationSeconds / totalParticipants / 60).round()
                : 0,
        'maxParticipationMinutes': (maxDurationSeconds / 60).round(),
        'minParticipationMinutes':
            minDurationSeconds == 999999
                ? 0
                : (minDurationSeconds / 60).round(),
        'platformBreakdown': platformCounts,
        'status': call.status.toString().split('.').last,
        'wasRecorded': call.recordingUrl != null,
      };
    } catch (e) {
      print('Error getting call analytics: $e');
      return {};
    }
  }

  // Get admin dashboard analytics
  Future<Map<String, dynamic>> getAdminDashboardAnalytics({
    int daysBack = 30,
  }) async {
    try {
      final DateTime startDate = DateTime.now().subtract(
        Duration(days: daysBack),
      );
      final startTimestamp = Timestamp.fromDate(startDate);

      // Get active users count
      final activeUsersSnapshot =
          await _usersCollection
              .where('isActive', isEqualTo: true)
              .count()
              .get();
      final activeUsersCount = activeUsersSnapshot.count;

      // Get members count
      final membersSnapshot =
          await _usersCollection
              .where('role', isEqualTo: 'member')
              .count()
              .get();
      final membersCount = membersSnapshot.count;

      // Get calls count in time period
      final callsSnapshot =
          await _callsCollection
              .where('scheduledStartTime', isGreaterThan: startTimestamp)
              .count()
              .get();
      final callsCount = callsSnapshot.count;

      // Get completed calls
      final completedCallsSnapshot =
          await _callsCollection
              .where('scheduledStartTime', isGreaterThan: startTimestamp)
              .where('status', isEqualTo: 'completed')
              .count()
              .get();
      final completedCallsCount = completedCallsSnapshot.count;

      // Get call duration stats (would be more complex in real app)
      final callsWithDurationSnapshot =
          await _callsCollection
              .where('scheduledStartTime', isGreaterThan: startTimestamp)
              .where('status', isEqualTo: 'completed')
              .where('actualStartTime', isNull: false)
              .where('actualEndTime', isNull: false)
              .limit(100) // Limit for performance
              .get();

      int totalCallMinutes = 0;
      for (final doc in callsWithDurationSnapshot.docs) {
        final call = Call.fromJson(doc.data() as Map<String, dynamic>);
        if (call.actualStartTime != null && call.actualEndTime != null) {
          totalCallMinutes +=
              call.actualEndTime!.difference(call.actualStartTime!).inMinutes;
        }
      }

      return {
        'activeUsers': activeUsersCount,
        'members': membersCount,
        'totalCalls': callsCount,
        'completedCalls': completedCallsCount,
        'canceledCalls': (callsCount ?? 0) - (completedCallsCount ?? 0),
        'completionRate':
            (callsCount ?? 0) > 0
                ? ((completedCallsCount ?? 0) / (callsCount ?? 0) * 100).round()
                : 0,
        'totalCallMinutes': totalCallMinutes,
        'averageCallMinutes':
            (completedCallsCount ?? 0) > 0
                ? (totalCallMinutes / (completedCallsCount ?? 0)).round()
                : 0,
        'timeframeDays': daysBack,
      };
    } catch (e) {
      print('Error getting admin dashboard analytics: $e');
      return {};
    }
  }
}
