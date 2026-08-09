import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerMicrophone implements MicrophonePermissionGateway {
  @override
  Future<MicrophonePermissionStatus> request() async {
    final status = await Permission.microphone.request();
    if (status.isGranted || status.isLimited) {
      return MicrophonePermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return MicrophonePermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return MicrophonePermissionStatus.restricted;
    return MicrophonePermissionStatus.denied;
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
