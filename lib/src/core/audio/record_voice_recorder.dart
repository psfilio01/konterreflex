import 'dart:async';
import 'dart:typed_data';

import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:record/record.dart' as record;

class RecordVoiceRecorder implements VoiceRecorder {
  RecordVoiceRecorder({record.AudioRecorder? recorder})
      : _recorder = recorder ?? record.AudioRecorder();

  final record.AudioRecorder _recorder;
  StreamSubscription<Uint8List>? _subscription;
  Completer<void>? _streamFinished;
  BytesBuilder? _bytes;

  @override
  Future<void> start() async {
    if (_subscription != null) {
      throw StateError('A recording is already active.');
    }
    _bytes = BytesBuilder(copy: false);
    _streamFinished = Completer<void>();
    final stream = await _recorder.startStream(
      const record.RecordConfig(
        encoder: record.AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _subscription = stream.listen(
      _bytes!.add,
      onError: _streamFinished!.completeError,
      onDone: _streamFinished!.complete,
      cancelOnError: true,
    );
  }

  @override
  Future<RecordedAudio> stop() async {
    if (_subscription == null || _bytes == null || _streamFinished == null) {
      throw StateError('No recording is active.');
    }
    await _recorder.stop();
    await _streamFinished!.future;
    final result = RecordedAudio(
      bytes: _bytes!.takeBytes(),
      mimeType: 'audio/pcm;rate=16000',
    );
    await _clearStream();
    return result;
  }

  @override
  Future<void> cancel() async {
    if (_subscription == null) return;
    await _recorder.cancel();
    await _clearStream();
  }

  Future<void> _clearStream() async {
    await _subscription?.cancel();
    _subscription = null;
    _streamFinished = null;
    _bytes = null;
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }
}
