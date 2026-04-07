import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hoc_vien_model.dart';
import '../models/giang_vien_model.dart';
import 'api_service.dart';
import 'notification_service.dart';

/// Singleton giữ trạng thái đăng nhập trong toàn app.
class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();

  String? token;
  String? userid;
  HocVien? hocVien;
  GiangVien? giangVien;

  bool get isGiangVien => giangVien != null && hocVien == null;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  /// Lưu toàn bộ session vào SharedPreferences
  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('auth_token', token!);
    if (userid != null) await prefs.setString('userid', userid!);
    if (giangVien != null) {
      await prefs.setString('user_type', 'gv');
      await prefs.setString('user_data', jsonEncode(giangVien!.toJson()));
    } else if (hocVien != null) {
      await prefs.setString('user_type', 'hv');
      await prefs.setString('user_data', jsonEncode(hocVien!.toJson()));
    }
  }

  /// Khôi phục session khi mở lại app
  Future<bool> tryRestore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    if (savedToken == null || savedToken.isEmpty) return false;

    token = savedToken;
    userid = prefs.getString('userid');

    final userType = prefs.getString('user_type');
    final userDataStr = prefs.getString('user_data');
    if (userType != null && userDataStr != null) {
      try {
        final json = jsonDecode(userDataStr) as Map<String, dynamic>;
        if (userType == 'gv') {
          giangVien = GiangVien.fromJson(json);
          hocVien = null;
        } else {
          hocVien = HocVien.fromJson(json);
          giangVien = null;
        }
      } catch (_) {}
    }
    return true;
  }

  /// Xóa session khi đăng xuất
  Future<void> clear() async {
    // Xóa FCM token trước khi clear session
    final id = hocVien?.id.toString() ?? giangVien?.id.toString();
    if (id != null) {
      await NotificationService.instance.unregisterToken(id);
    }
    token = null;
    userid = null;
    hocVien = null;
    giangVien = null;
    ApiService.clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('userid');
    await prefs.remove('user_type');
    await prefs.remove('user_data');
  }
}
