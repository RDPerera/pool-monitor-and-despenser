import 'package:flutter/material.dart';

class EmergencyStopButton extends StatefulWidget {
  final bool isAdmin;

  const EmergencyStopButton({Key? key, required this.isAdmin})
      : super(key: key);

  @override
  State<EmergencyStopButton> createState() =>
      _EmergencyStopButtonState();
}

class _EmergencyStopButtonState extends State<EmergencyStopButton> {


  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () {
        // Long press started
        _showEmergencyStopConfirmation();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[700]!, Colors.red[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emergency,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🚨 EMERGENCY STOP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Long press to activate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pan_tool,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stops ALL chemical dispensing immediately and alerts all users',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyStopConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text(
          '🚨 EMERGENCY STOP ACTIVATION',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action will:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Stop ALL chemical dispensing immediately',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '• Send critical alerts to all users',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '• Log this event with timestamp and user ID',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '• This action cannot be undone immediately',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF6C00),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Confirm by entering your PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPinConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6C00),
            ),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }

  void _showPinConfirmation() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN to Confirm Emergency Stop'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'PIN',
            border: OutlineInputBorder(),
            hintText: '****',
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == '0000') {
                // TODO: Replace with actual PIN verification
                _executeEmergencyStop();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeEmergencyStop() async {
    // TODO: Execute emergency stop on the device
    // TODO: Send critical alert to all users
    // TODO: Log event with timestamp and user ID

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green[700],
        title: const Text(
          '✓ EMERGENCY STOP ACTIVATED',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'All chemical dispensing has been stopped.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Critical alerts sent to all users.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Long press ended
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
