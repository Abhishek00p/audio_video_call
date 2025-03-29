import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final CollectionReference _subscriptionsCollection = FirebaseFirestore
      .instance
      .collection('subscriptions');
  final CollectionReference _paymentHistoryCollection = FirebaseFirestore
      .instance
      .collection('paymentHistory');
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Get active subscription for a user
  Future<Subscription?> getActiveSubscription(String userId) async {
    try {
      final querySnapshot =
          await _subscriptionsCollection
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .where('endDate', isGreaterThan: Timestamp.now())
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Subscription.fromJson(
          querySnapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting active subscription: $e');
      return null;
    }
  }

  // Get subscription history for a user
  Future<List<Subscription>> getSubscriptionHistory(String userId) async {
    try {
      final querySnapshot =
          await _subscriptionsCollection
              .where('userId', isEqualTo: userId)
              .orderBy('startDate', descending: true)
              .get();

      return querySnapshot.docs
          .map(
            (doc) => Subscription.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  // Create a new subscription
  Future<Subscription?> createSubscription({
    required String userId,
    required SubscriptionPlanType planType,
    required double price,
    required String paymentMethod,
    required SubscriptionFeatures features,
  }) async {
    try {
      // Check if user exists
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Calculate dates based on plan type
      final now = DateTime.now();
      DateTime endDate;

      switch (planType) {
        case SubscriptionPlanType.monthly:
          endDate = DateTime(now.year, now.month + 1, now.day);
          break;
        case SubscriptionPlanType.quarterly:
          endDate = DateTime(now.year, now.month + 3, now.day);
          break;
        case SubscriptionPlanType.yearly:
          endDate = DateTime(now.year + 1, now.month, now.day);
          break;
      }

      // Create subscription document
      final subscription = Subscription(
        id: '',
        userId: userId,
        planType: planType,
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: endDate,
        price: price,
        paymentMethod: paymentMethod,
        features: features,
        lastBillingDate: now,
        nextBillingDate: endDate,
      );

      // Save to Firestore
      final docRef = await _subscriptionsCollection.add(subscription.toJson());
      final updatedSubscription = subscription.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      // Update user role to member
      await _usersCollection.doc(userId).update({
        'role': 'member',
        'subscriptionExpiryDate': endDate,
      });

      return updatedSubscription;
    } catch (e) {
      print('Error creating subscription: $e');
      return null;
    }
  }

  // Cancel a subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      final docRef = _subscriptionsCollection.doc(subscriptionId);
      final doc = await docRef.get();

      if (!doc.exists) {
        return false;
      }

      await docRef.update({'status': 'canceled', 'autoRenew': false});

      // Get the user ID from the subscription
      final subscriptionData = doc.data() as Map<String, dynamic>;
      final userId = subscriptionData['userId'];

      // Check if user has other active subscriptions
      final otherActiveSubscriptions =
          await _subscriptionsCollection
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .where('id', isNotEqualTo: subscriptionId)
              .where('endDate', isGreaterThan: Timestamp.now())
              .get();

      // If no other active subscriptions, update user role back to regular user
      if (otherActiveSubscriptions.docs.isEmpty) {
        await _usersCollection.doc(userId).update({
          'role': 'user',
          'subscriptionExpiryDate': null,
        });
      }

      return true;
    } catch (e) {
      print('Error canceling subscription: $e');
      return false;
    }
  }

  // Record a payment
  Future<Payment?> recordPayment({
    required String userId,
    required String subscriptionId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String transactionId,
    String? receiptUrl,
  }) async {
    try {
      final payment = Payment(
        id: '',
        userId: userId,
        subscriptionId: subscriptionId,
        amount: amount,
        status: PaymentStatus.successful,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        paymentDate: DateTime.now(),
        receiptUrl: receiptUrl,
      );

      final docRef = await _paymentHistoryCollection.add(payment.toJson());
      final updatedPayment = payment.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      // Update subscription's last billing date
      await _subscriptionsCollection.doc(subscriptionId).update({
        'lastBillingDate': payment.paymentDate,
      });

      return updatedPayment;
    } catch (e) {
      print('Error recording payment: $e');
      return null;
    }
  }

  // Get payment history for a user
  Future<List<Payment>> getPaymentHistory(String userId) async {
    try {
      final querySnapshot =
          await _paymentHistoryCollection
              .where('userId', isEqualTo: userId)
              .orderBy('paymentDate', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => Payment.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }
}
