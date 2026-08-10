import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:record/record.dart' as record;

class RecordVoiceRecorder
    implements HandsFreeVoiceRecorder, VoiceActivitySource {
  RecordVoiceRecorder({
    record.AudioRecorder? recorder,
    this.silenceDuration = const Duration(milliseconds: 850),
    this.maximumDuration = const Duration(seconds: 20),
    this.speechThreshold = 650,
  }) : _recorder = recorder ?? record.AudioRecorder();

  final record.AudioRecorder _recorder;
  final StreamController<double> _voiceActivityController =
      StreamController<double>.broadcast(sync: true);
  StreamSubscription<Uint8List>? _subscription;
  Completer<void>? _streamFinished;
  BytesBuilder? _bytes;
  void Function(Uint8List)? _onAudio;
  final Duration silenceDuration;
  final Duration maximumDuration;
  final double speechThreshold;
  double _smoothedActivity = 0;

  @override
  Stream<double> get voiceActivity => _voiceActivityController.stream;

  @override
  Future<void> start() async {
    if (_subscription != null) {
      throw StateError('A recording is already active.');
    }
    await _beginRecording();
  }

  Future<void> _beginRecording({void Function(Uint8List)? onAudio}) async {
    _bytes = BytesBuilder(copy: false);
    _onAudio = onAudio;
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
      (chunk) {
        _bytes!.add(chunk);
        _publishVoiceActivity(chunk);
        _onAudio?.call(chunk);
      },
      onError: _streamFinished!.completeError,
      onDone: _streamFinished!.complete,
      cancelOnError: true,
    );
  }

  @override
  Future<RecordedAudio> recordUntilSilence() async {
    if (_subscription != null) {
      throw StateError('A recording is already active.');
    }
    final utteranceFinished = Completer<void>();
    var heardSpeech = false;
    var silentBytes = 0;
    final requiredSilentBytes =
        (32000 * silenceDuration.inMilliseconds / 1000).round();
    await _beginRecording(
      onAudio: (chunk) {
        if (_pcmRms(chunk) >= speechThreshold) {
          heardSpeech = true;
          silentBytes = 0;
        } else if (heardSpeech) {
          silentBytes += chunk.length;
          if (silentBytes >= requiredSilentBytes &&
              !utteranceFinished.isCompleted) {
            utteranceFinished.complete();
          }
        }
      },
    );
    final timeout = Timer(maximumDuration, () {
      if (!utteranceFinished.isCompleted) utteranceFinished.complete();
    });
    await utteranceFinished.future;
    timeout.cancel();
    return stop();
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
    _onAudio = null;
    _smoothedActivity = 0;
    _voiceActivityController.add(0);
  }

  void _publishVoiceActivity(Uint8List chunk) {
    final rms = _pcmRms(chunk);
    final noiseFloor = speechThreshold * 0.16;
    final target = (rms <= noiseFloor
            ? 0.0
            : ((rms - noiseFloor) / (speechThreshold * 2.4)).clamp(0.0, 1.0))
        .toDouble();
    final smoothing = target > _smoothedActivity ? 0.52 : 0.2;
    _smoothedActivity += (target - _smoothedActivity) * smoothing;
    _voiceActivityController.add(
      _smoothedActivity.clamp(0.0, 1.0).toDouble(),
    );
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
    await _voiceActivityController.close();
  }
}

double _pcmRms(Uint8List bytes) {
  if (bytes.length < 2) return 0;
  var sum = 0.0;
  var samples = 0;
  for (var index = 0; index + 1 < bytes.length; index += 2) {
    var sample = bytes[index] | (bytes[index + 1] << 8);
    if (sample >= 0x8000) sample -= 0x10000;
    sum += sample * sample;
    samples += 1;
  }
  return samples == 0 ? 0 : sqrt(sum / samples);
}
