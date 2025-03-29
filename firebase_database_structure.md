# Firebase Database Structure for Agora Voice Calling App

This document outlines the Firestore collections and their structure for the Agora Voice Calling application.

## Collections Overview

### 1. Users Collection
- Stores all user accounts (members, regular users, and admins)

### 2. Subscriptions Collection
- Tracks subscription details for members

### 3. Calls Collection
- Stores information about all voice calls/meetings

### 4. CallParticipants Collection
- Records who joined which calls and when

### 5. JoinRequests Collection
- Tracks meeting join requests and their status

### 6. PaymentHistory Collection
- Records all payment transactions for subscriptions

## Collection Structures

### Users Collection
```
users/
  {userId}/
    uid: "user123" (string)
    email: "user@example.com" (string)
    displayName: "John Doe" (string)
    phoneNumber: "+1234567890" (string)
    photoURL: "https://example.com/photo.jpg" (string, optional)
    role: "admin" | "member" | "user" (string)
    isActive: true (boolean)
    createdAt: timestamp
    lastLoginAt: timestamp
    deviceTokens: ["token1", "token2"] (array of strings, for notifications)
```

### Subscriptions Collection
```
subscriptions/
  {subscriptionId}/
    userId: "user123" (string, foreign key to users collection)
    planType: "monthly" | "quarterly" | "yearly" (string)
    status: "active" | "expired" | "canceled" | "pending" (string)
    startDate: timestamp
    endDate: timestamp
    autoRenew: true (boolean)
    price: 9.99 (number)
    currency: "USD" (string)
    paymentMethod: "credit_card" | "paypal" | "bank_transfer" (string)
    features: {
      maxCallDuration: 120 (number, in minutes),
      maxParticipants: 45 (number),
      recordingEnabled: true (boolean),
      privateChatEnabled: true (boolean)
    }
    lastBillingDate: timestamp
    nextBillingDate: timestamp
```

### Calls Collection
```
calls/
  {callId}/
    callId: "ABC123" (string, the public ID shared with users)
    password: "secret123" (string)
    hostId: "user123" (string, foreign key to users collection)
    title: "Weekly Team Meeting" (string)
    description: "Discuss project progress" (string, optional)
    scheduledStartTime: timestamp
    scheduledEndTime: timestamp
    actualStartTime: timestamp (optional)
    actualEndTime: timestamp (optional)
    status: "scheduled" | "active" | "completed" | "canceled" (string)
    maxParticipants: 45 (number)
    isRecording: false (boolean)
    recordingUrl: "https://storage.example.com/recordings/abc123.mp4" (string, optional)
    allowJoinRequests: true (boolean)
    agoraChannelName: "channel_abc123" (string)
    agoraToken: "xyz789" (string, optional)
```

### CallParticipants Collection
```
callParticipants/
  {participantId}/
    callId: "ABC123" (string, foreign key to calls collection)
    userId: "user123" (string, foreign key to users collection)
    userDisplayName: "John Doe" (string)
    userRole: "host" | "participant" (string)
    joinTime: timestamp
    leaveTime: timestamp (optional)
    durationInSeconds: 1800 (number, optional)
    deviceInfo: {
      platform: "iOS" | "Android" | "Web" (string),
      browser: "Chrome" (string, optional),
      deviceModel: "iPhone 12" (string, optional),
      ipAddress: "192.168.1.1" (string)
    }
    hasAudio: true (boolean)
    wasRemoved: false (boolean)
```

### JoinRequests Collection
```
joinRequests/
  {requestId}/
    callId: "ABC123" (string, foreign key to calls collection)
    userId: "user123" (string, foreign key to users collection)
    userDisplayName: "John Doe" (string)
    requestTime: timestamp
    status: "pending" | "approved" | "rejected" (string)
    responseTime: timestamp (optional)
    respondedBy: "user456" (string, foreign key to users collection, optional)
    message: "Please let me join the meeting" (string, optional)
```

### PaymentHistory Collection
```
paymentHistory/
  {paymentId}/
    userId: "user123" (string, foreign key to users collection)
    subscriptionId: "sub456" (string, foreign key to subscriptions collection)
    amount: 9.99 (number)
    currency: "USD" (string)
    status: "successful" | "failed" | "refunded" (string)
    paymentMethod: "credit_card" | "paypal" | "bank_transfer" (string)
    transactionId: "tx789" (string)
    paymentDate: timestamp
    receiptUrl: "https://example.com/receipts/tx789" (string, optional)
```

## Firebase Rules

Here's a basic security rules configuration for the database:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and update their own profile
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow create, delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Only admins can manage subscriptions
    match /subscriptions/{subscriptionId} {
      allow read: if request.auth != null && 
                   (request.auth.uid == resource.data.userId || 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Call access rules
    match /calls/{callId} {
      // Anyone can read call details
      allow read: if request.auth != null;
      // Only members can create calls
      allow create: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'member';
      // Only the host or admin can update/delete calls
      allow update, delete: if request.auth != null && 
                             (resource.data.hostId == request.auth.uid || 
                              get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Call participants tracking
    match /callParticipants/{participantId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      // Only the participant themselves or an admin can update leave time
      allow update: if request.auth != null && 
                     (resource.data.userId == request.auth.uid || 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Join requests
    match /joinRequests/{requestId} {
      // Participants can create join requests for themselves
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      // Users can read their own requests, hosts can read requests for their calls
      allow read: if request.auth != null && 
                   (resource.data.userId == request.auth.uid || 
                    get(/databases/$(database)/documents/calls/$(resource.data.callId)).data.hostId == request.auth.uid || 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      // Only the host or admin can update request status
      allow update: if request.auth != null && 
                     (get(/databases/$(database)/documents/calls/$(resource.data.callId)).data.hostId == request.auth.uid || 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Payment history
    match /paymentHistory/{paymentId} {
      // Users can read their own payment history, admins can read all
      allow read: if request.auth != null && 
                   (resource.data.userId == request.auth.uid || 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      // Only admins can create/update payment records
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Indexes

Recommended indexes for common queries:

```
// Find all active calls for a user
calls: status (ascending), scheduledStartTime (ascending)

// Find all participants for a specific call
callParticipants: callId (ascending), joinTime (ascending)

// Find all pending join requests for a call
joinRequests: callId (ascending), status (ascending), requestTime (ascending)

// Find active subscriptions
subscriptions: status (ascending), endDate (ascending)
```

## Cloud Functions Integration

Recommended Cloud Functions to implement:

1. **subscriptionStatusUpdate**: Automatically update subscription status when end date is reached
2. **callStatusUpdate**: Update call status based on scheduled times
3. **calculateParticipantDuration**: Calculate and update duration when a participant leaves
4. **sendJoinRequestNotification**: Notify host when someone requests to join
5. **generateAgoraToken**: Create and update Agora tokens before meetings
6. **processPayment**: Handle payment processing and update subscription status
7. **sendReminderEmails**: Send meeting reminders to participants