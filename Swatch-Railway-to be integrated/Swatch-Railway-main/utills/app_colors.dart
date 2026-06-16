import 'package:flutter/material.dart';


const Color kRailwayBlue = Color(0xFF1565C0);

const Color kBackground = Colors.white;

const Color kSurface = Color(0xFFFFFFFF);

const Color kTextPrimary = Color(0xFF212121);

const Color kTextSecondary = Color(0xFF616161);

const Color kSuccessGreen = Color(0xFF2E7D32);
const Color kWarningOrange = Color(0xFFF57C00);
const Color kErrorRed = Color(0xFFC62828);

const Color kNeutralGrey = Color(0xFF616161);

const Color kSuccess = Color(0xFF2E7D32);

const Color kWarning = Color(0xFFF57C00);

const Color kInfo = Color(0xFF00796B);

const Color kDisabled = Color(0xFFBDBDBD);

const Color kAccentYellow = Color(0xFFFFD54F);

const Color kDivider = Color(0xFFEEEEEE);


final LinearGradient kRailwayBannerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kRailwayBlue, Color(0xFF0047B3)],
);


MaterialColor createMaterialColor(Color color) {
  final strengths = <double>[.05];
  final swatch = <int, Color>{};
  final r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}


final MaterialColor kPrimarySwatch = createMaterialColor(kRailwayBlue);


final ThemeData indianRailwayTheme = ThemeData(
  primarySwatch: kPrimarySwatch,
  primaryColor: kRailwayBlue,
  scaffoldBackgroundColor: kBackground,
  cardColor: kSurface,
  dividerColor: kDivider,
  iconTheme: const IconThemeData(color: kRailwayBlue),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kRailwayBlue,
      foregroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: kRailwayBlue),
      foregroundColor: kRailwayBlue,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kRailwayBlue,
    foregroundColor: kSurface,
  ),
);


const Map<String, String> kColorHex = {
  'RailwayBlue': '#003399',
  'TicketRed': '#E53935',
  'Background': '#F5F7FA',
  'Surface': '#FFFFFF',
  'TextPrimary': '#212121',
  'TextSecondary': '#616161',
  'Success': '#2E7D32',
  'Warning': '#F57C00',
  'Info': '#00796B',
  'AccentYellow': '#FFD54F',
  'Disabled': '#BDBDBD',
  'Divider': '#EEEEEE',
};

