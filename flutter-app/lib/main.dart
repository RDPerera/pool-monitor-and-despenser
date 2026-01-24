import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dashboard/metric_detail_screen.dart';
import 'screens/dashboard/metrics_graph_screen.dart';
import 'screens/dispensing/dispensing_screen.dart';
import 'screens/settings/settings_screen.dart';

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
      ],
      child: Builder(builder: (context) {
        final base = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            primary: const Color(0xFF1E88E5),
            secondary: const Color(0xFF1E88E5),
            surface: const Color(0xFFF2F9FF),
          ),
          scaffoldBackgroundColor: const Color(0xFFF2F9FF),
          primaryColor: const Color(0xFF1E88E5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardColor: const Color(0xFF1E88E5),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            filled: true,
            fillColor: const Color.fromRGBO(255, 255, 255, 0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith((states) => Colors.white),
            checkColor: MaterialStateProperty.resolveWith((states) => const Color(0xFF1E88E5)),
            side: const BorderSide(color: Color(0xFFBDBDBD)),
          ),
        );

        final theme = base.copyWith(
          // Apply primary blue to default text (body + display)
          textTheme: base.textTheme.apply(
            bodyColor: const Color(0xFF1E88E5),
            displayColor: const Color(0xFF1E88E5),
          ),
          primaryTextTheme: base.primaryTextTheme.apply(
            bodyColor: const Color(0xFF1E88E5),
            displayColor: const Color(0xFF1E88E5),
          ),
          colorScheme: base.colorScheme.copyWith(onSurface: const Color(0xFF1E88E5)),
        );

        return MaterialApp(
          title: 'Pool Monitor & Dispenser',
          theme: theme,
          debugShowCheckedModeBanner: false,
          initialRoute: kDebugMode ? '/dashboard' : '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/dashboard': (context) => const MainTabScreen(),
            '/metric/ph': (context) => const MetricDetailScreen(metric: 'ph'),
            '/metric/turbidity': (context) => const MetricDetailScreen(metric: 'turbidity'),
            '/metric/temperature': (context) => const MetricDetailScreen(metric: 'temperature'),
            '/metrics/graph': (context) => const MetricsGraphScreen(),
          },
        );
      }),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = kDebugMode ? 2 : 0;
  final _screens = [
    const DashboardScreen(),
    const DispensingScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.science), label: 'Dispensing'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
