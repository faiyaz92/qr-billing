import 'package:flutter/material.dart';

class CustomerTrustIndicatorsWidget extends StatelessWidget {
  const CustomerTrustIndicatorsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.verified, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This product is verified and priced according to our online catalog. The price shown is the official online selling price.',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}