import re

path = r'D:\radyjko\lib\providers\radio_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add to toggleFavorite
content = content.replace('await _saveFavorites();', 'await _saveFavorites();\n    _syncFavoritesToCloud();')

# Add sync methods at the end
sync_methods = '''
  Future<void> syncFavoritesFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final cloudFavs = List<String>.from(doc.data()?['favorites'] ?? []);
        _favoriteIds.addAll(cloudFavs);
        await _saveFavorites();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Cloud sync read error: \");
    }
  }

  Future<void> _syncFavoritesToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'favorites': _favoriteIds.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Cloud sync write error: \");
    }
  }
}
'''

content = re.sub(r'\}\s*$', sync_methods, content)

# Add listener in init
init_listener = '''
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        syncFavoritesFromCloud();
      }
    });
    
    await _loadFavorites();
'''
content = content.replace('await _loadFavorites();', init_listener)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
