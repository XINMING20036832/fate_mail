import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStore {
  static const _kProfile = 'profile_json';
  static const _kUserId = 'user_id';
  static const _kWallet = 'wallet_json';
  static const _kPending = 'pending_requests';
  static const _kIncoming = 'incoming_requests';
  static const _kMailbox = 'mailbox_items';

  static Future<String> getOrCreateUserId() async {
    final sp = await SharedPreferences.getInstance();
    final existing = sp.getString(_kUserId);
    if (existing != null && existing.isNotEmpty) return existing;
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = 'U-$now';
    await sp.setString(_kUserId, uid);
    return uid;
  }

  static Future<Profile?> loadProfile() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProfile);
    if (raw == null || raw.isEmpty) return null;
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveProfile(Profile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProfile, jsonEncode(p.toJson()));
  }

  static Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
  }

  static Future<StampWallet> loadWallet() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kWallet);
    if (raw == null || raw.isEmpty) return StampWallet(0);
    return StampWallet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveWallet(StampWallet w) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kWallet, jsonEncode(w.toJson()));
  }

  static Future<List<MailRequest>> loadPending() async {
    return _loadList(_kPending, MailRequest.fromJson);
  }

  static Future<void> savePending(List<MailRequest> items) async {
    await _saveList(_kPending, items.map((e) => e.toJson()).toList());
  }

  static Future<List<MailRequest>> loadIncoming() async {
    return _loadList(_kIncoming, MailRequest.fromJson);
  }

  static Future<void> saveIncoming(List<MailRequest> items) async {
    await _saveList(_kIncoming, items.map((e) => e.toJson()).toList());
  }

  static Future<List<MailItem>> loadMailbox() async {
    return _loadList(_kMailbox, MailItem.fromJson);
  }

  static Future<void> saveMailbox(List<MailItem> items) async {
    await _saveList(_kMailbox, items.map((e) => e.toJson()).toList());
  }

  static Future<List<T>> _loadList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(key);
    if (raw == null || raw.isEmpty) return <T>[];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(fromJson).toList();
  }

  static Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, jsonEncode(list));
  }
}
