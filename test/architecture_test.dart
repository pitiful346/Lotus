import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const coreRoot = 'packages/lotus_core/lib';
  const pureLayerRoots = ['$coreRoot/src/domain', '$coreRoot/src/application'];

  test('lotus_core never depends on the generated FlutterFlow application', () {
    final violations = _findImports(
      roots: const [coreRoot],
      forbidden: const ['package:lotus/'],
    );

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('domain and application remain framework independent', () {
    final violations = _findImports(
      roots: pureLayerRoots,
      forbidden: const [
        'dart:io',
        'package:flutter/',
        'package:cloud_firestore/',
        'package:firebase_',
      ],
    );

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

List<String> _findImports({
  required List<String> roots,
  required List<String> forbidden,
}) {
  final violations = <String>[];

  for (final root in roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) {
      continue;
    }

    final dartFiles = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final import in forbidden) {
        if (content.contains(import)) {
          violations.add('${file.path} imports $import');
        }
      }
    }
  }

  return violations;
}
