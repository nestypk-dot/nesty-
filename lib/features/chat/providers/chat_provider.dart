import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────

class ChatConversation {
  final String id;
  final String guestId;
  final String guestName;
  final String guestAvatar;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final List<String> participants;
  final int unreadCount;
  final String? lastSenderId;

  ChatConversation({
    required this.id,
    required this.guestId,
    required this.guestName,
    required this.guestAvatar,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.participants,
    this.unreadCount = 0,
    this.lastSenderId,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json, String docId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final unreadMap = json['unreadCount'] as Map<String, dynamic>? ?? {};
    final unread = (unreadMap[currentUid] ?? 0) as int;

    return ChatConversation(
      id: docId,
      guestId: json['guestId'] ?? '',
      guestName: json['guestName'] ?? '',
      guestAvatar: json['guestAvatar'] ?? '',
      hostId: json['hostId'] ?? '',
      hostName: json['hostName'] ?? '',
      hostAvatar: json['hostAvatar'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? (json['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      participants: List<String>.from(json['participants'] ?? []),
      unreadCount: unread,
      lastSenderId: json['lastSenderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guestId': guestId,
      'guestName': guestName,
      'guestAvatar': guestAvatar,
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'participants': participants,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime time;
  final String type; // 'text', 'image', 'voice'
  final String? imageUrl;
  final bool isRead;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar = '',
    required this.text,
    required this.time,
    this.type = 'text',
    this.imageUrl,
    this.isRead = false,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String docId) {
    return ChatMessage(
      id: docId,
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderAvatar: json['senderAvatar'] ?? '',
      text: json['text'] ?? '',
      time: json['time'] != null
          ? (json['time'] as Timestamp).toDate()
          : DateTime.now(),
      type: json['type'] ?? 'text',
      imageUrl: json['imageUrl'],
      isRead: json['isRead'] ?? false,
      replyToId: json['replyToId'],
      replyToText: json['replyToText'],
      replyToSender: json['replyToSender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'text': text,
      'time': Timestamp.fromDate(time),
      'type': type,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
    };
  }
}

class CallSession {
  final String id;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final String status;
  final String type;
  final DateTime createdAt;

  CallSession({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  factory CallSession.fromJson(Map<String, dynamic> json, String docId) {
    return CallSession(
      id: docId,
      callerId: json['callerId'] ?? '',
      callerName: json['callerName'] ?? '',
      callerAvatar: json['callerAvatar'] ?? '',
      receiverId: json['receiverId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      receiverAvatar: json['receiverAvatar'] ?? '',
      status: json['status'] ?? 'ringing',
      type: json['type'] ?? 'audio',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'status': status,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class NotificationAlert {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String category;
  final bool isRead;

  NotificationAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.category,
    required this.isRead,
  });

  factory NotificationAlert.fromJson(Map<String, dynamic> json, String docId) {
    return NotificationAlert(
      id: docId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      category: json['category'] ?? 'system',
      isRead: json['isRead'] ?? false,
    );
  }
}

// ─────────────────────────────────────────────
// CONNECTION ITEM MODEL
// ─────────────────────────────────────────────

class ConnectionItem {
  final String id;
  final String name;
  final String role;
  final String location;
  final double rating;
  final int reviewsCount;
  final String connectedSince;
  final String imageUrl;
  final bool isOnline;
  final bool isVerified;
  final String? lastActive;

  ConnectionItem({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.rating,
    required this.reviewsCount,
    required this.connectedSince,
    required this.imageUrl,
    this.isOnline = false,
    this.isVerified = false,
    this.lastActive,
  });
}

// ─────────────────────────────────────────────
// CHAT SERVICE
// ─────────────────────────────────────────────

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Watch all conversations for current user, ordered by most recent
  Stream<List<ChatConversation>> watchConversations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            final userDoc = await _db.collection('users').doc(user.uid).get();
            final myName = userDoc.exists ? (userDoc.data()?['name'] ?? 'User') : 'User';
            final myAvatar = userDoc.exists ? (userDoc.data()?['photoUrl'] ?? '') : '';
            final myRole = userDoc.exists ? (userDoc.data()?['role'] ?? 'guest') : 'guest';

            final now = DateTime.now();
            final mockPeers = [
              {
                'uid': 'user_rehman',
                'name': 'Abdur Rehman',
                'role': 'host',
                'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150',
                'lastMsg': 'Good',
                'lastMsgTime': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
              },
              {
                'uid': 'user_haad',
                'name': 'Muhammad Haad',
                'role': 'guest',
                'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150',
                'lastMsg': 'Abdullah bhai',
                'lastMsgTime': Timestamp.fromDate(now.subtract(const Duration(days: 8, hours: 3))),
              },
              {
                'uid': 'user_ayesha',
                'name': 'Ayesha Khan',
                'role': 'guest',
                'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150',
                'lastMsg': '+jj',
                'lastMsgTime': Timestamp.fromDate(now.subtract(const Duration(days: 13))),
              },
            ];

            final batch = _db.batch();

            for (final peer in mockPeers) {
              final peerId = peer['uid'] as String;
              final peerName = peer['name'] as String;
              final peerAvatar = peer['avatar'] as String;
              final peerRole = peer['role'] as String;
              final lastMsg = peer['lastMsg'] as String;
              final lastMsgTime = peer['lastMsgTime'] as Timestamp;

              String guestId, guestName, guestAvatar;
              String hostId, hostName, hostAvatar;

              // Assign guest/host roles correctly
              if (myRole == 'host' || (myRole != 'host' && peerRole == 'host')) {
                if (myRole == 'host') {
                  hostId = user.uid;
                  hostName = myName;
                  hostAvatar = myAvatar;
                  guestId = peerId;
                  guestName = peerName;
                  guestAvatar = peerAvatar;
                } else {
                  guestId = user.uid;
                  guestName = myName;
                  guestAvatar = myAvatar;
                  hostId = peerId;
                  hostName = peerName;
                  hostAvatar = peerAvatar;
                }
              } else {
                guestId = user.uid;
                guestName = myName;
                guestAvatar = myAvatar;
                hostId = peerId;
                hostName = peerName;
                hostAvatar = peerAvatar;
              }

              final chatId = 'chat_${user.uid}_$peerId';

              batch.set(_db.collection('chats').doc(chatId), {
                'guestId': guestId,
                'guestName': guestName,
                'guestAvatar': guestAvatar,
                'hostId': hostId,
                'hostName': hostName,
                'hostAvatar': hostAvatar,
                'lastMessage': lastMsg,
                'lastMessageTime': lastMsgTime,
                'participants': [user.uid, peerId],
                'lastSenderId': peerId,
                'unreadCount': {user.uid: 0, peerId: 0},
                'createdAt': lastMsgTime,
              });

              // Seed the message in the subcollection
              final msgId = 'msg_${chatId}_1';
              batch.set(_db.collection('chats').doc(chatId).collection('messages').doc(msgId), {
                'senderId': peerId,
                'senderName': peerName,
                'senderAvatar': peerAvatar,
                'text': lastMsg,
                'time': lastMsgTime,
                'type': 'text',
                'imageUrl': null,
                'isRead': true,
              });
            }

            await batch.commit();

            final newSnap = await _db
                .collection('chats')
                .where('participants', arrayContains: user.uid)
                .get();

            final list = newSnap.docs
                .map((doc) => ChatConversation.fromJson(doc.data(), doc.id))
                .toList();
            list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
            return list;
          }

          final list = snapshot.docs
              .map((doc) => ChatConversation.fromJson(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return list;
        });
  }

  // Watch messages in a conversation
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _db
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  // Watch notifications for current user
  Stream<List<NotificationAlert>> watchNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            final batch = _db.batch();
            final now = DateTime.now();
            final mockNotifs = [
              {
                'userId': user.uid,
                'title': 'Get 15% off Swat! 🏔️',
                'description': 'Enjoy a premium vacation in Swat valley with discount coupon code: NESTYSWAT15.',
                'category': 'promo',
                'isRead': false,
                'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
              },
              {
                'userId': user.uid,
                'title': 'Rate your stay! ⭐',
                'description': 'How was your recent stay at Mountain View Resort? Tap to write a review.',
                'category': 'review',
                'isRead': false,
                'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
              },
              {
                'userId': user.uid,
                'title': 'Booking Confirmed! 📅',
                'description': 'Your stay at Margalla Hill View has been confirmed by host Abdur Rehman.',
                'category': 'booking',
                'isRead': false,
                'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
              },
              {
                'userId': user.uid,
                'title': 'Payment Successful! 💳',
                'description': 'We have received your payment of PKR 12,000 for your stay.',
                'category': 'booking',
                'isRead': false,
                'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1, hours: 1))),
              },
              {
                'userId': user.uid,
                'title': 'Identity Verified! ✅',
                'description': 'Congratulations! Your identity document has been verified.',
                'category': 'system',
                'isRead': false,
                'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
              },
              {
                'userId': user.uid,
                'title': 'New Message from Host 💬',
                'description': 'Check out local recommendations for Islamabad from Abdur Rehman.',
                'category': 'system',
                'isRead': false,
                'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2, hours: 2))),
              },
              {
                'userId': user.uid,
                'title': 'Security Alert 🔒',
                'description': 'A new login was detected from a Windows device.',
                'category': 'system',
                'isRead': false,
                'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
              },
              {
                'userId': user.uid,
                'title': 'Welcome to Nesty! 🏡',
                'description': 'Explore verified rental properties across Swat, Kalam, Malam Jabba, and Islamabad.',
                'category': 'booking',
                'isRead': true,
                'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
              }
            ];

            for (int i = 0; i < mockNotifs.length; i++) {
              final n = mockNotifs[i];
              final docRef = _db.collection('notifications').doc('notif_seed_${user.uid}_$i');
              batch.set(docRef, n);
            }
            await batch.commit();

            final newSnap = await _db
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .get();
            return newSnap.docs
                .map((doc) => NotificationAlert.fromJson(doc.data(), doc.id))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          final list = snapshot.docs
              .map((doc) => NotificationAlert.fromJson(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> markNotificationAsRead(String docId) async {
    await _db.collection('notifications').doc(docId).update({'isRead': true});
  }

  // Get total unread messages count for badge
  Stream<int> watchTotalUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);
    final uid = user.uid;

    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final unreadMap =
                doc.data()['unreadCount'] as Map<String, dynamic>? ?? {};
            total += ((unreadMap[uid] ?? 0) as num).toInt();
          }
          return total;
        });
  }

  // Calling system backend integration
  Future<String> startCall({
    required String receiverId,
    required String receiverName,
    required String receiverAvatar,
    required String type,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    // Fetch current user's details for caller profile
    final userDoc = await _db.collection('users').doc(currentUser.uid).get();
    final myName = userDoc.exists ? (userDoc.data()?['name'] ?? 'User') : 'User';
    final myAvatar = userDoc.exists ? (userDoc.data()?['photoUrl'] ?? '') : '';

    final callDoc = _db.collection('calls').doc();
    final call = CallSession(
      id: callDoc.id,
      callerId: currentUser.uid,
      callerName: myName,
      callerAvatar: myAvatar,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      status: 'ringing',
      type: type,
      createdAt: DateTime.now(),
    );

    await callDoc.set(call.toJson());
    return callDoc.id;
  }

  Future<void> updateCallStatus(String callId, String status) async {
    await _db.collection('calls').doc(callId).update({
      'status': status,
    });
  }

  Stream<CallSession?> watchCall(String callId) {
    return _db.collection('calls').doc(callId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CallSession.fromJson(snap.data()!, snap.id);
    });
  }

  Stream<CallSession?> watchIncomingCall() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db
        .collection('calls')
        .where('receiverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'ringing')
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return CallSession.fromJson(snap.docs.first.data(), snap.docs.first.id);
        });
  }

  // Get or create a conversation between current user and peer
  Future<String> getOrCreateConversation({
    required String peerId,
    required String peerName,
    required String peerImageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final currentUid = currentUser.uid;

    // Check if a conversation already exists between these two users
    final query = await _db
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .get();

    for (final doc in query.docs) {
      final participants =
          List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(peerId)) {
        return doc.id;
      }
    }

    // Fetch current user details
    final userDoc = await _db.collection('users').doc(currentUid).get();
    final myName =
        userDoc.exists ? (userDoc.data()?['name'] ?? 'User') : 'User';
    final myAvatar =
        userDoc.exists ? (userDoc.data()?['photoUrl'] ?? '') : '';
    final myRole =
        userDoc.exists ? (userDoc.data()?['role'] ?? 'guest') : 'guest';

    // Fetch peer details from Firestore to get their role
    final peerDoc = await _db.collection('users').doc(peerId).get();
    final peerRole =
        peerDoc.exists ? (peerDoc.data()?['role'] ?? 'guest') : 'guest';

    String guestId, guestName, guestAvatar;
    String hostId, hostName, hostAvatar;

    // Assign guest/host roles correctly
    if (myRole == 'host' || (myRole != 'host' && peerRole == 'host')) {
      // Current user is host, peer is guest
      if (myRole == 'host') {
        hostId = currentUid;
        hostName = myName;
        hostAvatar = myAvatar;
        guestId = peerId;
        guestName = peerName;
        guestAvatar = peerImageUrl;
      } else {
        // peer is host
        guestId = currentUid;
        guestName = myName;
        guestAvatar = myAvatar;
        hostId = peerId;
        hostName = peerName;
        hostAvatar = peerImageUrl;
      }
    } else {
      // Both guests - current user is "guest", peer is "host" for structure
      guestId = currentUid;
      guestName = myName;
      guestAvatar = myAvatar;
      hostId = peerId;
      hostName = peerName;
      hostAvatar = peerImageUrl;
    }

    final newChatDoc = await _db.collection('chats').add({
      'guestId': guestId,
      'guestName': guestName,
      'guestAvatar': guestAvatar,
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [currentUid, peerId],
      'lastSenderId': '',
      'unreadCount': {currentUid: 0, peerId: 0},
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newChatDoc.id;
  }

  // Send a message and update conversation metadata
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String type = 'text',
    String? imageUrl,
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userDoc = await _db.collection('users').doc(currentUser.uid).get();
    final senderName =
        userDoc.exists ? (userDoc.data()?['name'] ?? 'User') : 'User';
    final senderAvatar =
        userDoc.exists ? (userDoc.data()?['photoUrl'] ?? '') : '';

    final messageData = {
      'senderId': currentUser.uid,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'text': text,
      'time': FieldValue.serverTimestamp(),
      'type': type,
      'imageUrl': imageUrl,
      'isRead': false,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
    };

    // Add message to subcollection
    await _db
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .add(messageData);

    // Get conversation doc to find peer UID
    final convDoc =
        await _db.collection('chats').doc(conversationId).get();
    final participants =
        List<String>.from(convDoc.data()?['participants'] ?? []);
    final peerUid =
        participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');

    // Update conversation metadata + increment unread count for peer
    final Map<String, dynamic> updateData = {
      'lastMessage': type == 'image' ? '📷 Photo' : type == 'voice' ? '🎤 Voice message' : text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUser.uid,
    };

    if (peerUid.isNotEmpty) {
      updateData['unreadCount.$peerUid'] = FieldValue.increment(1);
    }

    await _db
        .collection('chats')
        .doc(conversationId)
        .update(updateData);

    // Clear typing indicator after sending
    await setTyping(conversationId, false);
  }

  // Set typing indicator for current user in a conversation
  Future<void> setTyping(String conversationId, bool isTyping) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      await _db.collection('chats').doc(conversationId).update({
        'typing.${currentUser.uid}': isTyping,
      });
    } catch (_) {}
  }

  // Watch typing status of the peer in a conversation
  Stream<bool> watchPeerTyping(String conversationId, String peerUid) {
    return _db
        .collection('chats')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
          final typingMap =
              doc.data()?['typing'] as Map<String, dynamic>? ?? {};
          return (typingMap[peerUid] ?? false) as bool;
        });
  }

