import 'package:flutter/material.dart';

/// Brand, layout, and status colors that adapt to light / dark mode.
@immutable
class KoditrackColors extends ThemeExtension<KoditrackColors> {
  final Color pageBackground;
  final Color navBarBackground;
  final Color cardBackground;
  final Color inputFill;
  final Color chipBackground;
  final Color brandGreen;
  final Color brandGreenLight;
  final Color brandGreenDark;
  final Color borderSubtle;
  final Color accentTeal;
  final Color accentTealLight;
  final Color accentTealDark;
  final Color accentAmber;
  final Color accentAmberLight;
  final Color accentAmberDark;
  final Color accentRed;
  final Color accentRedLight;
  final Color accentRedDark;
  final Color onPrimaryButton;
  final Color accentBlue;
  final Color accentBlueLight;

  const KoditrackColors({
    required this.pageBackground,
    required this.navBarBackground,
    required this.cardBackground,
    required this.inputFill,
    required this.chipBackground,
    required this.brandGreen,
    required this.brandGreenLight,
    required this.brandGreenDark,
    required this.borderSubtle,
    required this.accentTeal,
    required this.accentTealLight,
    required this.accentTealDark,
    required this.accentAmber,
    required this.accentAmberLight,
    required this.accentAmberDark,
    required this.accentRed,
    required this.accentRedLight,
    required this.accentRedDark,
    required this.onPrimaryButton,
    required this.accentBlue,
    required this.accentBlueLight,
  });

  static const light = KoditrackColors(
    pageBackground: Color(0xFFF7F4EF),
    navBarBackground: Color(0xFFFAF8F4),
    cardBackground: Colors.white,
    inputFill: Colors.white,
    chipBackground: Color(0xFFF0F0F0),
    brandGreen: Color(0xFF2E6F40),
    brandGreenLight: Color(0xFFE1F5EE),
    brandGreenDark: Color(0xFF085041),
    borderSubtle: Color(0x1A000000),
    accentTeal: Color(0xFF1D9E75),
    accentTealLight: Color(0xFFE1F5EE),
    accentTealDark: Color(0xFF085041),
    accentAmber: Color(0xFFBA7517),
    accentAmberLight: Color(0xFFFAEEDA),
    accentAmberDark: Color(0xFF633806),
    accentRed: Color(0xFFE24B4A),
    accentRedLight: Color(0xFFFCEBEB),
    accentRedDark: Color(0xFF791F1F),
    onPrimaryButton: Colors.white,
    accentBlue: Color(0xFF185FA5),
    accentBlueLight: Color(0xFFE6F1FB),
  );

  static const dark = KoditrackColors(
    pageBackground: Color(0xFF121412),
    navBarBackground: Color(0xFF1A1D1A),
    cardBackground: Color(0xFF222622),
    inputFill: Color(0xFF2C302C),
    chipBackground: Color(0xFF2E332E),
    brandGreen: Color(0xFF5CB87A),
    brandGreenLight: Color(0xFF1E3D2A),
    brandGreenDark: Color(0xFF9AE0B0),
    borderSubtle: Color(0x24FFFFFF),
    accentTeal: Color(0xFF4DB896),
    accentTealLight: Color(0xFF1A3328),
    accentTealDark: Color(0xFF7DD4B0),
    accentAmber: Color(0xFFD4A84B),
    accentAmberLight: Color(0xFF3D3018),
    accentAmberDark: Color(0xFFE8C078),
    accentRed: Color(0xFFE85A59),
    accentRedLight: Color(0xFF3D2222),
    accentRedDark: Color(0xFFF09090),
    onPrimaryButton: Colors.white,
    accentBlue: Color(0xFF7EB8E8),
    accentBlueLight: Color(0xFF1A2D3D),
  );

