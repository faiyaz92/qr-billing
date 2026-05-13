import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app_router.dart';
import '../cubits/billing_cubit.dart';
import '../cubits/billing_state.dart';
import '../widgets/dialogs/bluetooth_printer_not_connected_dialog.dart';

@RoutePage()
class BillDetailScreen extends StatelessWidget {
  const BillDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printBill(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: BlocBuilder<BillingCubit, BillingState>(
          buildWhen: (prev, curr) => curr is BillingUpdated,
          builder: (context, state) {
            if (state is BillingUpdated) {
              final summary = context.read<BillingCubit>().getSummaryData();
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CustomerInfoCard(state: state),
                    const SizedBox(height: 16),
                    _BillItemsSection(cart: state.cart),
                    const SizedBox(height: 16),
                    _TotalAmountCard(total: summary.subtotal),
                    const SizedBox(height: 16),
                    _BillSummaryCard(summary: summary, discount: state.discount),
                    const SizedBox(height: 16),
                    _CustomerDetailsEditSection(
                      initialName: state.customerName,
                      initialMobile: state.customerMobile,
                    ),
                    const SizedBox(height: 24),
                    _ActionButtonsSection(state: state),
                  ],
                ),
              );
            }
            return const Center(child: Text('No bill data'));
          },
        ),
      ),
    );
  }

  void _printBill(BuildContext context) async {
    try {
      await context.read<BillingCubit>().printBill();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill printed successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains('BLUETOOTH_PRINTER_NOT_CONNECTED')) {
          showDialog(
            context: context,
            builder: (_) => BluetoothPrinterNotConnectedDialog(
              onGoToSettings: () => context.router.push(ThermalPrinterRoute()),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Print failed: $e')),
          );
        }
      }
    }
  }

  void _showShareDialog(BuildContext context, BillingUpdated state) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.share, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Share Bill PDF',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose how you want to share the bill PDF.',
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.read<BillingCubit>().shareBillPdf();
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _shareViaEmail(context, state);
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareViaEmail(BuildContext context, BillingUpdated state) {
    // Note: PDF sharing is handled through the share_plus package which includes email
    context.read<BillingCubit>().shareBillPdf();
  }

  void _shareOnWhatsApp(BuildContext context, BillingUpdated state) async {
    final mobile = state.customerMobile;
    if (mobile == null || mobile.isEmpty) {
      final mobileController = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share on WhatsApp', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                const SizedBox(height: 20),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone, color: Colors.green), border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final number = mobileController.text.trim();
                          if (number.length == 10) {
                            Navigator.pop(dialogContext);
                            context.read<BillingCubit>().setCustomerMobile(number);
                            context.read<BillingCubit>().shareViaWhatsApp(number);
                          }
                        },
                        child: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      context.read<BillingCubit>().shareViaWhatsApp(mobile);
    }
  }
}

// Atomic Components
class _CustomerInfoCard extends StatelessWidget {
  final BillingUpdated state;
  const _CustomerInfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF1E40AF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.customerName?.isNotEmpty == true ? 'Customer: ${state.customerName}' : 'Customer: Not specified',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: state.customerName?.isNotEmpty == true ? const Color(0xFF1E40AF) : Colors.grey,
              ),
            ),
          ),
          if (state.customerMobile?.isNotEmpty == true)
            Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.phone, color: Colors.green, size: 20),
                const SizedBox(width: 4),
                Text(state.customerMobile!, style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500)),
              ],
            ),
        ],
      ),
    );
  }
}

class _BillItemsSection extends StatelessWidget {
  final List<CartItem> cart;
  const _BillItemsSection({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          const SizedBox(height: 12),
          ...cart.map((item) => _BillItemTile(item: item)),
        ],
      ),
    );
  }
}

class _BillItemTile extends StatelessWidget {
  final CartItem item;
  const _BillItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.data.data;
    final sellingPrice = double.tryParse(data['selling_price']?.toString() ?? '0') ?? 0.0;
    final itemTotalBeforeTax = (sellingPrice - item.itemDiscount) * item.quantity;
    final taxAmount = itemTotalBeforeTax * ((item.product.tax ?? 0.0) / 100);
    final finalPrice = itemTotalBeforeTax + taxAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.inventory_2, color: Color(0xFF1E40AF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['name'] ?? 'Unknown Product',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.itemDiscount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange[200]!)),
                        child: Text(
                          'OFF ₹${(item.itemDiscount * item.quantity).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Qty: ${item.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            if (item.product.originalPrice != null && item.product.originalPrice! > sellingPrice)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  'MRP: ₹${item.product.originalPrice!.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                ),
                              ),
                            if (item.itemDiscount > 0)
                              Text(
                                'Sell: ₹${sellingPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, color: Colors.orange, decoration: TextDecoration.lineThrough),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            if (item.product.tax != null && item.product.tax! > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  'Tax: ${item.product.tax!.toStringAsFixed(0)}% (₹${(finalPrice - itemTotalBeforeTax).toStringAsFixed(1)})',
                                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                ),
                              ),
                            Text(
                              '₹${(finalPrice / item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalAmountCard extends StatelessWidget {
  final double total;
  const _TotalAmountCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  final BillSummaryData summary;
  final double discount;
  const _BillSummaryCard({required this.summary, required this.discount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          const SizedBox(height: 12),
          if (summary.taxAmount > 0)
            _SummaryRow(label: 'Tax', value: '₹${summary.taxAmount.toStringAsFixed(2)}'),
          if (discount > 0)
            _SummaryRow(label: 'Discount', value: '₹${discount.toStringAsFixed(2)}'),
          _SummaryRow(label: 'You Save', value: '₹${summary.youSave.toStringAsFixed(2)}'),
          const Divider(),
          _SummaryRow(
            label: 'Final Total',
            value: '₹${summary.finalTotal.toStringAsFixed(2)}',
            isBold: true,
            labelSize: 18,
            valueColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final double labelSize;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.isBold = false, this.labelSize = 14, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: labelSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? const Color(0xFF1E40AF) : null)),
          Text(value, style: TextStyle(fontSize: labelSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? (isBold ? Colors.green : null))),
        ],
      ),
    );
  }
}

class _CustomerDetailsEditSection extends StatelessWidget {
  final String? initialName;
  final String? initialMobile;
  const _CustomerDetailsEditSection({this.initialName, this.initialMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: initialName),
                  decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onChanged: (value) => context.read<BillingCubit>().setCustomerName(value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: initialMobile),
                  decoration: const InputDecoration(labelText: 'Customer Mobile', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onChanged: (value) => context.read<BillingCubit>().setCustomerMobile(value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsSection extends StatelessWidget {
  final BillingUpdated state;
  const _ActionButtonsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<BillDetailScreen>();
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => parent?._printBill(context),
            icon: const Icon(Icons.print),
            label: const Text('Print Bill'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E40AF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => parent?._showShareDialog(context, state),
            icon: const Icon(Icons.share),
            label: const Text('Share PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => parent?._shareOnWhatsApp(context, state),
            icon: const Icon(Icons.message),
            label: const Text('WhatsApp'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }
}