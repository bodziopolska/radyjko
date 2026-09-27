import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import '../screens/player_screen.dart';
import '../l10n/app_strings.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final radioProvider = context.watch<RadioProvider>();
    final station = playerProvider.currentStation;

    if (station == null) return const SizedBox.shrink();
    
    final customLogo = radioProvider.getCustomLogo(station.stationUuid);
    final displayLogo = customLogo ?? station.bestFavicon;



    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
              // Station favicon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: displayLogo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: displayLogo,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Icon(
                            Icons.radio,
                            color: theme.colorScheme.primary,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.radio,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.radio,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Station info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Animated equalizer or status text
                        if (playerProvider.isPlaying) ...[
                          _EqualizerAnimation(color: theme.colorScheme.primary),
                          if (playerProvider.currentSong != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 16,
                                child: playerProvider.currentSong!.length > 25
                                    ? Marquee(
                                        text: playerProvider.currentSong!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        scrollAxis: Axis.horizontal,
                                        blankSpace: 30.0,
                                        velocity: 30.0,
                                        pauseAfterRound: const Duration(seconds: 2),
                                      )
                                    : Text(
                                        playerProvider.currentSong!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ),
                          ],
                        ] else if (playerProvider.isBuffering)
                          Text(
                            strings.buffering,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else if (playerProvider.hasError)
                          Text(
                            strings.connectionError,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          )
                        else
                          Text(
                            strings.stopped,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (station.bitrate > 0)
                          Text(
                            '${station.bitrate} kbps',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Play/Pause button
              if (playerProvider.isBuffering)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    playerProvider.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => playerProvider.togglePlayPause(),
                ),

              // Stop button
              IconButton(
                icon: Icon(
                  Icons.stop_circle_outlined,
                  size: 28,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: strings.stopPlayback,
                onPressed: () => playerProvider.stop(),
              ),
              // Expand hint
              Icon(
                Icons.keyboard_arrow_up,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Animated equalizer bars that pulse when music is playing.
class _EqualizerAnimation extends StatefulWidget {
  final Color color;
  const _EqualizerAnimation({required this.color});

  @override
  State<_EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<_EqualizerAnimation>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (i) => AnimationController(
        duration: Duration(milliseconds: 400 + i * 150),
        vsync: this,
      )..repeat(reverse: true),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 3, end: 14).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              width: 3,
              height: _animations[i].value,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          },
        );
      }),
    );
  }
}



