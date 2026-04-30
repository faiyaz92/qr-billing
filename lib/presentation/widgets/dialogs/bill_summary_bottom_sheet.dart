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

class BillSummaryBottomSheet extends StatefulWidget {
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
  State<BillSummaryBottomSheet> createState() => _BillSummaryBottomSheetState();
}

class _BillSummaryBottomSheetState extends State<BillSummaryBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data.customerName);
    _mobileController = TextEditingController(text: widget.data.customerMobile);
    _discountController = TextEditingController(
      text: widget.data.discount > 0 ? widget.data.discount.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _discountController.dispose();
    super.dispose();
  }

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
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name (Optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: widget.onCustomerNameChanged,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Mobile',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: widget.onCustomerMobileChanged,
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
                        Text('₹${widget.data.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Total Tax
                    if (widget.data.taxAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax:', style: TextStyle(color: Colors.blue)),
                          Text(
                            '₹${widget.data.taxAmount.toStringAsFixed(2)}',
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
                            '₹${(widget.data.subtotal + widget.data.taxAmount).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    if (widget.data.showProfitLossMode) ...[
                      const SizedBox(height: 8),
                      // Total Purchase Cost
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Cost:', style: TextStyle(color: Colors.blue)),
                          Text(
                            '₹${widget.data.totalPurchase.toStringAsFixed(2)}',
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
                            '₹${widget.data.expectedProfit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: widget.data.expectedProfit >= 0 ? Colors.green : Colors.red,
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
                        const Text(
                          '₹',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _discountController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              final discount = double.tryParse(value) ?? 0.0;
                              final maxDiscount = widget.data.subtotal + widget.data.taxAmount;
                              widget.onDiscountChanged(discount > maxDiscount ? maxDiscount : discount);
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
                          '₹${widget.data.finalTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.data.showProfitLossMode && widget.data.finalTotal < widget.data.totalPurchase ? Colors.orange : Colors.green,
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
                          '₹${widget.data.youSave.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    if (widget.data.showProfitLossMode) ...[
                      const SizedBox(height: 8),
                      // Actual Profit/Loss after discount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.data.actualProfit < 0 ? 'Loss:' : 'Profit:',
                            style: TextStyle(
                              color: widget.data.actualProfit < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹${widget.data.actualProfit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: widget.data.actualProfit < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (widget.data.discount > 0) ...[
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
                        widget.onPrintBill();
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
                        if (widget.data.isEditMode) {
                          widget.onSaveBill();
                        } else {
                          widget.onMarkBillAsPaid();
                        }
                        Navigator.pop(context); // Close bottom sheet after operations complete
                      },
                      icon: const Icon(Icons.payment),
                      label: Text(widget.data.isEditMode ? 'Update Bill' : 'Paid Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.data.isEditMode ? Colors.orange : Colors.green,
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