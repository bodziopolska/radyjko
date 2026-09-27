import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import '../l10n/app_strings.dart';
import '../widgets/logo_editor_dialog.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final playerProvider = context.watch<PlayerProvider>();
    final radioProvider = context.watch<RadioProvider>();
    final station = playerProvider.currentStation;

    if (station == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(strings.noStationSelected)),
      );
    }

    final isPlaying = playerProvider.isPlaying;
    final isBuffering = playerProvider.isBuffering;
    final isFavorite = radioProvider.isFavorite(station.stationUuid);
    final currentSong = playerProvider.currentSong;
    final customLogo = radioProvider.getCustomLogo(station.stationUuid);
    final itunesDisabled = radioProvider.isItunesDisabled(station.stationUuid);
    final displayLogo = customLogo ?? station.bestFavicon;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? theme.colorScheme.error : null,
            ),
            tooltip: isFavorite ? strings.removeFromFavoritesAction : strings.addToFavorites,
            onPressed: () => radioProvider.toggleFavorite(station),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'toggle_itunes':
                  await radioProvider.toggleItunesForStation(station.stationUuid);
                  if (playerProvider.currentStation?.stationUuid == station.stationUuid) {
                    playerProvider.refreshArtwork();
                  }
                  break;
                case 'custom_logo':
                  final result = await showDialog<String>(
                      context: context,
                      builder: (ctx) => LogoEditorDialog(
                        station: station,
                        currentLogo: customLogo,
                      ),
                    );
                  if (result != null) {
                    await radioProvider.setCustomLogo(
                      station.stationUuid,
                      result.isEmpty ? null : result,
                    );
                    if (playerProvider.currentStation?.stationUuid == station.stationUuid) {
                      playerProvider.refreshArtwork();
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_itunes',
                child: Row(
                  children: [
                    Icon(itunesDisabled ? Icons.music_note : Icons.music_off, size: 20),
                    const SizedBox(width: 8),
                    Text(itunesDisabled ? strings.enableItunesCovers : strings.disableItunesCovers),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'custom_logo',
                child: Row(
                  children: [
                    const Icon(Icons.image, size: 20),
                    const SizedBox(width: 8),
                    Text(strings.setStationLogo),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big Logo
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ((itunesDisabled ? null : playerProvider.currentArtwork) ?? displayLogo).isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ((itunesDisabled ? null : playerProvider.currentArtwork) ?? displayLogo),
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Icon(
                                  Icons.radio,
                                  size: 100,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.radio,
                                  size: 100,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : Icon(
                                Icons.radio,
                                size: 100,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Station Name
              Text(
                station.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Current Song (with Marquee if long)
              SizedBox(
                height: 32,
                child: currentSong != null && currentSong.isNotEmpty
                    ? _buildSongText(currentSong, theme)
                    : Text(
                        playerProvider.isBuffering
                            ? strings.buffering
                            : (playerProvider.hasError ? strings.stationConnectError : ''),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              if (currentSong != null && currentSong.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final query = Uri.encodeComponent(currentSong);
                    final url = Uri.parse('spotify:search:$query');
                    final webUrl = Uri.parse('https://open.spotify.com/search/$query');
                    try {
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                      }
                    } catch (_) {
                      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.music_note, size: 18),
                  label: Text(strings.searchInSpotify),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1DB954),
                    side: const BorderSide(color: Color(0xFF1DB954)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                const SizedBox(height: 48),
              ],

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play/Pause Button
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: isBuffering
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 48,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            onPressed: () {
                                if (isPlaying) {
                                  playerProvider.pause();
                              } else {
                                playerProvider.playStation(station);
                              }
                            },
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Volume Slider
              Row(
                children: [
                  Icon(
                    playerProvider.volume == 0
                        ? Icons.volume_off
                        : (playerProvider.volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Slider(
                      value: playerProvider.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) => playerProvider.setVolume(val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Station Info Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (station.countryCode.isNotEmpty)
                    _buildInfoChip(Icons.public, station.countryCode, theme),
                  if (station.language.isNotEmpty)
                    _buildInfoChip(Icons.language, station.language, theme),
                  if (station.bitrate > 0)
                    _buildInfoChip(Icons.speed, '${station.bitrate} kbps', theme),
                  if (station.codec.isNotEmpty)
                    _buildInfoChip(Icons.audio_file, station.codec, theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongText(String text, ThemeData theme) {
    if (text.length > 30) {
      return Marquee(
        text: text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        blankSpace: 40.0,
        velocity: 30.0,
        startPadding: 10.0,
        pauseAfterRound: const Duration(seconds: 2),
      );
    } else {
      return Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      );
    }
  }
}












