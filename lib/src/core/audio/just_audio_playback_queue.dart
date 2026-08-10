import 'dart:collection';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';

class JustAudioPlaybackQueue implements AudioPlaybackQueue {
  JustAudioPlaybackQueue({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final Queue<SpeechClip> _pending = Queue();
  int _generation = 0;
  bool _playing = false;

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
          await _player.play();
        } catch (_) {
          throw const VoiceServiceException(
            VoiceServiceFailureKind.playback,
            'AUDIO_PLAYBACK',
          );
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
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
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
