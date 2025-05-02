import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final Profile profile;

  const ProfileDetailsScreen({
    super.key,
    required this.profile,
  });

  @override
  ProfileDetailsScreenState createState() => ProfileDetailsScreenState();
}

class ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  int _currentPhotoIndex = 0;
  final PageController _photoController = PageController();

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with profile photos
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.6,
            pinned: true,
            backgroundColor: Colors.black,
            actions: [
              // Add a full-screen button
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: _openFullscreenGallery,
              ),
            ],
            leading: CircleAvatar(
              backgroundColor: Colors.black.withAlpha(30),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo carousel
                  PageView.builder(
                    controller: _photoController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemCount: widget.profile.photoUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: _openFullscreenGallery,
                        child: Hero(
                          tag: 'profile_photo_$index',
                          child: Image.network(
                            widget.profile.photoUrls[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),

                  // Photo indicators
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.profile.photoUrls.length,
                        (index) {
                          final isActive = index == _currentPhotoIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 20 : 10,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withAlpha((255 * 0.4).toInt()),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Photo counter
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentPhotoIndex + 1}/${widget.profile.photoUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile details
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, age and verification
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${widget.profile.name}, ${widget.profile.age}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Verification badge
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Distance indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.withAlpha(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '5 km away',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // About section
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Occupation
                  if (widget.profile.occupation?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.work_outline_rounded,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.profile.occupation ?? 'No occupation',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bio - full text
                  if (widget.profile.bio?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        widget.profile.bio ?? 'No bio',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),

                  // Additional personal information section
                  ..._buildPersonalInfoSection(),

                  const SizedBox(height: 24),

                  // Interests section
                  if (widget.profile.interests.isNotEmpty) ...[
                    const Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.profile.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary
                                    .withAlpha((255 * 0.8).toInt()),
                                AppColors.primary
                                    .withAlpha((255 * 0.6).toInt()),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withAlpha((255 * 0.3).toInt()),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.close,
                        color: AppColors.dislike,
                        label: 'Pass',
                        onTap: () {
                          Navigator.pop(context);
                          // Handle dislike
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.favorite,
                        color: AppColors.like,
                        label: 'Like',
                        onTap: () {
                          Navigator.pop(context);
                          // Handle like
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: color.withAlpha((255 * 0.2).toInt()), width: 2),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPersonalInfoSection() {
    final dateFormatter = DateFormat('MMMM d, yyyy');

    return [
      const Text(
        'Personal Information',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 16),

      // Gender
      _buildInfoRow(
        icon: Icons.person_outline,
        label: 'Gender',
        value: widget.profile.gender ?? 'Not specified',
      ),

      const SizedBox(height: 12),

      // Birth date
      _buildInfoRow(
        icon: Icons.cake_outlined,
        label: 'Birth Date',
        value: widget.profile.birthDate != null
            ? dateFormatter.format(widget.profile.birthDate!)
            : 'Not specified',
      ),

      const SizedBox(height: 12),

      // Location
      if (widget.profile.location != null)
        _buildInfoRow(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: widget.profile.location.toString(),
        ),

      if (widget.profile.location != null) const SizedBox(height: 12),

      // Additional profile preferences section
      const Text(
        'Preferences',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      // Age preference
      _buildInfoRow(
        icon: Icons.person_search_outlined,
        label: 'Age Preference',
        value:
            '${widget.profile.minAgePreference} - ${widget.profile.maxAgePreference} years',
      ),

      const SizedBox(height: 12),

      // Distance preference
      _buildInfoRow(
        icon: Icons.explore_outlined,
        label: 'Maximum Distance',
        value: '${widget.profile.maxDistance?.toInt() ?? 0} km',
      ),

      const SizedBox(height: 12),

      // Gender preference
      if (widget.profile.genderPreference != null)
        _buildInfoRow(
          icon: Icons.favorite_border_outlined,
          label: 'Interested In',
          value: widget.profile.genderPreference!,
        ),
    ];
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openFullscreenGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenGallery(
          photos: widget.profile.photoUrls,
          initialIndex: _currentPhotoIndex,
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _FullscreenGallery({
    required this.photos,
    required this.initialIndex,
  });

  @override
  _FullscreenGalleryState createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photos
          GestureDetector(
            onTap: _toggleControls,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: 'profile_photo_$index',
                      child: Image.network(
                        widget.photos[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Controls - fade in/out
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: Duration(milliseconds: 200),
            child: Column(
              children: [
                // Top bar
                Container(
                  color: Colors.black.withAlpha(50),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    left: 4,
                    right: 16,
                    bottom: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          '${_currentIndex + 1}/${widget.photos.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.white),
                        onPressed: () {
                          // Share functionality could be added here
                        },
                      ),
                    ],
                  ),
                ),

                Spacer(),

                // Bottom indicators
                if (widget.photos.length > 1)
                  Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    color: Colors.black.withAlpha(50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.photos.length,
                        (index) {
                          final isActive = index == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 20 : 10,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withAlpha((255 * 0.4).toInt()),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
