import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Audio handler that integrates just_audio with audio_service for
/// background playback and system notification controls.
class RadioAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  /// Decodes HTML entities like &#281; -> Ä™, &#x142; -> Ĺ‚, &amp; -> &
  static String _decodeHtmlEntities(String text) {
    // Decode numeric entities: &#NNN;
    text = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    );
    // Decode hex entities: &#xHHH;
    text = text.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    // Decode common named entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    return text;
  }

  AudioPlayer get player => _player;

  RadioAudioHandler() {
    // Broadcast playback state changes to the system.
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    // Listen to ICY metadata (Icecast/Shoutcast) for current song info.
    _player.icyMetadataStream.listen((metadata) {
      final currentItem = mediaItem.value;
      if (currentItem != null && metadata?.info?.title != null) {
        final songTitle = _decodeHtmlEntities(metadata!.info!.title!);
        // Update notification to show song title.
        mediaItem.add(currentItem.copyWith(
          title: songTitle,
          artist: currentItem.album,
          displayTitle: songTitle,
          displaySubtitle: currentItem.album,
        ));
      }
    });
  }

  /// Plays the current media item (radio station stream).
  @override
  Future<void> play() async { if (mediaItem.value != null) { _player.setUrl(mediaItem.value!.id).catchError((_) {}); await _player.play(); } else { await _player.play(); } }

  /// Pauses the current stream.
  @override
  Future<void> pause() async { await _player.stop(); }

  /// Stops playback and clears the notification.
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
    // Forcefully exit the app when removed from recents
    exit(0);
  }


  /// Sets a new radio station URL and starts playing.
  Future<void> playStation({
    required String url,
    required String title,
    String? artUri,
    String? album,
  }) async {
    // Update the media item metadata shown in the notification.
    final item = MediaItem(
      id: url,
      title: title,
      album: album ?? 'RadyjkoON',
      artUri: artUri != null && artUri.isNotEmpty ? Uri.tryParse(artUri) : null,
      playable: true,
    );
    mediaItem.add(item);

    try {
      // Don't await setUrl for radio streams as it blocks until buffering is done,
      // keeping the playing state false and making the UI look stopped.
      _player.setUrl(url).catchError((_) {});
      await _player.play();
    } catch (e) {
      // Propagate the error through playback state.
      // błąd jest propagowany przez strumień just_audio
    }
  }

  void updateArtwork(String? artUri) {
    final currentItem = mediaItem.value;
    if (currentItem != null) {
      final uri = (artUri != null && artUri.isNotEmpty) ? Uri.tryParse(artUri) : null;
      // If uri is null, we have to use a trick because copyWith(artUri: null) might not override if it's not explicitly supported, wait, copyWith in audio_service supports setting null? No, MediaItem.copyWith doesn't let you null out a property easily unless you recreate it or it handles it. Let's see...
      // Actually MediaItem copyWith in audio_service: it uses null check rtUri ?? this.artUri. To clear it, we might have to recreate the MediaItem.
      mediaItem.add(MediaItem(
        id: currentItem.id,
        title: currentItem.title,
        album: currentItem.album,
        artist: currentItem.artist,
        genre: currentItem.genre,
        duration: currentItem.duration,
        artUri: uri,
        playable: currentItem.playable,
        displayTitle: currentItem.displayTitle,
        displaySubtitle: currentItem.displaySubtitle,
        displayDescription: currentItem.displayDescription,
        extras: currentItem.extras,
      ));
    }
  }

  /// Transforms just_audio events into audio_service PlaybackState
  /// so the system notification shows the correct controls.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1],
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}



















