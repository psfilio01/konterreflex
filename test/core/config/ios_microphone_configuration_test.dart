import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS microphone permission has its usage text and build flag', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();

    expect(infoPlist, contains('<key>NSMicrophoneUsageDescription</key>'));
    expect(
      infoPlist,
      contains(
        'Konterreflex benötigt das Mikrofon, damit du gesprochene Antworten trainieren kannst.',
      ),
    );
    expect(podfile, contains("'PERMISSION_MICROPHONE=1'"));
    expect(
      File('ios/Runner/en.lproj/InfoPlist.strings').readAsStringSync(),
      contains('Konterreflex needs microphone access'),
    );
  });
}
