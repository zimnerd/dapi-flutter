import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/profile.dart';
import '../screens/profile_details_screen.dart';
import '../utils/logger.dart';

class ProfileCard extends StatefulWidget {
  final Profile profile;
  final bool interactive;

  const ProfileCard({
    super.key,
    required this.profile,
    this.interactive = true,
  });

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _selectedPhotoIndex = 0;
  final Logger _logger = Logger('ProfileCard');

  void _navigateToProfileDetail(BuildContext context) {
    if (!widget.interactive) return;

    _logger.debug('Navigating to profile details for ${widget.profile.id}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailsScreen(profile: widget.profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrls = widget.profile.photoUrls;
    final hasPhotos = photoUrls.isNotEmpty;
    final currentImageUrl = hasPhotos && _selectedPhotoIndex < photoUrls.length
        ? photoUrls[_selectedPhotoIndex]
        : null;

    _logger.debug(
        'Building card for profile ${widget.profile.id}, selected photo index: $_selectedPhotoIndex');

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfileDetail(context),
              child: Container(
                color: Colors.grey[300],
                child: currentImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: currentImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) {
                          _logger.error(
                              'Error loading main image: $url, Error: $error');
                          return Image.asset(
                            'assets/images/default_profile.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              _logger.error(
                                  'Error loading default_profile.png: $error');
                              return const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 50, color: Colors.grey));
                            },
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/default_profile.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          _logger.error(
                              'Error loading default_profile.png (no photos): $error');
                          return const Center(
                              child: Icon(Icons.person_off,
                                  size: 50, color: Colors.grey));
                        },
                      ),
              ),
            ),
          ),
          if (hasPhotos && photoUrls.length > 1)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              color: Colors.black.withOpacity(0.1),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: photoUrls.asMap().entries.map((entry) {
                    int index = entry.key;
                    String url = entry.value;
                    bool isSelected = _selectedPhotoIndex == index;

                    if (index >= photoUrls.length) {
                      _logger.warn(
                          'Thumbnail index $index out of bounds for photoUrls length ${photoUrls.length}');
                      return const SizedBox.shrink();
                    }

                    return GestureDetector(
                      onTap: () {
                        if (_selectedPhotoIndex != index) {
                          _logger.debug(
                              'Thumbnail tapped, changing index to $index');
                          setState(() {
                            _selectedPhotoIndex = index;
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) {
                              _logger.error(
                                  'Error loading thumbnail image: $url, Error: $error');
                              return Container(
                                  width: 50,
                                  height: 70,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image,
                                      size: 20, color: Colors.grey));
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.profile.name ?? 'N/A'}, ${widget.profile.age ?? 'N/A'}",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (widget.profile.bio != null &&
                    widget.profile.bio!.isNotEmpty) ...[
                  Text(
                    widget.profile.bio!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.profile.interests.isNotEmpty)
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: widget.profile.interests
                        .map((interest) => Chip(
                              label: Text(interest),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              backgroundColor: Colors.grey[200],
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
