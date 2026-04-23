import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ContinuousScanDialog extends StatelessWidget {
  final ValueChanged<String> onProductScanned;
  final VoidCallback onClose;

  const ContinuousScanDialog({
    super.key,
    required this.onProductScanned,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Continuous Scan'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            const Text('Scan product QR codes continuously'),
            const SizedBox(height: 16),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final String? code = barcode.rawValue;
                    if (code != null) {
                      onProductScanned(code);
                      break;
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onClose,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}