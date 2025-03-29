enum PaymentStatus { successful, failed, refunded }

enum PaymentMethod { credit_card, paypal, bank_transfer }

class Payment {
  final String id;
  final String userId;
  final String subscriptionId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethod paymentMethod;
  final String transactionId;
  final DateTime paymentDate;
  final String? receiptUrl;

  Payment({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.paymentDate,
    this.receiptUrl,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      userId: json['userId'],
      subscriptionId: json['subscriptionId'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: PaymentStatus.values.firstWhere(
        (status) => status.toString() == 'PaymentStatus.${json['status']}',
        orElse: () => PaymentStatus.failed,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (method) =>
            method.toString() == 'PaymentMethod.${json['paymentMethod']}',
        orElse: () => PaymentMethod.credit_card,
      ),
      transactionId: json['transactionId'],
      paymentDate: (json['paymentDate'] as dynamic).toDate(),
      receiptUrl: json['receiptUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'transactionId': transactionId,
      'paymentDate': paymentDate,
      'receiptUrl': receiptUrl,
    };
  }

  Payment copyWith({
    String? id,
    String? userId,
    String? subscriptionId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    String? transactionId,
    DateTime? paymentDate,
    String? receiptUrl,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      paymentDate: paymentDate ?? this.paymentDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}
