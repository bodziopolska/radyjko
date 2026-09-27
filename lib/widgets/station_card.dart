import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import '../l10n/app_strings.dart';

class StationCard extends StatelessWidget {
  final RadioStation station;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerProvider = context.watch<PlayerProvider>();
    final radioProvider = context.watch<RadioProvider>();
    final isCurrentStation =
        playerProvider.isCurrentStation(station.stationUuid);
    final isPlaying = isCurrentStation && playerProvider.isPlaying;
    final isBuffering = isCurrentStation && playerProvider.isBuffering;
    final isFavorite = radioProvider.isFavorite(station.stationUuid);
    final strings = AppStrings.of(context);

    return Card(
      elevation: isCurrentStation ? 3 : 1,
      color: isCurrentStation
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => playerProvider.playStation(station),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Station favicon — always show station logo, never iTunes artwork
              _buildFavicon(theme, isPlaying, isBuffering, null, radioProvider.getCustomLogo(station.stationUuid)),
              const SizedBox(width: 12),

              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Station name
                    Text(
                      station.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            isCurrentStation ? FontWeight.bold : FontWeight.w500,
                        color: isCurrentStation
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Country and language
                    Row(
                      children: [
                        Text(
                          station.countryFlag,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            station.country.isNotEmpty
                                ? station.country
                                : 'Nieznany',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (station.language.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.language,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              station.language.split(',').first.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Tags and metadata chips
                    _buildMetadataRow(theme),
                  ],
                ),
              ),

              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/Stop button
                  _buildPlayButton(
                      context, theme, isPlaying, isBuffering, isCurrentStation),
                  const SizedBox(height: 4),
                  // Favorite button
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    tooltip: isFavorite ? strings.removeFromFavoritesAction : strings.addToFavorites,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => radioProvider.toggleFavorite(station),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavicon(ThemeData theme, bool isPlaying, bool isBuffering, String? artworkUrl, String? customLogo) {
    final hasArtwork = artworkUrl != null && artworkUrl.isNotEmpty;
    final fallbackUrl = customLogo ?? station.bestFavicon;
    final displayUrl = hasArtwork ? artworkUrl : fallbackUrl;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: displayUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: displayUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain, // Fit inside without cropping
                    placeholder: (context, url) => Icon(
                      Icons.radio,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.radio,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                  )
                : Icon(
                    Icons.radio,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
          ),
        ),
        // Online/offline indicator dot
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: station.isOnline ? Colors.green : Colors.red.shade400,
              border: Border.all(
                color: theme.colorScheme.surface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(ThemeData theme) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        // Bitrate badge
        if (station.bitrate > 0)
          _buildBadge(
            '${station.bitrate} kbps',
            theme.colorScheme.tertiaryContainer,
            theme.colorScheme.onTertiaryContainer,
            theme,
          ),
        // Codec badge
        if (station.codec.isNotEmpty)
          _buildBadge(
            station.codec,
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
            theme,
          ),
        // First 2 tags
        ...station.tagList.take(2).map(
              (tag) => _buildBadge(
                tag,
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.onSurfaceVariant,
                theme,
              ),
            ),
      ],
    );
  }

  Widget _buildBadge(
    String label,
    Color backgroundColor,
    Color textColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildPlayButton(
    BuildContext context,
    ThemeData theme,
    bool isPlaying,
    bool isBuffering,
    bool isCurrentStation,
  ) {
    if (isBuffering) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_filled,
        color: isCurrentStation
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        size: 32,
      ),
      onPressed: () {
        final playerProvider =
            Provider.of<PlayerProvider>(context, listen: false);
        if (isCurrentStation && isPlaying) {
          playerProvider.stop();
        } else {
          playerProvider.playStation(station);
        }
      },
    );
  }
}
