import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplayMode {
  mobile,   // Responsive touch-friendly layout optimized for mobile (Dairy Management style)
  desktop,  // Previous desktop layout with zooming logic & fixed desktop canvas
}

class DisplayModeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_display_mode';
  DisplayMode _mode;

  DisplayMode get mode => _mode;
  bool get isMobile => _mode == DisplayMode.mobile;
  bool get isDesktop => _mode == DisplayMode.desktop;

  DisplayModeProvider({DisplayMode initialMode = DisplayMode.mobile}) : _mode = initialMode {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'desktop') {
        _mode = DisplayMode.desktop;
        notifyListeners();
      } else if (saved == 'mobile') {
        _mode = DisplayMode.mobile;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setDisplayMode(DisplayMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newMode == DisplayMode.desktop ? 'desktop' : 'mobile');
    } catch (_) {}
  }

  void toggleMode() {
    setDisplayMode(_mode == DisplayMode.mobile ? DisplayMode.desktop : DisplayMode.mobile);
  }
}
