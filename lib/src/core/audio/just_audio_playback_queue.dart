import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';

class JustAudioPlaybackQueue
    implements AudioPlaybackQueue, VoiceActivitySource {
  JustAudioPlaybackQueue({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final Queue<SpeechClip> _pending = Queue();
  final StreamController<double> _voiceActivityController =
      StreamController<double>.broadcast(sync: true);
  int _generation = 0;
  bool _playing = false;
  Timer? _voiceActivityTimer;

  @override
  Stream<double> get voiceActivity => _voiceActivityController.stream;

  @override
  Future<void> enqueue(SpeechClip clip) async => _pending.add(clip);

  @override
  Future<void> playAll() async {
    if (_playing) throw StateError('The playback queue is already running.');
    _playing = true;
    final generation = _generation;
    try {
      while (_pending.isNotEmpty && generation == _generation) {
        final clip = _pending.removeFirst();
        try {
          await _player.setAudioSource(
            _BytesAudioSource(clip.bytes, clip.mimeType),
          );
          if (generation != _generation) return;
          _startVoiceActivity(clip);
          await _player.play();
        } catch (_) {
          throw const VoiceServiceException(
            VoiceServiceFailureKind.playback,
            'AUDIO_PLAYBACK',
          );
        } finally {
          _stopVoiceActivity();
        }
      }
    } finally {
      _playing = false;
    }
  }

  @override
  Future<void> stop() async {
    _generation += 1;
    _pending.clear();
    _stopVoiceActivity();
    await _player.stop();
  }

  void _startVoiceActivity(SpeechClip clip) {
    _stopVoiceActivity();
    final cadenceOffset = (clip.transcript?.hashCode ?? clip.bytes.length) % 29;
    _voiceActivityTimer = Timer.periodic(
      const Duration(milliseconds: 72),
      (_) {
        final elapsed = _player.position.inMilliseconds + cadenceOffset;
        final primary = math.sin(elapsed / 92).abs();
        final secondary = math.sin((elapsed + 130) / 47).abs();
        final pause = math.sin((elapsed + 260) / 510).abs();
        final level =
            (0.12 + primary * 0.48 + secondary * 0.24) * (0.52 + pause * 0.48);
        _voiceActivityController.add(level.clamp(0.0, 1.0).toDouble());
      },
    );
  }

  void _stopVoiceActivity() {
    _voiceActivityTimer?.cancel();
    _voiceActivityTimer = null;
    if (!_voiceActivityController.isClosed) {
      _voiceActivityController.add(0);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
    await _voiceActivityController.close();
  }
}

class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this.bytes, this.mimeType);

  final Uint8List bytes;
  final String mimeType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final offset = start ?? 0;
    final last = end ?? bytes.length;
    final slice = bytes.sublist(offset, last);
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: slice.length,
      offset: offset,
      stream: Stream.value(slice),
      contentType: mimeType,
    );
  }
}
