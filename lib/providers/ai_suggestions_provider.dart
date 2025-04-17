import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dummy provider to simulate fetching AI Icebreakers
final icebreakerSuggestionsProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, conversationId) async {
  // In a real app, this would:
  // 1. Get user IDs associated with conversationId.
  // 2. Fetch relevant profile info for both users.
  // 3. Call a backend endpoint/AI service with that info.
  // 4. Return the suggestions from the service.

  print("Simulating AI Icebreaker fetch for: $conversationId");

  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 1200));

  // Return hardcoded dummy suggestions
  // Optionally make these slightly dynamic based on conversationId or dummy user data
  final List<String> suggestions = [
    "What\'s been the highlight of your week so far? ✨",
    "If you could have any superpower, what would it be? 🦸",
    "Spotted [mention common interest/photo detail] on your profile! Tell me more?",
    "Pineapple on pizza: Yes or No? 🍍🍕",
    "What\'s one song you have on repeat right now? 🎶",
  ];

  // Simulate potential error (uncomment to test error state)
  // if (Random().nextDouble() < 0.2) {
  //   throw Exception("Failed to fetch AI suggestions");
  // }

  return suggestions;
});

// Dummy provider for Profile Optimization Tips (similar structure)
final profileOptimizationTipsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
   // In a real app, this would:
   // 1. Get current user's profile data.
   // 2. Call backend/AI service with profile data.
   // 3. Return actionable tips.

   print("Simulating AI Profile Tip fetch...");
   await Future.delayed(const Duration(milliseconds: 1500));

   // Dummy tips
    return [
      "Your first photo is great! Adding one more showing an activity you enjoy could boost interest.",
      "Consider answering the 'Two truths and a lie' prompt - it's a great conversation starter!",
      "Mentioning specific goals in your bio can help attract like-minded people.",
    ];
}); 