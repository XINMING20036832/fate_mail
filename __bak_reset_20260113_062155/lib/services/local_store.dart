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
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveProfile(Profile profile) async {
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
}
