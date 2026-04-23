import 'package:flutter/material.dart';

class PrintBillDialog extends StatelessWidget {
  final VoidCallback onPrintBill;

  const PrintBillDialog({
    super.key,
    required this.onPrintBill,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Print Bill'),
      content: const Text('Print the current bill?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onPrintBill();
          },
          icon: const Icon(Icons.print),
          label: const Text('Print'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}