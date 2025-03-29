enum JoinRequestStatus { pending, approved, rejected }

class JoinRequest {
  final String id;
  final String callId;
  final String userId;
  final String userDisplayName;
  final DateTime requestTime;
  final JoinRequestStatus status;
  final String? message;

  JoinRequest({
    required this.id,
    required this.callId,
    required this.userId,
    required this.userDisplayName,
    required this.requestTime,
    this.status = JoinRequestStatus.pending,
    this.message,
  });

  bool get isPending => status == JoinRequestStatus.pending;
  bool get isApproved => status == JoinRequestStatus.approved;
  bool get isRejected => status == JoinRequestStatus.rejected;

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'],
      callId: json['callId'],
      userId: json['userId'],
      userDisplayName: json['userDisplayName'],
      requestTime: DateTime.parse(json['requestTime']),
      status: JoinRequestStatus.values.firstWhere(
        (status) => status.toString() == 'JoinRequestStatus.${json['status']}',
        orElse: () => JoinRequestStatus.pending,
      ),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callId': callId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'requestTime': requestTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'message': message,
    };
  }

  JoinRequest copyWith({
    String? id,
    String? callId,
    String? userId,
    String? userDisplayName,
    DateTime? requestTime,
    JoinRequestStatus? status,
    String? message,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      requestTime: requestTime ?? this.requestTime,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}
