import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http show readBytes;

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