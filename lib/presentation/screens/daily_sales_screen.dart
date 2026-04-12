import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../../../core/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app_router.dart';
import '../cubits/daily_sales_cubit.dart';
import '../cubits/daily_sales_state.dart';
import '../cubits/billing_cubit.dart';

@RoutePage()
class DailySalesScreen extends StatelessWidget {
  const DailySalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DailySalesCubit>()..loadSales(),
      child: BlocListener<DailySalesCubit, DailySalesState>(
        listener: (context, state) {
          if (state is DailySalesViewBill) {
            // Load bill into billing cubit and navigate to bill detail
            loadBillForView(context, state.billId);
          } else if (state is DailySalesEditBill) {
            // Load bill into billing cubit and navigate to billing screen
            loadBillForEdit(context, state.billId);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Track Sales'),
            backgroundColor: const Color(0xFF1E40AF),
            foregroundColor: Colors.white,
          ),
          body: Container(
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
                // Monthly Summary Tiles
                BlocBuilder<DailySalesCubit, DailySalesState>(
                  builder: (context, state) {
                    if (state is DailySalesLoaded) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryTile('Monthly Sales', '₹${state.monthlySales.toStringAsFixed(2)}', Icons.trending_up, Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryTile('Monthly Profit', '₹${state.monthlyProfit.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryTile('COGS', '₹${state.monthlyCOGS.toStringAsFixed(2)}', Icons.inventory, Colors.orange),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Filters: Month, Year, Search
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: BlocBuilder<DailySalesCubit, DailySalesState>(
                              builder: (context, state) {
                                final selectedMonth = (state is DailySalesLoaded) ? state.selectedMonth : DateTime.now().month;
                                return DropdownButtonFormField<int>(
                                  value: selectedMonth,
                                  decoration: const InputDecoration(
                                    labelText: 'Month',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: List.generate(12, (index) => DropdownMenuItem(
                                    value: index + 1,
                                    child: Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index]),
                                  )),
                                  onChanged: (value) => context.read<DailySalesCubit>().changeMonth(value!),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BlocBuilder<DailySalesCubit, DailySalesState>(
                              builder: (context, state) {
                                final selectedYear = (state is DailySalesLoaded) ? state.selectedYear : DateTime.now().year;
                                return DropdownButtonFormField<int>(
                                  value: selectedYear,
                                  decoration: const InputDecoration(
                                    labelText: 'Year',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: List.generate(10, (index) => DropdownMenuItem(
                                    value: DateTime.now().year - 5 + index,
                                    child: Text((DateTime.now().year - 5 + index).toString()),
                                  )),
                                  onChanged: (value) => context.read<DailySalesCubit>().changeYear(value!),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<DailySalesCubit, DailySalesState>(
                        builder: (context, state) {
                          final searchQuery = (state is DailySalesLoaded) ? state.searchQuery : '';
                          return TextField(
                            controller: TextEditingController(text: searchQuery),
                            decoration: const InputDecoration(
                              labelText: 'Search by Bill Number, Customer Name, or Mobile',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) => context.read<DailySalesCubit>().setSearchQuery(value),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: BlocBuilder<DailySalesCubit, DailySalesState>(
                  builder: (context, state) {
                    if (state is DailySalesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is DailySalesLoaded) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.dailySales.length,
                        itemBuilder: (context, index) {
                          final day = state.dailySales[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Colors.grey[100]!),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                title: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Color(0xFF1E40AF), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(day.date),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildTrendIcon(day.trend),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.trending_up, color: Colors.blue, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Sales: ₹${day.totalSales.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.inventory, color: Colors.orange, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'COGS: ₹${day.totalPurchase.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            day.totalProfit >= 0 ? Icons.account_balance_wallet : Icons.warning,
                                            color: day.totalProfit >= 0 ? Colors.green : Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Profit: ₹${day.totalProfit.toStringAsFixed(0)} (${day.profitPercentage >= 0 ? '+' : ''}${day.profitPercentage.toStringAsFixed(1)}%)',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: day.totalProfit >= 0 ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                children: day.bills.map((bill) => Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Color(0xFF1E40AF),
                                      child: Text(
                                        '${bill.id}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      'Bill #${bill.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Total: ₹${bill.finalTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.share, color: Colors.blue),
                                          onPressed: () => context.read<DailySalesCubit>().shareBillPdf(bill.id!),
                                          tooltip: 'Share PDF',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.visibility, color: Colors.grey),
                                          onPressed: () => context.read<DailySalesCubit>().viewBill(bill.id!),
                                          tooltip: 'View Bill',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange),
                                          onPressed: () => context.read<DailySalesCubit>().editBill(bill.id!),
                                          tooltip: 'Edit Bill',
                                        ),
                                      ],
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                          );
                        },
                      );
                    } else if (state is DailySalesError) {
                      return Center(child: Text('Error: ${state.message}'));
                    }
                    return const Center(child: Text('No sales data'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void loadBillForView(BuildContext context, int billId) async {
    final billingCubit = context.read<BillingCubit>();
    await billingCubit.loadBillForView(billId);
    context.router.push(BillDetailRoute());
  }

  void loadBillForEdit(BuildContext context, int billId) async {
    final billingCubit = context.read<BillingCubit>();
    await billingCubit.loadBillForView(billId); // Same for edit, but for edit, navigate to billing screen
    context.router.push(BillingRoute());
  }

  Widget _buildSummaryTile(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    // Convert YYYY-MM-DD to DD-MM-YYYY
    final parts = dateString.split('-');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dateString; // fallback if format is unexpected
  }

  Widget _buildTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return const Text('📈', style: TextStyle(fontSize: 20));
      case 'down':
        return const Text('📉', style: TextStyle(fontSize: 20));
      default:
        return const Text('➡️', style: TextStyle(fontSize: 20));
    }
  }
}