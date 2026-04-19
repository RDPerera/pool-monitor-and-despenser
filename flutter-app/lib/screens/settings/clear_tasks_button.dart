import 'package:flutter/material.dart';
import '../../services/dispensing_service.dart';

class ClearTasksButton extends StatefulWidget {
  final bool isAdmin;

  const ClearTasksButton({Key? key, required this.isAdmin}) : super(key: key);

  @override
  State<ClearTasksButton> createState() => _ClearTasksButtonState();
}

class _ClearTasksButtonState extends State<ClearTasksButton> {
  final DispensingService _dispensingService = DispensingService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) return const SizedBox.shrink();

    return GestureDetector(
      onLongPress: _showConfirmation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[700]!, Colors.orange[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
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
                    const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clear All Tasks',
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
                  child: const Icon(Icons.pan_tool, color: Colors.white, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Removes all pending dispensing tasks from the queue',
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

  void _showConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Clear All Dispensing Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently remove all pending dispensing tasks from the queue. The dispenser will stop receiving new jobs until new tasks are added.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPinConfirmation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
            child: const Text('CONTINUE', style: TextStyle(color: Colors.white)),
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
        title: const Text('Enter PIN to Confirm'),
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
                Navigator.pop(context);
                _clearAllTasks();
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

  Future<void> _clearAllTasks() async {
    setState(() => _isLoading = true);

    try {
      await _dispensingService.deleteAllJobs();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.green[700],
          title: const Text(
            '✓ All Tasks Cleared',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text(
                'All dispensing tasks have been removed from the queue.',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('OK', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear tasks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