  // Mark all messages in a conversation as read for current user
  Future<void> markConversationAsRead(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _db.collection('chats').doc(conversationId).update({
      'unreadCount.${currentUser.uid}': 0,
    });

    // Mark individual messages as read
    final unreadMessages = await _db
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUser.uid)
        .get();

    final batch = _db.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    final messagesRef = _db
        .collection('chats')
        .doc(conversationId)
        .collection('messages');
    final messages = await messagesRef.get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('chats').doc(conversationId));
    await batch.commit();
  }

  // Upload an image file to Firebase Storage and get download URL
  Future<String> uploadChatImage(String conversationId, String filePath) async {
    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child(conversationId)
        .child(fileName);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}

// ─────────────────────────────────────────────
// PRESENCE SERVICE
// ─────────────────────────────────────────────

class PresenceService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Mark current user as online in Firestore
  Future<void> setOnline() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Mark current user as offline in Firestore
  Future<void> setOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService();
});

final conversationsProvider =
    StreamProvider<List<ChatConversation>>((ref) {
  return ref.watch(chatServiceProvider).watchConversations();
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  return ref.watch(chatServiceProvider).watchMessages(conversationId);
});

final notificationsProvider =
    StreamProvider<List<NotificationAlert>>((ref) {
  return ref.watch(chatServiceProvider).watchNotifications();
});

