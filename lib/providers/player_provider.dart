import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/radio_station.dart';
import '../services/audio_handler.dart';
import '../services/itunes_service.dart';
import '../services/radio_api_service.dart';
import '../services/song_recognition_service.dart';

class PlayerProvider extends ChangeNotifier {
  final RadioAudioHandler _handler;
  final RadioApiService _api = RadioApiService();
  static const _tileChannel = MethodChannel('com.radyjkoon/tile');

  RadioStation? _currentStation;
  RadioStation? get currentStation => _currentStation;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isBuffering = false;
  bool get isBuffering => _isBuffering;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentSong;
  String? _currentArtwork;
  String? get currentArtwork => _currentArtwork;
  String? get currentSong => _currentSong;

  bool _isRecognizing = false;
  bool get isRecognizing => _isRecognizing;

  bool _isManualSong = false;
  bool get isManualSong => _isManualSong;

  DateTime? _manualSongExpiresAt;
  Timer? _manualSongTimer;

  int get manualSongRemainingSeconds {
    if (!_isManualSong || _manualSongExpiresAt == null) return 0;
    final diff = _manualSongExpiresAt!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void clearManualSong() {
    _manualSongTimer?.cancel();
    _manualSongTimer = null;
    _manualSongExpiresAt = null;
    _isManualSong = false;
    _currentSong = null;
    _currentArtwork = null;
    final station = _currentStation;
    if (station != null) {
      final customLogo = _customLogoGetter?.call(station.stationUuid);
      _handler.resetToStation(
        stationName: station.name,
        artUri: customLogo ?? station.bestFavicon,
      );
    }
    notifyListeners();
  }

  void _startManualSongTimer({Duration duration = const Duration(minutes: 3, seconds: 30)}) {
    _manualSongTimer?.cancel();
    _manualSongExpiresAt = DateTime.now().add(duration);
    _manualSongTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isManualSong || manualSongRemainingSeconds <= 0) {
        clearManualSong();
      } else {
        notifyListeners();
      }
    });
  }

  bool Function(String)? _isItunesDisabledCheck;
  void setItunesDisabledChecker(bool Function(String) checker) {
    _isItunesDisabledCheck = checker;
  }

  String? Function(String)? _customLogoGetter;
  void setCustomLogoGetter(String? Function(String) getter) {
    _customLogoGetter = getter;
  }

  bool _isJunkSongTitle(String? title, RadioStation? station) {
    if (title == null || title.trim().isEmpty) return true;
    final cleaned = title.trim().toLowerCase();
    
    if (station != null) {
      final stationName = station.name.trim().toLowerCase();
      if (cleaned == stationName) return true;
      if ((stationName.contains(cleaned) || cleaned.contains(stationName)) &&
          !title.contains(' - ') && !title.contains(' – ')) {
        return true;
      }
    }

    const junkTitles = [
      'radio',
      'unknown',
      'stream',
      'online',
      'live',
      'muzyka',
      'najlepsza muzyka',
      'hity na czasie',
      'reklama',
      'audycja',
      'wiadomości',
    ];
    if (junkTitles.contains(cleaned)) return true;

    return false;
  }

  PlayerProvider(this._handler) {
    _handler.player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering || state.processingState == ProcessingState.loading;
      _updateTile();
      notifyListeners();
    });

    _handler.player.playbackEventStream.listen((event) {}, onError: (e, stackTrace) {
      _hasError = true;
      String errorDetails = 'Kod błędu: nieznany';
      if (e is PlayerException) {
        errorDetails = 'Błąd [PE-${e.code}]: ${e.message}';
      } else {
        errorDetails = 'Błąd [SYS]: ${e.toString()}';
      }
      _errorMessage = 'Nie udało się odtworzyć stacji.\n$errorDetails';
      _isPlaying = false;
      _updateTile();
      notifyListeners();
    });

    _handler.player.icyMetadataStream.listen((metadata) async {
      final rawTitle = metadata?.info?.title;
      if (rawTitle == null || rawTitle.trim().isEmpty) return;
      final songTitle = RadioAudioHandler.decodeHtmlEntities(rawTitle).trim();
      if (songTitle.isEmpty) return;

      if (_isJunkSongTitle(songTitle, _currentStation)) {
        if (!_isManualSong && (_currentSong != null || _currentArtwork != null)) {
          _currentSong = null;
          _currentArtwork = null;
          final station = _currentStation;
          if (station != null) {
            final customLogo = _customLogoGetter?.call(station.stationUuid);
            _handler.resetToStation(
              stationName: station.name,
              artUri: customLogo ?? station.bestFavicon,
            );
          }
          notifyListeners();
        }
        return;
      }

      if (_currentSong != songTitle) {
        _manualSongTimer?.cancel();
        _manualSongTimer = null;
        _manualSongExpiresAt = null;
        _isManualSong = false;
        _currentSong = songTitle;
        _currentArtwork = null;

        final station = _currentStation;
        final stationId = station?.stationUuid ?? '';
        final customLogo = _customLogoGetter?.call(stationId);
        final stationLogo = customLogo ?? station?.bestFavicon;

        _handler.updateMediaDetails(
          title: songTitle,
          artist: station?.name,
          artUri: stationLogo,
        );
        notifyListeners();

        if (!(_isItunesDisabledCheck?.call(stationId) ?? false)) {
          try {
            final artwork = await ItunesService.getArtwork(songTitle);
            if (artwork != null && _currentSong == songTitle) {
              _currentArtwork = artwork;
              _handler.updateArtwork(artwork);
              notifyListeners();
            }
          } catch (_) {}
        }
      }
    });

    _tileChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'togglePlayPause':
          await togglePlayPause();
          break;
        case 'getState':
          return {
            'isPlaying': _isPlaying,
            'stationName': _currentStation?.name ?? '',
          };
      }
    });
  }

  double get volume => _handler.player.volume;
  void setVolume(double vol) {
    _handler.player.setVolume(vol);
    notifyListeners();
  }

  /// Play a station. If the same station is already playing, toggle pause/play.
  Future<void> playStation(RadioStation station) async {
    _hasError = false;
    _errorMessage = null;

    if (_currentStation?.stationUuid == station.stationUuid) {
      if (_isPlaying) {
        await _handler.pause();
      } else {
        await _handler.play();
      }
      return;
    }

    _manualSongTimer?.cancel();
    _manualSongTimer = null;
    _manualSongExpiresAt = null;
    _currentStation = station;
    _isManualSong = false;
    _currentSong = null;
    _currentArtwork = null;
    _isBuffering = true;
    notifyListeners();

    try {
      _api.clickStation(station.stationUuid);
      await _handler.playStation(
        url: station.streamUrl,
        title: station.name,
        artUri: station.favicon,
        album: station.name,
      );
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Nie udało się połączyć ze stacją';
      _isPlaying = false;
      _isBuffering = false;
      notifyListeners();
    }
  }

  Future<String?> recognizeCurrentSong({String? rapidApiKey}) async {
    final station = _currentStation;
    if (station == null || !_isPlaying) {
      return 'Włącz odtwarzanie stacji przed rozpoznawaniem.';
    }

    final streamUrl = station.streamUrl;
    if (streamUrl.isEmpty) {
      return 'Brak adresu strumienia dla tej stacji.';
    }

    _isRecognizing = true;
    notifyListeners();

    try {
      final result = await SongRecognitionService.recognizeFromStream(
        streamUrl,
        rapidApiKey: rapidApiKey,
      );

      if (result.isSuccess && result.song != null) {
        final recognized = result.song!;
        final newSong = recognized.fullTitle;
        _isManualSong = true;
        _currentSong = newSong;
        _currentArtwork = recognized.artworkUrl;

        final stationId = station.stationUuid;
        final customLogo = _customLogoGetter?.call(stationId);
        final stationLogo = customLogo ?? station.bestFavicon;

        // Immediately update notification title, artist, and artwork
        _handler.updateMediaDetails(
          title: recognized.title.isNotEmpty ? recognized.title : newSong,
          artist: recognized.artist.isNotEmpty ? recognized.artist : station.name,
          artUri: _currentArtwork ?? stationLogo,
        );
        notifyListeners();

        // Start 3.5 minute auto-clear timer
        _startManualSongTimer();

        if (_currentArtwork == null && !(_isItunesDisabledCheck?.call(stationId) ?? false)) {
          try {
            final artwork = await ItunesService.getArtwork(newSong);
            if (artwork != null && _currentSong == newSong) {
              _currentArtwork = artwork;
              _handler.updateArtwork(artwork);
              notifyListeners();
            }
          } catch (_) {}
        }
        return null;
      } else {
        return result.errorMessage ?? 'Nie udało się rozpoznać utworu.';
      }
    } catch (e) {
      print('DEBUG [PlayerProvider]: Błąd rozpoznawania: $e');
      return 'Wystąpił błąd podczas rozpoznawania: $e';
    } finally {
      _isRecognizing = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _handler.pause();
    _isPlaying = false;
    _updateTile();
    notifyListeners();
  }

  Future<void> resume() => _handler.play();

  /// Completely stops playback, clears the current station, and dismisses the notification.
  Future<void> stop() async {
    _manualSongTimer?.cancel();
    _manualSongTimer = null;
    _manualSongExpiresAt = null;
    await _handler.stop();
    _currentStation = null;
    _isManualSong = false;
    _currentSong = null;
    _currentArtwork = null;
    _isPlaying = false;
    _isBuffering = false;
    _updateTile();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_currentStation == null) return;
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  void refreshArtwork() {
    if (_currentStation == null) return;
    final isItunesDisabled = _isItunesDisabledCheck?.call(_currentStation!.stationUuid) ?? false;
    
    if (_currentArtwork != null && !isItunesDisabled) {
      _handler.updateArtwork(_currentArtwork);
    } else {
      final customLogo = _customLogoGetter?.call(_currentStation!.stationUuid);
      _handler.updateArtwork(customLogo ?? _currentStation!.bestFavicon);
    }
  }

  bool get hasStation => _currentStation != null;

  bool isCurrentStation(String stationUuid) =>
      _currentStation?.stationUuid == stationUuid;

  /// Update the Quick Settings tile with current station info.
  void _updateTile() {
    try {
      _tileChannel.invokeMethod('updateTile', {
        'isPlaying': _isPlaying,
        'stationName': _currentStation?.name ?? '',
      });
    } catch (_) {
      // Tile may not be available — ignore.
    }
  }

  @override
  void dispose() {
    _manualSongTimer?.cancel();
    _handler.player.dispose();
    super.dispose();
  }
}
