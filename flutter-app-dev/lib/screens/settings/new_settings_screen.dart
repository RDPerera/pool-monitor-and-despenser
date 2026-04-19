import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';

// Import the detail screens
import 'pool_profile_card.dart';
import 'sensor_calibration_card.dart';
import 'chemical_dispensing_card.dart';
import 'alert_thresholds_card.dart';
import 'emergency_stop_button.dart';
import 'user_roles_screen.dart';
import 'logs_reports_screen.dart';

class NewSettingsScreen extends StatefulWidget {
  const NewSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NewSettingsScreen> createState() => _NewSettingsScreenState();
}

class _NewSettingsScreenState extends State<NewSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isAdmin = currentUser?.role == 'admin';
    final isTechnician = currentUser?.role == 'technician';
    final isAuthenticated = currentUser != null;

    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(
          child: Text('Please log in to access settings'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppLogo(size: 32),
        ),
        elevation: 2,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show user role badge
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getRoleColor(currentUser.role).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getRoleColor(currentUser.role)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: _getRoleColor(currentUser.role)),
                        const SizedBox(width: 8),
                        Text(
                          '${currentUser.firstName} ${currentUser.lastName} • ${currentUser.role.toUpperCase()},',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _getRoleColor(currentUser.role),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Emergency Stop at top for visibility (Admin only)
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: EmergencyStopButton(isAdmin: isAdmin),
                  ),

                // Pool Profile Section
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: PoolProfileCard(
                      onEdit: () {
                        setState(() {});
                      },
                    ),
                  ),

                // Sensor Calibration Section
                if (isAdmin || isTechnician)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SensorCalibrationCard(),
                  ),

                // Chemical Dispensing Section
                if (isAdmin || isTechnician)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ChemicalDispensingCard(),
                  ),

                // Alert Thresholds Section
                if (isAdmin || isTechnician)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: AlertThresholdsCard(isAdmin: isAdmin),
                  ),

                // Viewer-only: Read-only view
                if (!isAdmin && !isTechnician)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.visibility,
                                      color: Color(0xFF1976D2), size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'View Only Access',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'You have read-only access to monitoring data',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Contact an administrator to request additional permissions.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Spacer for bottom navigation
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Bottom Navigation Bar for management features
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isAdmin)
                    _buildBottomNavButton(
                      icon: Icons.people,
                      label: 'User Roles',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserRolesScreen(),
                        ),
                      ),
                    ),
                  _buildBottomNavButton(
                    icon: Icons.history,
                    label: 'Logs & Reports',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LogsReportsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'technician':
        return Colors.orange;
      case 'viewer':
      default:
        return Colors.blue;
    }
  }

  Widget _buildBottomNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF1976D2), size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
