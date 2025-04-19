import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Export the appropriate connectivity implementation based on platform
export 'web_network_stub.dart' if (dart.library.io) 'network_manager.dart'; 