  @override
  KoditrackColors copyWith({
    Color? pageBackground,
    Color? navBarBackground,
    Color? cardBackground,
    Color? inputFill,
    Color? chipBackground,
    Color? brandGreen,
    Color? brandGreenLight,
    Color? brandGreenDark,
    Color? borderSubtle,
    Color? accentTeal,
    Color? accentTealLight,
    Color? accentTealDark,
    Color? accentAmber,
    Color? accentAmberLight,
    Color? accentAmberDark,
    Color? accentRed,
    Color? accentRedLight,
    Color? accentRedDark,
    Color? onPrimaryButton,
    Color? accentBlue,
    Color? accentBlueLight,
  }) {
    return KoditrackColors(
      pageBackground: pageBackground ?? this.pageBackground,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      inputFill: inputFill ?? this.inputFill,
      chipBackground: chipBackground ?? this.chipBackground,
      brandGreen: brandGreen ?? this.brandGreen,
      brandGreenLight: brandGreenLight ?? this.brandGreenLight,
      brandGreenDark: brandGreenDark ?? this.brandGreenDark,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accentTeal: accentTeal ?? this.accentTeal,
      accentTealLight: accentTealLight ?? this.accentTealLight,
      accentTealDark: accentTealDark ?? this.accentTealDark,
      accentAmber: accentAmber ?? this.accentAmber,
      accentAmberLight: accentAmberLight ?? this.accentAmberLight,
      accentAmberDark: accentAmberDark ?? this.accentAmberDark,
      accentRed: accentRed ?? this.accentRed,
      accentRedLight: accentRedLight ?? this.accentRedLight,
      accentRedDark: accentRedDark ?? this.accentRedDark,
      onPrimaryButton: onPrimaryButton ?? this.onPrimaryButton,
      accentBlue: accentBlue ?? this.accentBlue,
      accentBlueLight: accentBlueLight ?? this.accentBlueLight,
    );
  }

  @override
  KoditrackColors lerp(ThemeExtension<KoditrackColors>? other, double t) {
    if (other is! KoditrackColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return KoditrackColors(
      pageBackground: l(pageBackground, other.pageBackground),
      navBarBackground: l(navBarBackground, other.navBarBackground),
      cardBackground: l(cardBackground, other.cardBackground),
      inputFill: l(inputFill, other.inputFill),
      chipBackground: l(chipBackground, other.chipBackground),
      brandGreen: l(brandGreen, other.brandGreen),
      brandGreenLight: l(brandGreenLight, other.brandGreenLight),
      brandGreenDark: l(brandGreenDark, other.brandGreenDark),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      accentTeal: l(accentTeal, other.accentTeal),
      accentTealLight: l(accentTealLight, other.accentTealLight),
      accentTealDark: l(accentTealDark, other.accentTealDark),
      accentAmber: l(accentAmber, other.accentAmber),
      accentAmberLight: l(accentAmberLight, other.accentAmberLight),
      accentAmberDark: l(accentAmberDark, other.accentAmberDark),
      accentRed: l(accentRed, other.accentRed),
      accentRedLight: l(accentRedLight, other.accentRedLight),
      accentRedDark: l(accentRedDark, other.accentRedDark),
      onPrimaryButton: l(onPrimaryButton, other.onPrimaryButton),
      accentBlue: l(accentBlue, other.accentBlue),
      accentBlueLight: l(accentBlueLight, other.accentBlueLight),
    );
  }
}

extension KoditrackThemeContext on BuildContext {
  KoditrackColors get kt =>
      Theme.of(this).extension<KoditrackColors>() ?? KoditrackColors.light;

  ColorScheme get cs => Theme.of(this).colorScheme;
}

class KoditrackTheme {
  static const _seed = Color(0xFF2E6F40);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: KoditrackColors.light.navBarBackground,
      surfaceContainerLowest: KoditrackColors.light.pageBackground,
    );
    return _base(scheme, KoditrackColors.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: KoditrackColors.dark.navBarBackground,
      surfaceContainerLowest: KoditrackColors.dark.pageBackground,
    );
    return _base(scheme, KoditrackColors.dark);
  }

  static ThemeData _base(ColorScheme scheme, KoditrackColors ext) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: ext.pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: ext.pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: ext.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: ext.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.brandGreen, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: ext.borderSubtle),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ext.brandGreen,
          foregroundColor: ext.onPrimaryButton,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ext.brandGreen,
        foregroundColor: ext.onPrimaryButton,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: ext.brandGreen.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: ext.brandGreen, fontSize: 12);
          }
          return TextStyle(color: scheme.onSurfaceVariant, fontSize: 12);
        }),
      ),
      extensions: [ext],
    );
  }
}
