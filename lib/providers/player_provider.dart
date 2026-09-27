import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/radio_station.dart';
import '../services/audio_handler.dart';
import '../services/itunes_service.dart';
import '../services/radio_api_service.dart';

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

  bool Function(String)? _isItunesDisabledCheck;
  void setItunesDisabledChecker(bool Function(String) checker) {
    _isItunesDisabledCheck = checker;
  }

  String? Function(String)? _customLogoGetter;
  void setCustomLogoGetter(String? Function(String) getter) {
    _customLogoGetter = getter;
  }

  PlayerProvider(this._handler) {
    _handler.player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering || state.processingState == ProcessingState.loading;
      _updateTile();
      notifyListeners();
    });

    _handler.player.playbackEventStream.listen((event) {}, onError: (e) {
      _hasError = true;
      _errorMessage = 'Nie udało się odtworzyć stacji';
      _isPlaying = false;
      _updateTile();
      notifyListeners();
    });

    _handler.mediaItem.listen((item) async {
      if (item?.displayTitle != null && item!.displayTitle!.isNotEmpty) {
        final newSong = item.displayTitle;
        if (_currentSong != newSong) {
          _currentSong = newSong;
          _currentArtwork = null;
          final stationId = _currentStation?.stationUuid ?? '';
          final customLogo = _customLogoGetter?.call(stationId);
          _handler.updateArtwork(customLogo ?? _currentStation?.bestFavicon ?? '');
          notifyListeners();
          
          // Only fetch iTunes artwork if not disabled for this station
          if (!(_isItunesDisabledCheck?.call(stationId) ?? false)) {
            try {
              final artwork = await ItunesService.getArtwork(newSong!);
              if (artwork != null && _currentSong == newSong) {
                _currentArtwork = artwork;
                _handler.updateArtwork(artwork);
                notifyListeners();
              }
            } catch (_) {}
          }
        }
      } else {
        if (_currentSong != null || _currentArtwork != null) {
          _currentSong = null;
          _currentArtwork = null;
          final stationId = _currentStation?.stationUuid ?? '';
          final customLogo = _customLogoGetter?.call(stationId);
          _handler.updateArtwork(customLogo ?? _currentStation?.bestFavicon ?? '');
          notifyListeners();
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

    _currentStation = station;
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

  Future<void> pause() => _handler.pause();
  Future<void> resume() => _handler.play();

  Future<void> stop() async {
    await _handler.stop();
    _currentStation = null;
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
      // Tile may not be available â€” ignore.
    }
  }

  @override
  void dispose() {
    _handler.player.dispose();
    super.dispose();
  }
}











