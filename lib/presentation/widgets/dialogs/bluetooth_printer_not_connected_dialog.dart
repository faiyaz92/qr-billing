import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

class BluetoothPrinterNotConnectedDialog extends StatelessWidget {
  final VoidCallback? onGoToSettings;
  
  const BluetoothPrinterNotConnectedDialog({super.key, this.onGoToSettings});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bluetooth Printer Not Connected'),
      content: const Text(
        'You have selected Bluetooth printer as your default printer, but no printer is currently connected. '
        'Please connect to a Bluetooth thermal printer to print bills.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            // Navigate to thermal printer settings screen
            onGoToSettings?.call();
          },
          child: const Text('Go to Settings'),
        ),
      ],
    );
  }
}