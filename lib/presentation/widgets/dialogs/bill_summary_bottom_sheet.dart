import 'package:flutter/material.dart';
import '../../cubits/billing_cubit.dart';

class BillSummaryData {
  final List<CartItem> cart;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final double finalTotal;
  final double totalPurchase;
  final double expectedProfit;
  final double actualProfit;
  final double youSave;
  final bool showProfitLossMode;
  final bool isEditMode;
  final String? customerName;
  final String? customerMobile;

  const BillSummaryData({
    required this.cart,
    required this.subtotal,
    required this.taxAmount,
    required this.discount,
    required this.finalTotal,
    required this.totalPurchase,
    required this.expectedProfit,
    required this.actualProfit,
    required this.youSave,
    required this.showProfitLossMode,
    required this.isEditMode,
    this.customerName,
    this.customerMobile,
  });
}

class BillSummaryBottomSheet extends StatelessWidget {
  final BillSummaryData data;
  final ValueChanged<String> onCustomerNameChanged;
  final ValueChanged<String> onCustomerMobileChanged;
  final ValueChanged<double> onDiscountChanged;
  final VoidCallback onPrintBill;
  final VoidCallback onSaveBill;
  final VoidCallback onMarkBillAsPaid;

  const BillSummaryBottomSheet({
    super.key,
    required this.data,
    required this.onCustomerNameChanged,
    required this.onCustomerMobileChanged,
    required this.onDiscountChanged,
    required this.onPrintBill,
    required this.onSaveBill,
    required this.onMarkBillAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Text(
                'Bill Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Customer Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: data.customerName),
                      decoration: const InputDecoration(
                        labelText: 'Customer Name (Optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: onCustomerNameChanged,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: data.customerMobile),
                      decoration: const InputDecoration(
                        labelText: 'Customer Mobile',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: onCustomerMobileChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bill Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('₹${data.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Total Tax
                    if (data.taxAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax:', style: TextStyle(color: Colors.blue)),
                          Text(
                            '₹${data.taxAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total with Tax:', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
                          Text(
                            '₹${(data.subtotal + data.taxAmount).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    if (data.showProfitLossMode) ...[
                      const SizedBox(height: 8),
                      // Total Purchase Cost
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Cost:', style: TextStyle(color: Colors.blue)),
                          Text(
                            '₹${data.totalPurchase.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Expected Profit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expected Profit:', style: TextStyle(color: Colors.purple)),
                          Text(
                            '₹${data.expectedProfit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: data.expectedProfit >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Discount Input
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Discount:', textAlign: TextAlign.right),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: data.discount.toStringAsFixed(2)),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              prefixText: '₹',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final discount = double.tryParse(value) ?? 0.0;
                              final maxDiscount = data.subtotal + data.taxAmount;
                              onDiscountChanged(discount > maxDiscount ? maxDiscount : discount);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    // Final Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Final Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${data.finalTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: data.showProfitLossMode && data.finalTotal < data.totalPurchase ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // You Save
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'You Save:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '₹${data.youSave.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    if (data.showProfitLossMode) ...[
                      const SizedBox(height: 8),
                      // Actual Profit/Loss after discount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data.actualProfit < 0 ? 'Loss:' : 'Profit:',
                            style: TextStyle(
                              color: data.actualProfit < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹${data.actualProfit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: data.actualProfit < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (data.discount > 0) ...[
                        const SizedBox(height: 4),
                        const Text(
                          '⚠️ High discount may result in loss!',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                        onPrintBill();
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (data.isEditMode) {
                          onSaveBill();
                        } else {
                          onMarkBillAsPaid();
                        }
                        Navigator.pop(context); // Close bottom sheet after operations complete
                      },
                      icon: const Icon(Icons.payment),
                      label: Text(data.isEditMode ? 'Update Bill' : 'Paid Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: data.isEditMode ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}