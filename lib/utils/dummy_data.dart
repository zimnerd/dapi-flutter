import '../models/conversation.dart';
import '../models/profile.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/match.dart';
import '../utils/logger.dart';

class DummyData {
  static final Logger _logger = Logger('DummyData');

  static List<Profile> getProfiles() {
    final List<Profile> dummyProfiles = [
      Profile(
        id: '1',
        name: 'Sarah Johnson',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 28)),
        gender: 'female',
        photoUrls: ['https://example.com/photo1.jpg'],
        interests: ['Travel', 'Photography', 'Coffee'],
        location: {'city': 'New York', 'country': 'USA'},
        bio: 'Adventure seeker and coffee lover',
        prompts: [
          {'question': 'Favorite place', 'answer': 'Paris, France'},
          {
            'question': 'Perfect date',
            'answer': 'Coffee and a walk in the park'
          },
        ],
        isVerified: true,
        profilePictures: ['https://example.com/photo1.jpg'],
        isPremium: false,
        lastActive: DateTime.now(),
      ),
      Profile(
        id: '2',
        name: 'James Smith',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 32)),
        gender: 'male',
        photoUrls: ['https://example.com/photo2.jpg'],
        interests: ['Music', 'Cooking', 'Hiking'],
        location: {'city': 'Los Angeles', 'country': 'USA'},
        bio: 'Music lover and foodie',
        prompts: [
          {'question': 'Favorite food', 'answer': 'Italian cuisine'},
          {'question': 'Hobby', 'answer': 'Playing guitar'},
        ],
        isVerified: true,
        profilePictures: ['https://example.com/photo2.jpg'],
        isPremium: true,
        lastActive: DateTime.now(),
      ),
      // Add more dummy profiles as needed
    ];

    return dummyProfiles;
  }

  static List<Conversation> getConversations() {
    final profiles = getProfiles();
    final DateTime now = DateTime.now();

    // Ensure we have enough profiles to create conversations
    if (profiles.length < 4) {
      _logger.info('Not enough profiles, adding dummy profiles');
      // Add more dummy profiles if needed
      profiles.addAll([
        Profile(
          id: 'dummy1',
          name: 'Emma Williams',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 27)),
          gender: 'female',
          photoUrls: ['https://example.com/photo3.jpg'],
          interests: ['Reading', 'Yoga', 'Art'],
          location: {'city': 'Chicago', 'country': 'USA'},
          bio: 'Bookworm and yoga enthusiast',
          prompts: [
            {'question': 'Favorite book', 'answer': 'Pride and Prejudice'},
            {'question': 'Hobby', 'answer': 'Painting landscapes'},
          ],
          isVerified: true,
          profilePictures: ['https://example.com/photo3.jpg'],
          isPremium: false,
          lastActive: DateTime.now(),
        ),
        Profile(
          id: 'dummy2',
          name: 'Michael Brown',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
          gender: 'male',
          photoUrls: ['https://example.com/photo4.jpg'],
          interests: ['Running', 'Technology', 'Movies'],
          location: {'city': 'San Francisco', 'country': 'USA'},
          bio: 'Tech enthusiast and film buff',
          prompts: [
            {
              'question': 'Favorite movie',
              'answer': 'The Shawshank Redemption'
            },
            {'question': 'Hobby', 'answer': 'Building apps'},
          ],
          isVerified: true,
          profilePictures: ['https://example.com/photo4.jpg'],
          isPremium: true,
          lastActive: DateTime.now(),
        ),
        Profile(
          id: 'dummy3',
          name: 'Olivia Davis',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
          gender: 'female',
          photoUrls: ['https://example.com/photo5.jpg'],
          interests: ['Music', 'Travel', 'Food'],
          location: {'city': 'Seattle', 'country': 'USA'},
          bio: 'Music lover and foodie',
          prompts: [
            {'question': 'Favorite cuisine', 'answer': 'Italian'},
            {'question': 'Dream destination', 'answer': 'Japan'},
          ],
          isVerified: true,
          profilePictures: ['https://example.com/photo5.jpg'],
          isPremium: false,
          lastActive: DateTime.now(),
        ),
        Profile(
          id: 'dummy4',
          name: 'William Johnson',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 29)),
          gender: 'male',
          photoUrls: ['https://example.com/photo6.jpg'],
          interests: ['Fitness', 'Gaming', 'Cooking'],
          location: {'city': 'Austin', 'country': 'USA'},
          bio: 'Gym enthusiast and amateur chef',
          prompts: [
            {'question': 'Favorite game', 'answer': 'The Witcher 3'},
            {'question': 'Specialty dish', 'answer': 'Homemade pasta'},
          ],
          isVerified: true,
          profilePictures: ['https://example.com/photo6.jpg'],
          isPremium: true,
          lastActive: DateTime.now(),
        ),
      ]);
    }

    // Safety check - ensure we have at least 4 profiles after adding dummies
    if (profiles.isEmpty) {
      _logger.error('ERROR: No profiles available for conversations');
      return [];
    }

    List<User> createParticipantsFromProfile(Profile profile) {
      return [
        User(
          id: "currentUser",
          email: "user@example.com",
          name: "Current User",
        ),
        User(
          id: profile.id.toString(),
          email:
              "${profile.name.toLowerCase().replaceAll(' ', '.')}@example.com",
          name: profile.name,
        )
      ];
    }

    // Get safe profiles - use modulo to ensure we never go out of bounds
    final int profileCount = profiles.length;
    _logger.info('Creating conversations with $profileCount profiles');

    final Profile profile0 = profiles[0 % profileCount];
    final Profile profile1 = profiles[1 % profileCount];
    final Profile profile2 = profiles[2 % profileCount];
    final Profile profile3 = profiles[3 % profileCount];

    // Create conversations
    return [
      Conversation(
        id: 'conv1',
        participants: createParticipantsFromProfile(profile0),
        lastMessage: Message(
          id: 'msg1',
          conversationId: 'conv1',
          senderId: 'user1',
          text: 'Hey there! How are you doing today?',
          timestamp: now.subtract(Duration(hours: 1)),
          status: MessageStatus.sent,
          isRead: false,
          createdAt: now.subtract(Duration(hours: 1)),
          updatedAt: now.subtract(Duration(hours: 1)),
        ),
        createdAt: now.subtract(Duration(days: 2)),
        updatedAt: now.subtract(Duration(hours: 1)),
        unreadCount: 0,
      ),
      Conversation(
        id: 'conv2',
        participants: createParticipantsFromProfile(profile1),
        lastMessage: Message(
          id: 'msg2',
          conversationId: 'conv2',
          senderId: profile1.id.toString(),
          text: 'That hiking spot looks amazing!',
          timestamp: now.subtract(Duration(hours: 2)),
          status: MessageStatus.sent,
          isRead: false,
          createdAt: now.subtract(Duration(hours: 2)),
          updatedAt: now.subtract(Duration(hours: 2)),
        ),
        createdAt: now.subtract(Duration(days: 3)),
        updatedAt: now.subtract(Duration(hours: 2)),
        unreadCount: 0,
      ),
      Conversation(
        id: 'conv3',
        participants: createParticipantsFromProfile(profile2),
        lastMessage: Message(
          id: 'msg3',
          conversationId: 'conv3',
          senderId: "currentUser",
          text: 'Thanks for the restaurant recommendation',
          timestamp: now.subtract(Duration(days: 1)),
          status: MessageStatus.sent,
          isRead: false,
          createdAt: now.subtract(Duration(days: 1)),
          updatedAt: now.subtract(Duration(days: 1)),
        ),
        createdAt: now.subtract(Duration(days: 5)),
        updatedAt: now.subtract(Duration(days: 1)),
        unreadCount: 0,
      ),
      Conversation(
        id: 'conv4',
        participants: createParticipantsFromProfile(profile3),
        lastMessage: Message(
          id: 'msg4',
          conversationId: 'conv4',
          senderId: profile3.id.toString(),
          text: 'Have you been to that new concert venue?',
          timestamp: now.subtract(Duration(days: 3)),
          status: MessageStatus.sent,
          isRead: false,
          createdAt: now.subtract(Duration(days: 3)),
          updatedAt: now.subtract(Duration(days: 3)),
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
            isRead: false,
            createdAt: now.subtract(Duration(minutes: 30)),
            updatedAt: now.subtract(Duration(minutes: 30)),
          ),
          Message(
            id: '2',
            conversationId: conversationId,
            senderId: 'user1',
            text: 'Thanks! I liked yours too. What do you do for fun?',
            timestamp: now.subtract(Duration(days: 1, hours: 1, minutes: 45)),
            status: MessageStatus.read,
            isRead: true,
            createdAt: now.subtract(Duration(days: 1, hours: 1, minutes: 45)),
            updatedAt: now.subtract(Duration(days: 1, hours: 1, minutes: 45)),
          ),
          Message(
            id: '3',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text: 'I love hiking and trying new coffee shops. What about you?',
            timestamp: now.subtract(Duration(days: 1, hours: 1, minutes: 30)),
            status: MessageStatus.sent,
            isRead: false,
            createdAt: now.subtract(Duration(days: 1, hours: 1, minutes: 30)),
            updatedAt: now.subtract(Duration(days: 1, hours: 1, minutes: 30)),
          ),
          Message(
            id: '4',
            conversationId: conversationId,
            senderId: 'user1',
            text: 'I enjoy photography and watching movies.',
            timestamp: now.subtract(Duration(days: 1, hours: 1)),
            status: MessageStatus.read,
            isRead: true,
            createdAt: now.subtract(Duration(days: 1, hours: 1)),
            updatedAt: now.subtract(Duration(days: 1, hours: 1)),
          ),
          Message(
            id: '5',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text: 'Would you like to grab coffee sometime?',
            timestamp: now.subtract(Duration(minutes: 30)),
            status: MessageStatus.sent,
            isRead: false,
            createdAt: now.subtract(Duration(minutes: 30)),
            updatedAt: now.subtract(Duration(minutes: 30)),
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
            isRead: true,
            createdAt: now.subtract(Duration(days: 2, hours: 4)),
            updatedAt: now.subtract(Duration(days: 2, hours: 4)),
          ),
          Message(
            id: '2',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text: 'Yes! I try to go at least once a month.',
            timestamp: now.subtract(Duration(days: 2, hours: 3)),
            status: MessageStatus.sent,
            isRead: false,
            createdAt: now.subtract(Duration(days: 2, hours: 3)),
            updatedAt: now.subtract(Duration(days: 2, hours: 3)),
          ),
          Message(
            id: '3',
            conversationId: conversationId,
            senderId: 'user2',
            text: 'Have you been to Eagle Peak?',
            timestamp: now.subtract(Duration(days: 2, hours: 2)),
            status: MessageStatus.read,
            isRead: true,
            createdAt: now.subtract(Duration(days: 2, hours: 2)),
            updatedAt: now.subtract(Duration(days: 2, hours: 2)),
          ),
          Message(
            id: '4',
            conversationId: conversationId,
            senderId: 'currentUserId',
            text:
                'No, but I\'ve heard it\'s beautiful! I\'ll have to check it out.',
            timestamp: now.subtract(Duration(days: 2, hours: 1)),
            status: MessageStatus.sent,
            isRead: false,
            createdAt: now.subtract(Duration(days: 2, hours: 1)),
            updatedAt: now.subtract(Duration(days: 2, hours: 1)),
          ),
          Message(
            id: '5',
            conversationId: conversationId,
            senderId: 'user2',
            text: 'That hiking spot looks amazing!',
            timestamp: now.subtract(Duration(hours: 2)),
            status: MessageStatus.read,
            isRead: true,
            createdAt: now.subtract(Duration(hours: 2)),
            updatedAt: now.subtract(Duration(hours: 2)),
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

  static List<Match> getDummyMatches() {
    return [
      Match(
        id: '1',
        matchedUser: Profile(
          id: '3',
          name: 'Emma Wilson',
          birthDate: DateTime(1994, 3, 10),
          gender: 'female',
          photoUrls: ['https://example.com/photo3.jpg'],
          interests: ['Art', 'Reading', 'Yoga'],
          location: {'city': 'London', 'country': 'UK'},
          bio: 'Art lover and bookworm',
          isVerified: true,
          profilePictures: ['https://example.com/photo3.jpg'],
          isPremium: false,
          lastActive: DateTime.now(),
        ),
        matchedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Match(
        id: '2',
        matchedUser: Profile(
          id: '4',
          name: 'David Kim',
          birthDate: DateTime(1992, 11, 5),
          gender: 'male',
          photoUrls: ['https://example.com/photo4.jpg'],
          interests: ['Sports', 'Movies', 'Travel'],
          location: {'city': 'Los Angeles', 'country': 'USA'},
          bio: 'Sports fanatic and movie buff',
          isVerified: true,
          profilePictures: ['https://example.com/photo4.jpg'],
          isPremium: true,
          lastActive: DateTime.now(),
        ),
        matchedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Match(
        id: '3',
        matchedUser: Profile(
          id: '5',
          name: 'Sophia Martinez',
          birthDate: DateTime(1996, 7, 20),
          gender: 'female',
          photoUrls: ['https://example.com/photo5.jpg'],
          interests: ['Dancing', 'Food', 'Music'],
          location: {'city': 'Miami', 'country': 'USA'},
          bio: 'Salsa dancer and foodie',
          isVerified: true,
          profilePictures: ['https://example.com/photo5.jpg'],
          isPremium: false,
          lastActive: DateTime.now(),
        ),
        matchedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Match(
        id: '4',
        matchedUser: Profile(
          id: '6',
          name: 'James Taylor',
          birthDate: DateTime(1991, 4, 15),
          gender: 'male',
          photoUrls: ['https://example.com/photo6.jpg'],
          interests: ['Hiking', 'Photography', 'Cooking'],
          location: {'city': 'Seattle', 'country': 'USA'},
          bio: 'Outdoor enthusiast and amateur chef',
          isVerified: true,
          profilePictures: ['https://example.com/photo6.jpg'],
          isPremium: true,
          lastActive: DateTime.now(),
        ),
        matchedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }
}
