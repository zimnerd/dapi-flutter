import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/empty_state.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isLoading = true;
  List<Event> _events = [];
  String _selectedFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    // Simulate loading from API
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, these would come from an API
    setState(() {
      _events = _getMockEvents();
      _isLoading = false;
    });
  }
  
  List<Event> _getMockEvents() {
    return [
      Event(
        id: '1',
        title: 'Yoga in the Park',
        description: 'Join us for a relaxing yoga session in Central Park. All skill levels welcome!',
        location: 'Central Park, New York',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        attendees: 18,
        category: 'Fitness',
        isFree: true,
      ),
      Event(
        id: '2',
        title: 'Coffee Tasting Event',
        description: 'Sample different coffee varieties from around the world and meet new people!',
        location: 'Brew House Cafe, Brooklyn',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        imageUrl: 'https://images.unsplash.com/photo-1511920170033-f8396924c348?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        attendees: 24,
        category: 'Food & Drink',
        isFree: false,
        price: 15.0,
      ),
      Event(
        id: '3',
        title: 'Hiking Adventure',
        description: 'A moderate 5-mile hike with beautiful views. Great opportunity to meet fellow nature lovers!',
        location: 'Bear Mountain State Park',
        dateTime: DateTime.now().add(const Duration(days: 8)),
        imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        attendees: 12,
        category: 'Outdoors',
        isFree: true,
      ),
      Event(
        id: '4',
        title: 'Paint & Sip Night',
        description: 'Enjoy wine while painting a masterpiece! No experience necessary, instructor will guide you step by step.',
        location: 'Art Studio Loft, Manhattan',
        dateTime: DateTime.now().add(const Duration(days: 4)),
        imageUrl: 'https://images.unsplash.com/photo-1577896852618-320e1f882636?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        attendees: 35,
        category: 'Art',
        isFree: false,
        price: 45.0,
      ),
      Event(
        id: '5',
        title: 'Salsa Dancing Lessons',
        description: 'Learn to dance salsa with professional instructors. Singles welcome - partners will rotate throughout the evening.',
        location: 'Dance Studio 54, Queens',
        dateTime: DateTime.now().add(const Duration(days: 6)),
        imageUrl: 'https://images.unsplash.com/photo-1504609813442-a9924e2e4531?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        attendees: 28,
        category: 'Dance',
        isFree: false,
        price: 20.0,
      ),
      Event(
        id: '6',
        title: 'Board Game Night',
        description: 'Fun night of board games and meeting new people. Games provided, but feel free to bring your favorites!',
        location: 'Game Haven Cafe, Brooklyn',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        imageUrl: 'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        attendees: 22,
        category: 'Games',
        isFree: true,
      ),
    ];
  }
  
  List<Event> get _filteredEvents {
    if (_selectedFilter == 'All') {
      return _events;
    }
    return _events.where((event) => event.category == _selectedFilter).toList();
  }
  
  List<String> get _categories {
    final categories = _events.map((e) => e.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? EmptyState(
                  icon: Icons.event,
                  title: 'No events found',
                  message: 'There are no upcoming events in your area. Check back later!',
                )
              : Column(
                  children: [
                    const SizedBox(height: 8),
                    // Category filter chips
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedFilter == category,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = category;
                                });
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: _selectedFilter == category 
                                    ? AppColors.primary 
                                    : Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Events list
                    Expanded(
                      child: _filteredEvents.isEmpty
                          ? EmptyState(
                              icon: Icons.event_busy,
                              title: 'No events in this category',
                              message: 'Try selecting a different category or check back later!',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) {
                                return _buildEventCard(_filteredEvents[index]);
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event creation coming soon!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          AspectRatio(
            aspectRatio: 16/9,
            child: Image.network(
              event.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          
          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.category,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(event.dateTime),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Title
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Price & Attendees
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.isFree ? 'FREE' : '\$${event.price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: event.isFree ? Colors.green : Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16),
                        const SizedBox(width: 4),
                        Text('${event.attendees} attending'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // RSVP Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('RSVP to "${event.title}" coming soon!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('RSVP'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime dateTime) {
    // Format: "Mon, Jan 1, 7:00 PM"
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final day = days[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    final date = dateTime.day;
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day, $month $date, $hour:$minute $period';
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final String imageUrl;
  final int attendees;
  final String category;
  final bool isFree;
  final double? price;
  
  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.dateTime,
    required this.imageUrl,
    required this.attendees,
    required this.category,
    required this.isFree,
    this.price,
  }) : assert(isFree || price != null, 'Price must be provided for non-free events');
} 