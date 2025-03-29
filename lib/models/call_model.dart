enum CallStatus { scheduled, active, completed, canceled }

class Call {
  final String id;
  final String password;
  final String hostId;
  final String title;
  final String? description;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final CallStatus status;
  final List<String> participantIds;
  final int maxParticipants;
  final bool isRecording;
  final String? recordingUrl;
  final bool allowJoinRequests;

  Call({
    required this.id,
    required this.password,
    required this.hostId,
    required this.title,
    this.description,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    this.status = CallStatus.scheduled,
    this.participantIds = const [],
    this.maxParticipants = 45,
    this.isRecording = false,
    this.recordingUrl,
    this.allowJoinRequests = true,
  });

  bool get isActive => status == CallStatus.active;
  bool get isScheduled => status == CallStatus.scheduled;
  bool get isCompleted => status == CallStatus.completed;
  bool get isCanceled => status == CallStatus.canceled;

  bool get canBeJoined => isScheduled || isActive;
  bool get isFull => participantIds.length >= maxParticipants;

  Duration get scheduledDuration =>
      scheduledEndTime.difference(scheduledStartTime);

  Duration? get actualDuration =>
      actualEndTime != null && actualStartTime != null
          ? actualEndTime!.difference(actualStartTime!)
          : null;

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'],
      password: json['password'],
      hostId: json['hostId'],
      title: json['title'],
      description: json['description'],
      scheduledStartTime: DateTime.parse(json['scheduledStartTime']),
      scheduledEndTime: DateTime.parse(json['scheduledEndTime']),
      actualStartTime:
          json['actualStartTime'] != null
              ? DateTime.parse(json['actualStartTime'])
              : null,
      actualEndTime:
          json['actualEndTime'] != null
              ? DateTime.parse(json['actualEndTime'])
              : null,
      status: CallStatus.values.firstWhere(
        (status) => status.toString() == 'CallStatus.${json['status']}',
        orElse: () => CallStatus.scheduled,
      ),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      maxParticipants: json['maxParticipants'] ?? 45,
      isRecording: json['isRecording'] ?? false,
      recordingUrl: json['recordingUrl'],
      allowJoinRequests: json['allowJoinRequests'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'password': password,
      'hostId': hostId,
      'title': title,
      'description': description,
      'scheduledStartTime': scheduledStartTime.toIso8601String(),
      'scheduledEndTime': scheduledEndTime.toIso8601String(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'participantIds': participantIds,
      'maxParticipants': maxParticipants,
      'isRecording': isRecording,
      'recordingUrl': recordingUrl,
      'allowJoinRequests': allowJoinRequests,
    };
  }

  Call copyWith({
    String? id,
    String? password,
    String? hostId,
    String? title,
    String? description,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    CallStatus? status,
    List<String>? participantIds,
    int? maxParticipants,
    bool? isRecording,
    String? recordingUrl,
    bool? allowJoinRequests,
  }) {
    return Call(
      id: id ?? this.id,
      password: password ?? this.password,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      status: status ?? this.status,
      participantIds: participantIds ?? this.participantIds,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isRecording: isRecording ?? this.isRecording,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      allowJoinRequests: allowJoinRequests ?? this.allowJoinRequests,
    );
  }
}
