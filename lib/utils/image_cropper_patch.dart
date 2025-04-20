import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http show readBytes;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:image_cropper_platform_interface/src/models/cropped_file/base.dart';

/// A CroppedFile that works on web.
///
/// It wraps the bytes of a selected file.
class CroppedFile extends CroppedFileBase {
  /// Construct a CroppedFile object from its ObjectUrl.
  ///
  /// Optionally, this can be initialized with `bytes`
  /// so no http requests are performed to retrieve files later.
  const CroppedFile(this.path, {Uint8List? bytes})
      : _initBytes = bytes,
        super(path);

  @override
  final String path;
  final Uint8List? _initBytes;

  Future<Uint8List> get _bytes async {
    if (_initBytes != null) {
      // Fixed line - return Uint8List directly instead of using UnmodifiableUint8ListView
      return Future<Uint8List>.value(_initBytes!);
    }
    return http.readBytes(Uri.parse(path));
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    return encoding.decode(await _bytes);
  }

  @override
  Future<Uint8List> readAsBytes() async {
    return _bytes;
  }
}

// This is a temporary patch file to make the Android build work
// when image_cropper has compatibility issues
class MockCroppedFile extends CroppedFile {
  const MockCroppedFile(super.path);
}

// This function can be used as a drop-in replacement for image_cropper
// when it has compatibility issues on Android
Future<CroppedFile?> safeCropImage(XFile? source) async {
  if (source == null) return null;

  try {
    // Try using a simple version of image_cropper to avoid parameter conflicts
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: source.path,
    );

    return croppedFile != null ? CroppedFile(croppedFile.path) : null;
  } catch (e) {
    // If it fails, just return the original file
    print('Image cropper failed: $e - returning original file');
    return MockCroppedFile(source.path);
  }
}
