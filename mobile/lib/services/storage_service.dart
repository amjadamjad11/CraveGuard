import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> get isDemoMode async => (await prefs).getBool(AppConstants.demoModeKey) ?? false;
  Future<void> setDemoMode(bool v) async => (await prefs).setBool(AppConstants.demoModeKey, v);

  Future<bool> get isOnboardingComplete async => (await prefs).getBool(AppConstants.onboardingCompleteKey) ?? false;
  Future<void> setOnboardingComplete(bool v) async => (await prefs).setBool(AppConstants.onboardingCompleteKey, v);

  Future<String?> getString(String key) async => (await prefs).getString(key);
  Future<void> setString(String key, String v) async => (await prefs).setString(key, v);
}
