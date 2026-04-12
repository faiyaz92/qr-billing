import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../cubits/billing_cubit.dart';

@RoutePage()
class BillingScreen extends StatefulWidget {
  BillingScreen({super.key});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {

  void _showPrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Print Bill'),
        content: const Text('Print the current bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await context.read<BillingCubit>().printBill();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bill printed successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Print failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showContinuousScanDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocListener<BillingCubit, BillingState>(
        listener: (context, state) {
          if (state is BillingUpdated && !state.duplicateDetected) {
            // Close dialog after successful scan
            Navigator.of(dialogContext).pop();
          }
        },
        child: AlertDialog(
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
                          context.read<BillingCubit>().scanProduct(code, continuousScan: true);
                          break;
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBillSummaryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<BillingCubit, BillingState>(
        builder: (context, state) {
          if (state is BillingUpdated) {
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
                              decoration: const InputDecoration(
                                labelText: 'Customer Name (Optional)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (value) => context.read<BillingCubit>().setCustomerName(value),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Customer Mobile',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (value) => context.read<BillingCubit>().setCustomerMobile(value),
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
                                Text('₹${context.read<BillingCubit>().calculateTotal().toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Total Tax
                            Builder(
                              builder: (context) {
                                final taxAmount = context.read<BillingCubit>().calculateTaxAmount();
                                if (taxAmount > 0) {
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Tax:', style: TextStyle(color: Colors.blue)),
                                          Text(
                                            '₹${taxAmount.toStringAsFixed(2)}',
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
                                            '₹${(context.read<BillingCubit>().calculateTotal() + taxAmount).toStringAsFixed(2)}',
                                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            if (state.showProfitLossMode) ...[
                              const SizedBox(height: 8),
                              // Total Purchase Cost
                              Builder(
                                builder: (context) {
                                  final totalPurchase = state.cart.fold<double>(
                                    0.0,
                                    (sum, item) => sum + (item.product.purchasePrice * item.quantity),
                                  );
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Cost:', style: TextStyle(color: Colors.blue)),
                                      Text(
                                        '₹${totalPurchase.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.blue),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              // Expected Profit
                              Builder(
                                builder: (context) {
                                  final subtotal = context.read<BillingCubit>().calculateTotal();
                                  final totalPurchase = state.cart.fold<double>(
                                    0.0,
                                    (sum, item) => sum + (item.product.purchasePrice * item.quantity),
                                  );
                                  final expectedProfit = subtotal - totalPurchase;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Expected Profit:', style: TextStyle(color: Colors.purple)),
                                      Text(
                                        '₹${expectedProfit.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: expectedProfit >= 0 ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      prefixText: '₹',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final discount = double.tryParse(value) ?? 0.0;
                                      final subtotal = context.read<BillingCubit>().calculateTotal();
                                      final taxAmount = context.read<BillingCubit>().calculateTaxAmount();
                                      final maxDiscount = subtotal + taxAmount;
                                      context.read<BillingCubit>().setDiscount(discount > maxDiscount ? maxDiscount : discount);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            // Final Total
                            Builder(
                              builder: (context) {
                                final finalTotal = context.read<BillingCubit>().calculateFinalTotal();
                                final totalPurchase = state.showProfitLossMode ? state.cart.fold<double>(
                                  0.0,
                                  (sum, item) => sum + (item.product.purchasePrice * item.quantity),
                                ) : 0.0;
                                final isLoss = state.showProfitLossMode && finalTotal < totalPurchase;
                                
                                return Row(
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
                                      '₹${finalTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isLoss ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (state.showProfitLossMode) ...[
                              const SizedBox(height: 8),
                              // Actual Profit/Loss after discount
                              Builder(
                                builder: (context) {
                                  final subtotal = context.read<BillingCubit>().calculateTotal();
                                  final totalPurchase = state.cart.fold<double>(
                                    0.0,
                                    (sum, item) => sum + (item.product.purchasePrice * item.quantity),
                                  );
                                  final actualProfit = (subtotal - state.discount) - totalPurchase;
                                  final isLoss = actualProfit < 0;
                                  
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isLoss ? 'Loss:' : 'Profit:',
                                        style: TextStyle(
                                          color: isLoss ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '₹${actualProfit.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: isLoss ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              if (state.discount > 0) ...[
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
                              onPressed: () async {
                                Navigator.pop(context); // Close bottom sheet
                                try {
                                  await context.read<BillingCubit>().printBill();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Bill printed successfully')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Print failed: $e')),
                                  );
                                }
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
                              onPressed: () async {
                                try {
                                  if (state.isEditMode) {
                                    // In edit mode, just save the bill (update existing)
                                    await context.read<BillingCubit>().saveBill(state.discount);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Bill updated successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    // Normal mode - mark as paid and clear cart
                                    await context.read<BillingCubit>().markBillAsPaid();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Bill marked as paid successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to ${state.isEditMode ? 'update' : 'mark'} bill: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  Navigator.pop(context); // Close bottom sheet after operations complete
                                }
                              },
                              icon: const Icon(Icons.payment),
                              label: Text(state.isEditMode ? 'Update Bill' : 'Paid Bill'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.isEditMode ? Colors.orange : Colors.green,
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
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<BillingCubit, BillingState>(
            builder: (context, state) {
              if (state is BillingUpdated && !state.isEditMode) {
                return IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => context.read<BillingCubit>().addDummyProductsForTesting(),
                  tooltip: 'Add Dummy Products (Testing)',
                  color: Colors.green,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => context.read<BillingCubit>().toggleProfitLossMode(),
            tooltip: 'Toggle Profit/Loss View',
            color: (context.watch<BillingCubit>().state as BillingUpdated).showProfitLossMode ? Colors.orange : null,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _showBillSummaryBottomSheet,
            tooltip: 'Bill Summary',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _showPrintDialog(context),
            tooltip: 'Print Bill',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => context.read<BillingCubit>().clearCart(),
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: BlocListener<BillingCubit, BillingState>(
        listener: (context, state) {
          if (state is BillingUpdated && state.duplicateDetected && state.duplicateProductName != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${state.duplicateProductName} is already in cart'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8FAFC),
                Color(0xFFF1F5F9),
              ],
            ),
          ),
          child: Column(
            children: [
              // Cart (Full screen now)
              Expanded(
                child: BlocBuilder<BillingCubit, BillingState>(
                  builder: (context, state) {
                    if (state is BillingUpdated) {
                      return Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Cart Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E40AF),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shopping_cart, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Cart Items (${state.cart.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (state.cart.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () => context.read<BillingCubit>().clearCart(),
                                      icon: const Icon(Icons.clear, size: 16, color: Colors.white),
                                      label: const Text('Clear All', style: TextStyle(color: Colors.white)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: state.cart.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          'Your cart is empty',
                                          style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w500),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Scan product QR codes to add items',
                                          style: TextStyle(color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.cart.length,
                                    itemBuilder: (context, index) {
                                      final item = state.cart[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Product Icon (Centered)
                                              Container(
                                                width: 50,
                                                height: 50,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[100],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.inventory_2,
                                                  color: Color(0xFF1E40AF),
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Product Details Column
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // First Row: Product Name and Price
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            item.product.name ?? 'Unknown Product',
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text(
                                                              '₹${item.product.sellingPrice.toStringAsFixed(0)}',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.grey,
                                                              ),
                                                            ),
                                                            if (item.product.tax != null && item.product.tax! > 0) ...[
                                                              Text(
                                                                'Tax: ${item.product.tax!.toStringAsFixed(1)}%',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.blue,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                            if (state.showProfitLossMode) ...[
                                                              Text(
                                                                'Cost: ₹${(item.product.purchasePrice).toStringAsFixed(0)}',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.blue,
                                                                ),
                                                              ),
                                                              Text(
                                                                'Profit: ₹${(((item.product.sellingPrice - item.itemDiscount - item.product.purchasePrice) * item.quantity)).toStringAsFixed(0)}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: (((item.product.sellingPrice - item.itemDiscount - item.product.purchasePrice) * item.quantity)) >= 0 ? Colors.green : Colors.red,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Second Row: Plus Minus and Delete Button
                                                    Row(
                                                      children: [
                                                        // Quantity Controls
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            border: Border.all(color: Colors.grey[300]!),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              IconButton(
                                                                icon: const Icon(Icons.remove, size: 16),
                                                                onPressed: () => context.read<BillingCubit>().updateQuantity(index, -1),
                                                                padding: const EdgeInsets.all(2),
                                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                              ),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  border: Border.symmetric(
                                                                    vertical: BorderSide(color: Colors.grey[300]!),
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  '${item.quantity}',
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(Icons.add, size: 16),
                                                                onPressed: () => context.read<BillingCubit>().updateQuantity(index, 1),
                                                                padding: const EdgeInsets.all(2),
                                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        IconButton(
                                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                title: const Text('Remove Item'),
                                                                content: Text('Remove "${item.product.name}" from cart?'),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: const Text('Cancel'),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.pop(context);
                                                                      context.read<BillingCubit>().removeItem(index);
                                                                    },
                                                                    child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                          padding: const EdgeInsets.all(2),
                                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Item Discount (always visible, read-only)
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          'Item Discount:',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: SizedBox(
                                                            height: 28,
                                                            child: TextField(
                                                              decoration: const InputDecoration(
                                                                hintText: '0.00',
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                prefixText: '₹',
                                                              ),
                                                              style: const TextStyle(fontSize: 12),
                                                              keyboardType: TextInputType.number,
                                                              onChanged: (value) {
                                                                final discount = double.tryParse(value) ?? 0.0;
                                                                final maxDiscount = item.product.sellingPrice;
                                                                context.read<BillingCubit>().updateItemDiscount(index, discount > maxDiscount ? maxDiscount : discount);
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Third Row: Price * Count (left) and Total (right)
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '₹${item.product.sellingPrice.toStringAsFixed(0)} × ${item.quantity}',
                                                          style: const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text(
                                                              '₹${((item.product.sellingPrice - item.itemDiscount) * item.quantity).toStringAsFixed(2)}',
                                                              style: TextStyle(
                                                                color: ((item.product.sellingPrice - item.itemDiscount) * item.quantity) >= (item.product.purchasePrice * item.quantity) ? Colors.green : Colors.orange,
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                            if (state.showProfitLossMode && item.itemDiscount > 0) ...[
                                                              Text(
                                                                'After discount',
                                                                style: const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Center(child: Text('Scan products to start billing'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<BillingCubit, BillingState>(
        builder: (context, state) {
          if (state is BillingUpdated && !state.isEditMode) {
            return FloatingActionButton(
              onPressed: _showContinuousScanDialog,
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              tooltip: 'Continuous Scan',
              child: const Icon(Icons.qr_code_scanner),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );  }
}