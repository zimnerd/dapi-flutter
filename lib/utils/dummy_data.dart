import '../models/conversation.dart';
import '../models/profile.dart';
import '../models/message.dart';
import '../models/user.dart';

class DummyData {
  static List<Profile> getProfiles() {
    return [
      Profile(
        id: 1,
        name: 'Emma Johnson',
        age: 27,
        gender: 'Female',
        bio: 'Adventure seeker and coffee lover. Love to travel and explore new places.',
        photoUrls: ['assets/images/profile1.jpg', 'assets/images/profile1_2.jpg'],
        occupation: 'Photographer',
        location: 'New York, NY',
        interests: ['Travel', 'Photography', 'Hiking'],
        isOnline: true,
        birthDate: DateTime.now().subtract(Duration(days: 365 * 27)),
      ),
      Profile(
        id: 2,
        name: 'Michael',
        age: 28,
        bio: 'Coffee enthusiast, dog lover',
        occupation: 'Software Engineer',
        birthDate: DateTime(1992, 9, 23),
        gender: 'male',
        location: 'New York',
        interests: ['coding', 'coffee', 'dogs'],
        photoUrls: ['assets/images/user_placeholder.png'],
      ),
      Profile(
        id: 3,
        name: 'Emma',
        age: 25,
        bio: 'Yoga instructor and foodie',
        occupation: 'Yoga Instructor',
        birthDate: DateTime(1995, 3, 18),
        gender: 'female',
        location: 'Los Angeles',
        interests: ['yoga', 'cooking', 'meditation'],
        photoUrls: ['assets/images/user_placeholder.png'],
      ),
      Profile(
        id: 4,
        name: 'David',
        age: 32,
        bio: 'Music lover and amateur guitarist',
        occupation: 'Music Producer',
        birthDate: DateTime(1991, 11, 5),
        gender: 'male',
        location: 'Austin',
        interests: ['music', 'guitar', 'concerts'],
        photoUrls: ['assets/images/user_placeholder.png'],
      ),
    ];
  }

  static List<Conversation> getConversations() {
    final profiles = getProfiles();
    final DateTime now = DateTime.now();
    
    List<User> createParticipantsFromProfile(Profile profile) {
      return [
        User(
          id: "currentUser",
          email: "user@example.com",
          name: "Current User",
        ),
        User(
          id: profile.id.toString(),
          email: "${profile.name.toLowerCase()}@example.com",
          name: profile.name,
        )
      ];
    }
    
    return [
      Conversation(
        id: 'conv1',
        participants: createParticipantsFromProfile(profiles[0]),
        lastMessage: Message(
          id: 'msg1',
          conversationId: 'conv1',
          senderId: 'user1',
          text: 'Hey there! How are you doing today?',
          timestamp: now.subtract(Duration(hours: 1)),
          status: MessageStatus.sent,
        ),
        createdAt: now.subtract(Duration(days: 2)),
        updatedAt: now.subtract(Duration(hours: 1)),
        unreadCount: 0,
      ),
      Conversation(
        id: 'conv2',
        participants: createParticipantsFromProfile(profiles[1]),
        lastMessage: Message(
          id: 'msg2',
          conversationId: 'conv2',
          senderId: profiles[1].id.toString(),
          text: 'That hiking spot looks amazing!',
          timestamp: now.subtract(Duration(hours: 2)),
          status: MessageStatus.sent,
        ),
        createdAt: now.subtract(Duration(days: 3)),
        updatedAt: now.subtract(Duration(hours: 2)),
        unreadCount: 0,
      ),
      Conversation(
        id: 'conv3',
        participants: createParticipantsFromProfile(profiles[2]),
        lastMessage: Message(
          id: 'msg3',
          conversationId: 'conv3',
          senderId: "currentUser",
          text: 'Thanks for the restaurant recommendation',
          timestamp: now.subtract(Duration(days: 1)),
          status: MessageStatus.sent,
        ),
        createdAt: now.subtract(Duration(days: 5)),
        updatedAt: now.subtract(Duration(days: 1)),
        unreadCount: 0,
      ),
      Conversation(
        id: 'conv4',
        participants: createParticipantsFromProfile(profiles[3]),
        lastMessage: Message(
          id: 'msg4',
          conversationId: 'conv4',
          senderId: profiles[3].id.toString(),
          text: 'Have you been to that new concert venue?',
          timestamp: now.subtract(Duration(days: 3)),
          status: MessageStatus.sent,
        ),
        createdAt: now.subtract(Duration(days: 7)),
        updatedAt: now.subtract(Duration(days: 3)),
        unreadCount: 0,
      ),
    ];
  }

  static List<Message> getMessages(String conversationId) {
    final DateTime now = DateTime.now();
    
    switch (conversationId) {
      case 'conv1':
        return [
          Message(
            id: 'msg1',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text: 'Hey there! How are you?',
            timestamp: now.subtract(Duration(minutes: 30)),
            status: MessageStatus.sent,
          ),
          Message(
            id: '2',
            conversationId: conversationId,
            senderId: 'user1',
            text: 'Thanks! I liked yours too. What do you do for fun?',
            timestamp: now.subtract(Duration(days: 1, hours: 1, minutes: 45)),
            status: MessageStatus.read,
          ),
          Message(
            id: '3',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text: 'I love hiking and trying new coffee shops. What about you?',
            timestamp: now.subtract(Duration(days: 1, hours: 1, minutes: 30)),
            status: MessageStatus.sent,
          ),
          Message(
            id: '4',
            conversationId: conversationId,
            senderId: 'user1',
            text: 'I enjoy photography and watching movies.',
            timestamp: now.subtract(Duration(days: 1, hours: 1)),
            status: MessageStatus.read,
          ),
          Message(
            id: '5',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text: 'Would you like to grab coffee sometime?',
            timestamp: now.subtract(Duration(minutes: 30)),
            status: MessageStatus.sent,
          ),
        ];
      case 'conv2':
        return [
          Message(
            id: '1',
            conversationId: conversationId,
            senderId: 'user2',
            text: 'Hey, I saw you like hiking too!',
            timestamp: now.subtract(Duration(days: 2, hours: 4)),
            status: MessageStatus.read,
          ),
          Message(
            id: '2',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text: 'Yes! I try to go at least once a month.',
            timestamp: now.subtract(Duration(days: 2, hours: 3)),
            status: MessageStatus.sent,
          ),
          Message(
            id: '3',
            conversationId: conversationId,
            senderId: 'user2',
            text: 'Have you been to Eagle Peak?',
            timestamp: now.subtract(Duration(days: 2, hours: 2)),
            status: MessageStatus.read,
          ),
          Message(
            id: '4',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text: 'No, but I\'ve heard it\'s beautiful! I\'ll have to check it out.',
            timestamp: now.subtract(Duration(days: 2, hours: 1)),
            status: MessageStatus.sent,
          ),
          Message(
            id: '5',
            conversationId: conversationId,
            senderId: 'user2',
            text: 'That hiking spot looks amazing!',
            timestamp: now.subtract(Duration(hours: 2)),
            status: MessageStatus.read,
          ),
        ];
      default:
        return [];
    }
  }

  static List<Profile> getMatches() {
    final allProfiles = getProfiles();
    
    return allProfiles.take(3).toList();
  }
} 