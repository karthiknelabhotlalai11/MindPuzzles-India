import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class GameState {
  static late SharedPreferences _prefs;
  static const int freeLevels = 10;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Level tracking
  static int getSudokuLevel() => _prefs.getInt('sudoku_level') ?? 1;
  static int getPatchesLevel() => _prefs.getInt('patches_level') ?? 1;
  static int getZipLevel() => _prefs.getInt('zip_level') ?? 1;

  static Future<void> incrementSudokuLevel() async =>
      await _prefs.setInt('sudoku_level', getSudokuLevel() + 1);
  static Future<void> incrementPatchesLevel() async =>
      await _prefs.setInt('patches_level', getPatchesLevel() + 1);
  static Future<void> incrementZipLevel() async =>
      await _prefs.setInt('zip_level', getZipLevel() + 1);

  // Check if game requires subscription
  static bool sudokuNeedsSubscription() => getSudokuLevel() > freeLevels;
  static bool patchesNeedsSubscription() => getPatchesLevel() > freeLevels;
  static bool zipNeedsSubscription() => getZipLevel() > freeLevels;

  // Subscription management
  static bool isSubscribed() => _prefs.getBool('is_subscribed') ?? false;

  static Future<bool> activateSubscription(String key) async {
    final validKeys = _prefs.getStringList('valid_keys') ?? [];
    if (validKeys.contains(key.trim().toUpperCase())) {
      await _prefs.setBool('is_subscribed', true);
      await _prefs.setString('activated_key', key.trim().toUpperCase());
      return true;
    }
    return false;
  }

  // Owner adds valid keys (in a real app this would be server-side)
  static Future<void> addValidKey(String key) async {
    final keys = _prefs.getStringList('valid_keys') ?? [];
    keys.add(key.trim().toUpperCase());
    await _prefs.setStringList('valid_keys', keys);
  }

  // Generate a unique payment reference for WhatsApp
  static String generatePaymentReference() {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return 'MP${List.generate(8, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  // Scores and stats
  static int getTotalScore() => _prefs.getInt('total_score') ?? 0;
  static Future<void> addScore(int points) async =>
      await _prefs.setInt('total_score', getTotalScore() + points);

  // High scores per game
  static int getSudokuBest() => _prefs.getInt('sudoku_best') ?? 0;
  static int getPatchesBest() => _prefs.getInt('patches_best') ?? 0;
  static int getZipBest() => _prefs.getInt('zip_best') ?? 0;

  static Future<void> updateSudokuBest(int score) async {
    if (score > getSudokuBest()) await _prefs.setInt('sudoku_best', score);
  }
}
