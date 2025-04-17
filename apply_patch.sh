#!/bin/bash

# Path to the problematic file
TARGET_FILE="/Users/eddy/.pub-cache/hosted/pub.dev/image_cropper_platform_interface-5.0.0/lib/src/models/cropped_file/html.dart"

# Backup the original file
cp "$TARGET_FILE" "${TARGET_FILE}.backup"

# Replace the file with our patched version
cat > "$TARGET_FILE" << 'EOF'
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright note: this code file is copied from `image_picker` plugin

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http show readBytes;

import './base.dart';

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
      // Fixed: Return Uint8List directly instead of using UnmodifiableUint8ListView
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
EOF

echo "Patch applied successfully!" 