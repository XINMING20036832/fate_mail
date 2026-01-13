import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStore {
  static const _kProfile = 'profile';
  static const _kUserId = 'userId';
  static const _kWallet = 'wallet';
  static const _kPending = 'pending_requests';
  static const _kIncoming = 'incoming_requests';
  static const _kMailbox = 'mailbox';

  static Future<String> getOrCreateUserId() async {
    final sp = await SharedPreferences.getInstance();
    final existing = sp.getString(_kUserId);
    if (existing != null && existing.isNotEmpty) return existing;
    final uid = DateTime.now().millisecondsSinceEpoch.toString();
    await sp.setString(_kUserId, uid);
    return uid;
  }

  static Future<Profile?> loadProfile() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProfile);
    if (raw == null) return null;

    final p = Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (p == null) return null;

    // 自动根据时间锁定“命运坐标”（24h 过期 或 已改过一次）
    final now = DateTime.now().millisecondsSinceEpoch;
    bool shouldLock = p.locked;
    if (p.boundAtMs > 0) {
      final expired = (now - p.boundAtMs) > 24 * 60 * 60 * 1000;
      final usedUp = p.coordEditCount >= 1;
      shouldLock = expired || usedUp;
    }

    if (shouldLock != p.locked) {
      final next = p.copyWith(locked: shouldLock);
      await sp.setString(_kProfile, jsonEncode(next.toJson()));
      return next;
    }
    return p;
  }

  static Future<void> saveProfile(Profile profile) async {(Profile profile) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProfile, jsonEncode(profile.toJson()));
  }

  static Future<StampWallet> loadWallet() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kWallet);
    if (raw == null) return StampWallet(0);
    return StampWallet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveWallet(StampWallet wallet) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kWallet, jsonEncode(wallet.toJson()));
  }

  static Future<List<Map<String, dynamic>>> _loadList(String key) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(key);
    if (raw == null) return <Map<String, dynamic>>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, jsonEncode(list));
  }

  static Future<List<MailRequest>> loadPending() async {
    final list = await _loadList(_kPending);
    return list.map(MailRequest.fromJson).toList();
  }

  static Future<void> savePending(List<MailRequest> items) async {
    await _saveList(_kPending, items.map((e) => e.toJson()).toList());
  }

  static Future<List<MailRequest>> loadIncoming() async {
    final list = await _loadList(_kIncoming);
    return list.map(MailRequest.fromJson).toList();
  }

  static Future<void> saveIncoming(List<MailRequest> items) async {
    await _saveList(_kIncoming, items.map((e) => e.toJson()).toList());
  }

  static Future<List<MailItem>> loadMailbox() async {
    final list = await _loadList(_kMailbox);
    return list.map(MailItem.fromJson).toList();
  }

  static Future<void> saveMailbox(List<MailItem> items) async {
    await _saveList(_kMailbox, items.map((e) => e.toJson()).toList());
  }

  static Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kProfile);
    await sp.remove(_kWallet);
    await sp.remove(_kUserId);
    await sp.remove(_kPending);
    await sp.remove(_kIncoming);
    await sp.remove(_kMailbox);
  }
}
