enum SubscriptionPlanType { monthly, quarterly, yearly }

enum SubscriptionStatus { active, expired, canceled, pending }

class Subscription {
  final String id;
  final String userId;
  final SubscriptionPlanType planType;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final double price;
  final String currency;
  final String paymentMethod;
  final SubscriptionFeatures features;
  final DateTime? lastBillingDate;
  final DateTime? nextBillingDate;

  Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.autoRenew = true,
    required this.price,
    this.currency = 'USD',
    required this.paymentMethod,
    required this.features,
    this.lastBillingDate,
    this.nextBillingDate,
  });

  bool get isActive =>
      status == SubscriptionStatus.active && DateTime.now().isBefore(endDate);

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['userId'],
      planType: SubscriptionPlanType.values.firstWhere(
        (type) => type.toString() == 'SubscriptionPlanType.${json['planType']}',
        orElse: () => SubscriptionPlanType.monthly,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (status) => status.toString() == 'SubscriptionStatus.${json['status']}',
        orElse: () => SubscriptionStatus.pending,
      ),
      startDate: (json['startDate'] as dynamic).toDate(),
      endDate: (json['endDate'] as dynamic).toDate(),
      autoRenew: json['autoRenew'] ?? true,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      paymentMethod: json['paymentMethod'],
      features: SubscriptionFeatures.fromJson(json['features']),
      lastBillingDate:
          json['lastBillingDate'] != null
              ? (json['lastBillingDate'] as dynamic).toDate()
              : null,
      nextBillingDate:
          json['nextBillingDate'] != null
              ? (json['nextBillingDate'] as dynamic).toDate()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planType': planType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startDate': startDate,
      'endDate': endDate,
      'autoRenew': autoRenew,
      'price': price,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'features': features.toJson(),
      'lastBillingDate': lastBillingDate,
      'nextBillingDate': nextBillingDate,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlanType? planType,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
    double? price,
    String? currency,
    String? paymentMethod,
    SubscriptionFeatures? features,
    DateTime? lastBillingDate,
    DateTime? nextBillingDate,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoRenew: autoRenew ?? this.autoRenew,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      features: features ?? this.features,
      lastBillingDate: lastBillingDate ?? this.lastBillingDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    );
  }
}

class SubscriptionFeatures {
  final int maxCallDuration; // in minutes
  final int maxParticipants;
  final bool recordingEnabled;
  final bool privateChatEnabled;

  SubscriptionFeatures({
    required this.maxCallDuration,
    required this.maxParticipants,
    required this.recordingEnabled,
    required this.privateChatEnabled,
  });

  factory SubscriptionFeatures.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeatures(
      maxCallDuration: json['maxCallDuration'] ?? 60,
      maxParticipants: json['maxParticipants'] ?? 10,
      recordingEnabled: json['recordingEnabled'] ?? false,
      privateChatEnabled: json['privateChatEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxCallDuration': maxCallDuration,
      'maxParticipants': maxParticipants,
      'recordingEnabled': recordingEnabled,
      'privateChatEnabled': privateChatEnabled,
    };
  }
}
