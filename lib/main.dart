import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaanKotApp());
}

class SaanKotApp extends StatefulWidget {
  const SaanKotApp({super.key});

  @override
  State<SaanKotApp> createState() => _SaanKotAppState();
}

class _SaanKotAppState extends State<SaanKotApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        title: 'Saan KOT - Nepali Restaurant POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.alabasterBg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.emeraldPrimary,
            primary: AppColors.emeraldPrimary,
            secondary: AppColors.amberOrange,
            surface: AppColors.pureWhite,
          ),
          cardTheme: CardThemeData(
            color: AppColors.pureWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.pureWhite,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textDark),
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          fontFamily: null,
        ),
        home: const MainShell(),
      ),
    );
  }
}
