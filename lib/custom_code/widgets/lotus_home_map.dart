// FlutterFlow keeps these imports in custom widget exports, even when a
// particular widget does not use all of them.
// ignore_for_file: unnecessary_import, unused_import

// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'lotus_home_map_platform_stub.dart'
    if (dart.library.io) 'lotus_home_map_platform_native.dart'
    as platform;

/// Full-screen map used as the foundation of the Lotus Home page.
class LotusHomeMap extends StatelessWidget {
  const LotusHomeMap({super.key});

  @override
  Widget build(BuildContext context) => platform.buildLotusHomeMap();
}
