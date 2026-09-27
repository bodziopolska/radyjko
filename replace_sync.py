import re

path = r'D:\radyjko\lib\providers\radio_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace syncFavoritesFromCloud
pattern_read = r'Future<void> syncFavoritesFromCloud\(\) async \{.*?(?=\s+Future<void> _syncFavoritesToCloud)'
replace_read = '''Future<void> syncFavoritesFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final cloudFavs = List<String>.from(doc.data()?['favorites_json'] ?? []);
        final cloudStations = cloudFavs.map((e) => RadioStation.fromJsonString(e)).toList();
        
        for (var station in cloudStations) {
          if (!_favoriteIds.contains(station.stationUuid)) {
            _favoriteIds.add(station.stationUuid);
            _favoriteStations.add(station);
          }
        }
        await _saveFavorites();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Cloud sync read error: \");
    }
  }'''
content = re.sub(pattern_read, replace_read, content, flags=re.DOTALL)

# Replace _syncFavoritesToCloud
pattern_write = r'Future<void> _syncFavoritesToCloud\(\) async \{.*?(?=\s+\})'
replace_write = '''Future<void> _syncFavoritesToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final List<String> encoded = _favoriteStations.map((s) => s.toJsonString()).toList();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'favorites_json': encoded,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Cloud sync write error: \");
    }
  }'''
content = re.sub(pattern_write, replace_write, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
