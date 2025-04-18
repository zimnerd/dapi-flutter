import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Or your storage solution
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Use Firebase Storage or your preferred cloud storage
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  StorageService(); // Keep default constructor for now

  // Secure read method for sensitive data
  Future<String?> read(String key) async {
    try {
      print('⟹ [StorageService] Reading key: $key');
      return await _secureStorage.read(key: key);
    } catch (e) {
      print('⟹ [StorageService] Error reading from secure storage: $e');
      
      // Fallback to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } catch (e) {
        print('⟹ [StorageService] Error reading from shared preferences: $e');
        return null;
      }
    }
  }

  // Secure write method for sensitive data
  Future<void> write(String key, String value) async {
    try {
      print('⟹ [StorageService] Writing key: $key');
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      print('⟹ [StorageService] Error writing to secure storage: $e');
      
      // Fallback to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (e) {
        print('⟹ [StorageService] Error writing to shared preferences: $e');
      }
    }
  }

  // Placeholder method: In a real app, this would upload the file and return the URL
  Future<String> uploadProfileImage(XFile imageFile, String userId) async {
    print("[StorageService] Uploading image for user $userId...");
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate upload
    
    // Return a dummy URL
    final fileName = _uuid.v4();
    final dummyUrl = 'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/profile_images%2F$userId%2F$fileName.jpg?alt=media';
    print("[StorageService] Dummy upload complete. URL: $dummyUrl");
    return dummyUrl;
    
    /* 
    // Example Firebase Storage implementation:
    try {
      final String fileName = _uuid.v4();
      final Reference ref = _storage.ref().child('profile_images/$userId/$fileName');
      final UploadTask uploadTask = ref.putFile(File(imageFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print("[StorageService] Upload successful. URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("[StorageService] Error uploading image: $e");
      throw Exception('Image upload failed: $e');
    }
    */
  }

  // Check if mock data mode is enabled
  Future<bool> isMockDataEnabled() async {
    final mockDataMode = await read('use_mock_data');
    return mockDataMode == 'true';
  }

  // Enable mock data mode for testing
  Future<void> enableMockDataMode() async {
    await write('use_mock_data', 'true');
    print('⟹ [StorageService] Mock data mode enabled');
  }
  
  // Disable mock data mode
  Future<void> disableMockDataMode() async {
    await write('use_mock_data', 'false');
    print('⟹ [StorageService] Mock data mode disabled');
  }
} 