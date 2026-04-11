import 'package:flutter/material.dart';
import '../main.dart' show userThemeNotifier;

// ─────────────────────────────────────────────────────────────────────────────
// userPageRoute<T>()
// Use this instead of MaterialPageRoute whenever navigating to a new user-
// facing page from within the user subtree.  It re-wraps the destination with
// the same UserTheme + reactive Theme overlay so dark/light mode propagates
// across Navigator route boundaries.
//
// Usage:
//   Navigator.push(context, userPageRoute((_) => const SomePage()));
// ─────────────────────────────────────────────────────────────────────────────

Route<T> userPageRoute<T>(WidgetBuilder builder) {
  return MaterialPageRoute<T>(
    builder: (context) => UserTheme(
      notifier: userThemeNotifier,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: userThemeNotifier,
        builder: (ctx, mode, child) => Theme(
          data: mode == ThemeMode.dark
              ? UserTheme.darkTheme
              : UserTheme.lightTheme,
          child: child!,
        ),
        child: Builder(builder: builder),
      ),
    ),
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extension — semantic colour helpers
// Usage:  context.uiBackground  /  context.uiPrimary  etc.
// Resolves automatically from the nearest Theme, so dark/light is transparent.
// ─────────────────────────────────────────────────────────────────────────────

extension UserThemeColors on BuildContext {
  bool get _dark => Theme.of(this).brightness == Brightness.dark;

  /// Main scaffold / page background
  Color get uiBackground =>
      _dark ? const Color(0xFF121212) : Colors.white;

  /// Card / tile / sheet surface
  Color get uiSurface =>
      _dark ? const Color(0xFF1E1E1E) : Colors.white;

  /// Subtle fill — search bar, inactive tiles
  Color get uiFill =>
      _dark ? const Color(0xFF2A2A2A) : const Color(0xFFF4F4F6);

  /// Brand / action primary (blue)
  Color get uiPrimary =>
      _dark ? const Color(0xFF7B7BFF) : const Color(0xFF1A1AE6);

  /// High-emphasis text
  Color get uiTextPrimary =>
      _dark ? Colors.white : Colors.black87;

  /// Medium-emphasis text
  Color get uiTextSecondary =>
      _dark ? Colors.grey.shade400 : Colors.black54;

  /// Low-emphasis text / placeholders
  Color get uiTextHint =>
      _dark ? Colors.grey.shade600 : Colors.black38;

  /// Dividers and thin borders
  Color get uiDivider =>
      _dark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

  /// Standard icon colour (non-primary)
  Color get uiIcon =>
      _dark ? Colors.grey.shade400 : Colors.black45;
}

// ─────────────────────────────────────────────────────────────────────────────
// UserThemeNotifier
// Holds the single source of truth for the user-facing dark/light mode.
// ─────────────────────────────────────────────────────────────────────────────

class UserThemeNotifier extends ValueNotifier<ThemeMode> {
  UserThemeNotifier() : super(ThemeMode.light);

  bool get isDark => value == ThemeMode.dark;

  void toggle() {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserTheme  (InheritedWidget wrapper)
// Place this above the user-facing subtree so any descendant can read/toggle
// the theme with  UserTheme.of(context).
// ─────────────────────────────────────────────────────────────────────────────

class UserTheme extends InheritedNotifier<UserThemeNotifier> {
  const UserTheme({
    super.key,
    required super.notifier,
    required super.child,
  });

  /// Access the notifier from any widget in the user subtree.
  static UserThemeNotifier of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<UserTheme>();
    assert(result != null, 'No UserTheme found in context');
    return result!.notifier!;
  }

  // ── Light theme ────────────────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
        colorSchemeSeed: const Color(0xFF1A1AE6),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1A1AE6),
          unselectedItemColor: Colors.grey,
        ),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFEEEEEE),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      );

  // ── Dark theme ─────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        colorSchemeSeed: const Color(0xFF6C6CFF),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF7B7BFF),
          unselectedItemColor: Colors.grey,
        ),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: const Color(0xFF2C2C2C),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A2A),
        ),
      );
}
