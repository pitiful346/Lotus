import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LotusSearchHistoryStore {
  Future<List<String>> load();

  Future<void> save(List<String> queries);
}

final class SharedPreferencesLotusSearchHistoryStore
    implements LotusSearchHistoryStore {
  SharedPreferencesLotusSearchHistoryStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const _key = 'lotus.search.history';

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<List<String>> load() async {
    final preferences = await _preferences();
    return List.unmodifiable(preferences.getStringList(_key) ?? const []);
  }

  @override
  Future<void> save(List<String> queries) async {
    final preferences = await _preferences();
    await preferences.setStringList(_key, queries);
  }
}
