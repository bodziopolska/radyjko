import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../providers/player_provider.dart';
import '../l10n/app_strings.dart';
import '../widgets/station_card.dart';
import '../widgets/station_shimmer.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/player_bar.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import '../services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final radioProvider = context.read<RadioProvider>();
      final playerProvider = context.read<PlayerProvider>();
      await radioProvider.init();
      playerProvider.setItunesDisabledChecker(radioProvider.isItunesDisabled);
      playerProvider.setCustomLogoGetter(radioProvider.getCustomLogo);
      
      // Sprawdź dostępność aktualizacji
      if (mounted) {
        UpdateService.checkAndPrompt(context);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<RadioProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildBrowseTab(theme, strings),
                const FavoritesScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
          const PlayerBar(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: strings.browse,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: strings.favorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: strings.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTab(ThemeData theme, AppStrings strings) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Row(
              children: [
                Icon(
                  Icons.radio,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '${strings.appName} (V2)',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: strings.searchHint,
                      leading: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.search),
                      ),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<RadioProvider>()
                                  .setSearchQuery('');
                            },
                          ),
                        Badge(
                          isLabelVisible: context
                              .watch<RadioProvider>()
                              .hasActiveFilters,
                          child: IconButton(
                            icon: const Icon(Icons.tune),
                            tooltip: AppStrings.of(context).filterStations,
                            onPressed: () => _showFilterSheet(context),
                          ),
                        ),
                      ],
                      onSubmitted: (query) {
                        _debounce?.cancel();
                        context.read<RadioProvider>().setSearchQuery(query);
                      },
                      onChanged: (query) {
                        setState(() {});
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          context.read<RadioProvider>().setSearchQuery(query);
                        });
                      },
                    ),
                  ),
                  _buildCategoryChips(theme, strings),
                ],
              ),
            ),
          ),
        ];
      },
      body: _buildStationList(theme, strings),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, AppStrings strings) {
    final provider = context.watch<RadioProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _CategoryChip(
            label: strings.popular,
            selected: provider.category == StationCategory.top &&
                !provider.hasActiveFilters &&
                provider.searchQuery.isEmpty,
            onSelected: () {
              _searchController.clear();
              provider.resetFilters();
            },
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: strings.trending,
            selected: provider.category == StationCategory.trending,
            onSelected: () {
              _searchController.clear();
              provider.setCategory(StationCategory.trending);
            },
          ),
          const SizedBox(width: 8),
          if (provider.hasActiveFilters || provider.searchQuery.isNotEmpty)
            _CategoryChip(
              label: strings.results,
              selected: provider.category == StationCategory.search,
              onSelected: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildStationList(ThemeData theme, AppStrings strings) {
    final provider = context.watch<RadioProvider>();

    if (provider.isLoading) {
      return const StationShimmer();
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              strings.loadFailed,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              strings.checkConnection,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(strings.tryAgain),
              onPressed: () => provider.loadStations(),
            ),
          ],
        ),
      );
    }

    if (provider.stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              strings.noResults,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              strings.tryChangingFilters,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadStations(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: provider.stations.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.stations.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: provider.isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: StationCard(station: provider.stations[index]),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const FilterSheet(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}