final totalUnreadCountProvider = StreamProvider<int>((ref) {
  return ref.watch(chatServiceProvider).watchTotalUnreadCount();
});

/// Watches whether the given [peerUid] is currently typing in [conversationId].
final peerTypingProvider =
    StreamProvider.family<bool, ({String conversationId, String peerUid})>(
  (ref, args) => ref
      .watch(chatServiceProvider)
      .watchPeerTyping(args.conversationId, args.peerUid),
);

// ─────────────────────────────────────────────
// USERS / CONNECTIONS PROVIDER (Firebase)
// ─────────────────────────────────────────────


final usersProvider = StreamProvider<List<ConnectionItem>>((ref) {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  return auth.authStateChanges().asyncExpand((user) {
    if (user == null) return Stream.value(<ConnectionItem>[]);

    return db.collection('users').snapshots().map((snapshot) {
      // Check if we need to seed mock users
      if (snapshot.docs.isEmpty || (snapshot.docs.length == 1 && snapshot.docs.first.id == user.uid)) {
        Future.microtask(() async {
          final batch = db.batch();
          final mockUsers = [
            {
              'uid': 'user_ayesha',
              'name': 'Ayesha Khan',
              'email': 'ayesha@gmail.com',
              'phone': '+923001234567',
              'location': 'Lahore, Punjab',
              'role': 'guest',
              'rating': 4.9,
              'reviewsCount': 12,
              'isApproved': true,
              'isOnline': true,
              'photoUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150',
              'createdAt': Timestamp.now(),
              'lastSeen': Timestamp.now(),
            },
            {
              'uid': 'user_rehman',
              'name': 'Abdur Rehman',
              'email': 'rehman@gmail.com',
              'phone': '+923124567890',
              'location': 'Islamabad, ICT',
              'role': 'host',
              'rating': 4.8,
              'reviewsCount': 24,
              'isApproved': true,
              'isOnline': false,
              'photoUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150',
              'createdAt': Timestamp.now(),
              'lastSeen': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 42))),
            },
            {
              'uid': 'user_haad',
              'name': 'Muhammad Haad',
              'email': 'haad@gmail.com',
              'phone': '+923219876543',
              'location': 'Karachi, Sindh',
              'role': 'guest',
              'rating': 4.7,
              'reviewsCount': 6,
              'isApproved': true,
              'isOnline': true,
              'photoUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150',
              'createdAt': Timestamp.now(),
              'lastSeen': Timestamp.now(),
            }
          ];

          for (final u in mockUsers) {
            if (u['uid'] == user.uid) continue;
            final docRef = db.collection('users').doc(u['uid'] as String);
            batch.set(docRef, u);
          }
          await batch.commit();
        });
      }

      final list = <ConnectionItem>[];
      for (final doc in snapshot.docs) {
        if (doc.id == user.uid) continue; // Skip current user
        final data = doc.data();
        final name = data['name'] ?? 'User';
        final roleStr = data['role'] ?? 'guest';
        final isSubmitted = data['isSubmitted'] ?? false;
        final location = data['location'] ?? 'Pakistan';
        final rating = (data['rating'] ?? 4.5).toDouble();
        final reviewsCount = (data['reviewsCount'] ?? 0).toInt();
        final isOnline = data['isOnline'] ?? false;
        final isVerified = data['isApproved'] ?? false;
        final storedPhoto = data['photoUrl'] ?? '';
        final photoUrl = storedPhoto.isNotEmpty
            ? storedPhoto
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=00674F&color=fff&size=150';

        String roleBadge = 'Guest';
        if (roleStr == 'host' || isSubmitted == true) {
          final isSuperhost = data['isSuperhost'] ?? false;
          roleBadge = isSuperhost ? 'Superhost' : 'Host';
        }

        list.add(ConnectionItem(
          id: doc.id,
          name: name,
          role: roleBadge,
          location: location,
          rating: rating,
          reviewsCount: reviewsCount,
          connectedSince: _getTimeSince(data['createdAt']),
          imageUrl: photoUrl,
          isOnline: isOnline,
          isVerified: isVerified,
          lastActive: _getLastActiveTime(data['lastSeen']),
        ));
      }
      list.sort((a, b) {
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        if (a.role.contains('Host') && !b.role.contains('Host')) return -1;
        if (!a.role.contains('Host') && b.role.contains('Host')) return 1;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  });
});

String _getTimeSince(dynamic timestamp) {
  if (timestamp == null) return 'Recently';
  try {
    final date = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  } catch (_) {
    return 'Recently';
  }
}

String _getLastActiveTime(dynamic timestamp) {
  if (timestamp == null) return 'Offline';
  try {
    final date = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Active just now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    return 'Active recently';
  } catch (_) {
    return 'Offline';
  }
}

final incomingCallProvider = StreamProvider<CallSession?>((ref) {
  return ref.watch(chatServiceProvider).watchIncomingCall();
});

final singleCallProvider = StreamProvider.family<CallSession?, String>((ref, callId) {
  return ref.watch(chatServiceProvider).watchCall(callId);
});
