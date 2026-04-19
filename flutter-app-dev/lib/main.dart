import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/dispensing_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_out_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dashboard/metric_detail_screen.dart';
import 'screens/dashboard/metrics_graph_screen.dart';
import 'screens/dispensing/dispensing_screen.dart';
import 'screens/settings/settings_screen.dart';

// ── iOS system colours ─────────────────────────────────────────────────────
const kBlue       = Color(0xFF007AFF);
const kGreen      = Color(0xFF34C759);
const kOrange     = Color(0xFFFF9500);
const kRed        = Color(0xFFFF3B30);
const kLabel      = Color(0xFF1C1C1E);
const kLabel2     = Color(0x993C3C43); // 60 %
const kLabel3     = Color(0x4D3C3C43); // 30 %
const kBg         = Color(0xFFF2F2F7); // grouped background
const kCardBg     = Color(0xFFFFFFFF);
const kSeparator  = Color(0xFFC6C6C8);

void main() {
  runApp(const PoolMonitorApp());
}

class PoolMonitorApp extends StatelessWidget {
  const PoolMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => DispensingProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Pool Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.light(
            primary: kBlue,
            secondary: kBlue,
            surface: kCardBg,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: kLabel,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith((_) => kBlue),
            checkColor: MaterialStateProperty.resolveWith((_) => Colors.white),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kCardBg,
            hintStyle: const TextStyle(color: kLabel3),
            labelStyle: const TextStyle(color: kLabel2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kSeparator),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kSeparator),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBlue, width: 1.5),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: kLabel, fontWeight: FontWeight.w700),
            titleLarge:   TextStyle(color: kLabel, fontWeight: FontWeight.w600),
            bodyLarge:    TextStyle(color: kLabel),
            bodyMedium:   TextStyle(color: kLabel2),
          ),
        ),
        initialRoute: '/dashboard',
        routes: {
          '/login':              (c) => const LoginScreen(),
          '/signin':             (c) => const SignInScreen(),
          '/register':           (c) => const RegisterScreen(),
          '/signed-out':         (c) => const SignOutScreen(),
          '/dashboard':          (c) => const MainTabScreen(),
          '/metric/ph':          (c) => const MetricDetailScreen(metric: 'ph'),
          '/metric/turbidity':   (c) => const MetricDetailScreen(metric: 'turbidity'),
          '/metric/temperature': (c) => const MetricDetailScreen(metric: 'temperature'),
          '/metric/chlorine':    (c) => const MetricDetailScreen(metric: 'chlorine'),
          '/metrics/graph':      (c) => const MetricsGraphScreen(),
        },
      ),
    );
  }
}

// ── Main tab scaffold ──────────────────────────────────────────────────────

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({Key? key}) : super(key: key);
  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _idx = 0;
  final _screens = const [
    DashboardScreen(),
    DispensingScreen(),
    SettingsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 0 && args < _screens.length) _idx = args;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: kBg,
      body: _screens[_idx],
      bottomNavigationBar: _IOSTabBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

// ── iOS-style tab bar ──────────────────────────────────────────────────────

class _IOSTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _IOSTabBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.bar_chart_rounded,    Icons.bar_chart_rounded,   'Monitor'),
    (Icons.science_rounded,     Icons.science_outlined,    'Dispense'),
    (Icons.settings_rounded,    Icons.settings_outlined,   'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: 56 + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            border: const Border(top: BorderSide(color: kSeparator, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _items.length,
              (i) => _TabItem(
                icon:         i == currentIndex ? _items[i].$1 : _items[i].$2,
                label:        _items[i].$3,
                active:       i == currentIndex,
                onTap:        () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({required this.icon, required this.label,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? kBlue : const Color(0xFF8E8E93);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: color,
          )),
        ]),
      ),
    );
  }
}
