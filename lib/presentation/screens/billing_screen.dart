import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app_router.dart';
import '../../core/injection.dart';
import '../cubits/billing_cubit.dart';
import '../cubits/billing_state.dart';
import '../cubits/add_product_cubit.dart';
import '../widgets/dialogs/print_bill_dialog.dart';
import '../widgets/dialogs/continuous_scan_dialog.dart';
import '../widgets/dialogs/bill_summary_bottom_sheet.dart';
import '../widgets/dialogs/bluetooth_printer_not_connected_dialog.dart';
import '../widgets/cart_widget.dart';
import '../widgets/product_list_drawer.dart';
import '../widgets/quick_add_widget.dart';

@RoutePage()
class BillingScreen extends StatefulWidget {
  BillingScreen({super.key});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: const Text('Billing'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<BillingCubit, BillingState>(
            buildWhen: (prev, curr) =>
                curr is BillingUpdated &&
                (prev is! BillingUpdated || prev.showProfitLossMode != curr.showProfitLossMode),
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.analytics_outlined),
                onPressed: () => context.read<BillingCubit>().toggleProfitLossMode(),
                tooltip: 'Toggle Profit/Loss View',
                color: (state is BillingUpdated && state.showProfitLossMode) ? Colors.orange : null,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              final summaryData = context.read<BillingCubit>().getSummaryData();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (modalContext) => BlocProvider.value(
                  value: context.read<BillingCubit>(),
                  child: BlocBuilder<BillingCubit, BillingState>(
                    buildWhen: (prev, curr) => curr is BillingUpdated,
                    builder: (context, state) {
                      // Live summary update in bottom sheet
                      final liveSummary = context.read<BillingCubit>().getSummaryData();
                      return BillSummaryBottomSheet(
                        data: liveSummary,
                        onCustomerNameChanged: (value) => context.read<BillingCubit>().setCustomerName(value),
                        onCustomerMobileChanged: (value) => context.read<BillingCubit>().setCustomerMobile(value),
                        onDiscountChanged: (value) => context.read<BillingCubit>().setDiscount(value),
                        onPrintBill: () async {
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
                                  builder: (_) => const BluetoothPrinterNotConnectedDialog(),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Print failed: $e')),
                                );
                              }
                            }
                          }
                        },
                        onSaveBill: () async {
                          try {
                            await context.read<BillingCubit>().saveBill();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bill updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update bill: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        onMarkBillAsPaid: () async {
                          try {
                            await context.read<BillingCubit>().markBillAsPaid();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bill marked as paid successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to mark bill as paid: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              );
            },
            tooltip: 'Bill Summary',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => PrintBillDialog(
                onPrintBill: () async {
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
                },
              ),
            ),
            tooltip: 'Print Bill',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ContinuousScanDialog(
                onProductScanned: (code) async {
                  try {
                    await context.read<BillingCubit>().scanProduct(code, continuousScan: true);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scan failed: $e')),
                      );
                    }
                  }
                },
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
            tooltip: 'Continuous Scan',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => context.read<BillingCubit>().clearCart(),
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      drawer: const ProductListDrawer(),
      body: BlocListener<BillingCubit, BillingState>(
        listener: (context, state) {
          if (state is BillingUpdated) {
            if (state.duplicateDetected && state.duplicateProductName != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${state.duplicateProductName} is already in cart'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
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
          child: const Column(
            children: [
              Expanded(
                child: CartWidget(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<BillingCubit, BillingState>(
        buildWhen: (prev, curr) =>
            curr is BillingUpdated &&
            (prev is! BillingUpdated || prev.isEditMode != curr.isEditMode),
        builder: (context, state) {
          if (state is BillingUpdated && !state.isEditMode) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'quick_add_fab',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const QuickAddWidget(),
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  tooltip: 'Quick Add Product',
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add Product'),
                  elevation: 6,
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'scan_fab',
                  onPressed: () => showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ContinuousScanDialog(
                      onProductScanned: (code) async {
                        try {
                          await context.read<BillingCubit>().scanProduct(code, continuousScan: true);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Scan failed: $e')),
                            );
                          }
                        }
                      },
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  tooltip: 'Scan QR Code',
                  child: const Icon(Icons.qr_code_scanner, size: 28),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}