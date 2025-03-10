const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Send message API
router.post('/send', async (req, res) => {
  try {
    const { senderId, receiverId, content, jobId, jobTitle } = req.body;

    // Validate input
    if (!senderId || !receiverId || !content || !jobId || !jobTitle) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Get sender details
    const senderDoc = await db.collection('users').doc(senderId).get();
    if (!senderDoc.exists) {
      return res.status(404).json({ error: 'Sender not found' });
    }

    const senderData = senderDoc.data();
    const conversationId = [senderId, receiverId].sort().join('_');

    // Create/update conversation
    await db.collection('conversations').doc(conversationId).set({
      participants: [senderId, receiverId],
      job_id: jobId,
      job_title: jobTitle,
      last_message: content,
      last_message_time: admin.firestore.FieldValue.serverTimestamp(),
      unread_count: admin.firestore.FieldValue.increment(1),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // Create message
    const messageRef = await db.collection('messages').add({
      conversation_id: conversationId,
      sender_id: senderId,
      receiver_id: receiverId,
      content: content,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      job_id: jobId,
      sender_role: senderData.role,
      sender_name: senderData.name
    });

    // Send notification
    const receiverDoc = await db.collection('users').doc(receiverId).get();
    const receiverData = receiverDoc.data();
    
    if (receiverData?.fcm_token) {
      await admin.messaging().send({
        token: receiverData.fcm_token,
        notification: {
          title: `New message from ${senderData.name}`,
          body: content
        },
        data: {
          jobId,
          jobTitle,
          conversationId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        }
      });
    }

    res.status(200).json({ success: true, messageId: messageRef.id });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ error: error.message });
  }
});

// Mark messages as read API
router.post('/mark-read', async (req, res) => {
  try {
    const { conversationId, userId } = req.body;

    if (!conversationId || !userId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const batch = db.batch();

    const messagesSnapshot = await db.collection('messages')
      .where('conversation_id', '==', conversationId)
      .where('receiver_id', '==', userId)
      .where('read', '==', false)
      .get();

    messagesSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { read: true });
    });

    batch.update(db.collection('conversations').doc(conversationId), {
      unread_count: 0
    });

    await batch.commit();

    res.status(200).json({
      success: true,
      messagesRead: messagesSnapshot.size
    });
  } catch (error) {
    console.error('Error marking messages as read:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get conversations API
router.get('/conversations/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const conversationsSnapshot = await db.collection('conversations')
      .where('participants', 'array-contains', userId)
      .orderBy('updated_at', 'desc')
      .get();

    const conversations = [];
    
    for (const doc of conversationsSnapshot.docs) {
      const conversationData = doc.data();
      const otherParticipantId = conversationData.participants
        .find(id => id !== userId);
      
      const otherParticipantDoc = await db.collection('users')
        .doc(otherParticipantId).get();
      const otherParticipantData = otherParticipantDoc.data();

      conversations.push({
        id: doc.id,
        jobId: conversationData.job_id,
        jobTitle: conversationData.job_title,
        lastMessage: conversationData.last_message,
        lastMessageTime: conversationData.last_message_time,
        unreadCount: conversationData.unread_count,
        otherParticipant: {
          id: otherParticipantId,
          name: otherParticipantData.name,
          role: otherParticipantData.role
        }
      });
    }

    res.status(200).json({ conversations });
  } catch (error) {
    console.error('Error getting conversations:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router; 