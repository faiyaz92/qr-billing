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
            _loadBillForView(context, state.billId);
          } else if (state is DailySalesEditBill) {
            _loadBillForEdit(context, state.billId);
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
                colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
              ),
            ),
            child: Column(
              children: [
                const _MonthlySummaryHeader(),
                const _FilterSection(),
                Expanded(
                  child: BlocBuilder<DailySalesCubit, DailySalesState>(
                    buildWhen: (prev, curr) => curr is DailySalesLoaded || curr is DailySalesLoading || curr is DailySalesError,
                    builder: (context, state) {
                      if (state is DailySalesLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is DailySalesLoaded) {
                        if (state.dailySales.isEmpty) {
                          return const Center(child: Text('No sales data for this period'));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.dailySales.length,
                          itemBuilder: (context, index) => _DailySalesCard(day: state.dailySales[index]),
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

  void _loadBillForView(BuildContext context, int billId) async {
    final billingCubit = context.read<BillingCubit>();
    await billingCubit.loadBillForView(billId);
    if (context.mounted) context.router.push(BillDetailRoute());
  }

  void _loadBillForEdit(BuildContext context, int billId) async {
    final billingCubit = context.read<BillingCubit>();
    await billingCubit.loadBillForView(billId);
    if (context.mounted) context.router.push(BillingRoute());
  }
}

// Atomic Components
class _MonthlySummaryHeader extends StatelessWidget {
  const _MonthlySummaryHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailySalesCubit, DailySalesState>(
      buildWhen: (prev, curr) => curr is DailySalesLoaded,
      builder: (context, state) {
        if (state is! DailySalesLoaded) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: _SummaryTile('Monthly Sales', '₹${state.monthlySales.toStringAsFixed(0)}', Icons.trending_up, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryTile('Monthly Profit', '₹${state.monthlyProfit.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryTile('COGS', '₹${state.monthlyCOGS.toStringAsFixed(0)}', Icons.inventory, Colors.orange)),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryTile(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<DailySalesCubit, DailySalesState>(
                  buildWhen: (prev, curr) => curr is DailySalesLoaded,
                  builder: (context, state) {
                    final selectedMonth = (state is DailySalesLoaded) ? state.selectedMonth : DateTime.now().month;
                    return DropdownButtonFormField<int>(
                      value: selectedMonth,
                      decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
                  buildWhen: (prev, curr) => curr is DailySalesLoaded,
                  builder: (context, state) {
                    final selectedYear = (state is DailySalesLoaded) ? state.selectedYear : DateTime.now().year;
                    return DropdownButtonFormField<int>(
                      value: selectedYear,
                      decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: List.generate(5, (index) => DropdownMenuItem(
                        value: DateTime.now().year - index,
                        child: Text((DateTime.now().year - index).toString()),
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
            buildWhen: (prev, curr) => curr is DailySalesLoaded,
            builder: (context, state) {
              return TextField(
                decoration: const InputDecoration(labelText: 'Search Bill, Customer or Mobile', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), prefixIcon: Icon(Icons.search)),
                onChanged: (value) => context.read<DailySalesCubit>().setSearchQuery(value),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DailySalesCard extends StatelessWidget {
  final DailySales day;
  const _DailySalesCard({required this.day});

  String _formatDate(String dateString) {
    final parts = dateString.split('-');
    if (parts.length == 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
    return dateString;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF1E40AF), size: 20),
              const SizedBox(width: 8),
              Text(_formatDate(day.date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
              const SizedBox(width: 12),
              _TrendIcon(trend: day.trend),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SubDetailRow(icon: Icons.trending_up, label: 'Sales: ₹${day.totalSales.toStringAsFixed(0)}', color: Colors.blue),
                _SubDetailRow(icon: Icons.inventory, label: 'COGS: ₹${day.totalPurchase.toStringAsFixed(0)}', color: Colors.orange),
                _SubDetailRow(
                  icon: day.totalProfit >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  label: 'Profit: ₹${day.totalProfit.toStringAsFixed(0)} (${day.profitPercentage >= 0 ? '+' : ''}${day.profitPercentage.toStringAsFixed(1)}%)',
                  color: day.totalProfit >= 0 ? Colors.green : Colors.red,
                  isBold: true,
                ),
              ],
            ),
          ),
          children: day.bills.reversed.map((bill) => _BillListTile(bill: bill, displayTotal: day.billDisplayTotals[bill.id] ?? bill.finalTotal)).toList(),
        ),
      ),
    );
  }
}

class _SubDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isBold;
  const _SubDetailRow({required this.icon, required this.label, required this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  final String trend;
  const _TrendIcon({required this.trend});

  @override
  Widget build(BuildContext context) {
    switch (trend) {
      case 'up': return const Text('📈', style: TextStyle(fontSize: 20));
      case 'down': return const Text('📉', style: TextStyle(fontSize: 20));
      default: return const Text('➡️', style: TextStyle(fontSize: 20));
    }
  }
}

class _BillListTile extends StatelessWidget {
  final dynamic bill;
  final double displayTotal;
  const _BillListTile({required this.bill, required this.displayTotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFF1E40AF), child: Text('${bill.id}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        title: Text('Bill #${bill.id}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
        subtitle: Text('Final Total: ₹${displayTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.share, color: Colors.blue), onPressed: () => context.read<DailySalesCubit>().shareBillPdf(bill.id!), tooltip: 'Share PDF'),
            IconButton(icon: const Icon(Icons.visibility, color: Colors.grey), onPressed: () => context.read<DailySalesCubit>().viewBill(bill.id!), tooltip: 'View Bill'),
            IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => context.read<DailySalesCubit>().editBill(bill.id!), tooltip: 'Edit Bill'),
          ],
        ),
      ),
    );
  }
}