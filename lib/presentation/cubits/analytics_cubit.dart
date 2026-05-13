import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_bill_repository.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../data/models/bill.dart';

abstract class AnalyticsState {}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final double todaySales;
  final double monthlySales;
  final double monthlyProfit;
  final int totalProducts;
  final double averageOrderValue;
  final Map<String, double> categorySales;
  final List<RecentActivity> recentActivities;

  AnalyticsLoaded({
    required this.todaySales,
    required this.monthlySales,
    required this.monthlyProfit,
    required this.totalProducts,
    required this.averageOrderValue,
    required this.categorySales,
    required this.recentActivities,
  });
}

class AnalyticsError extends AnalyticsState {
  final String message;
  AnalyticsError(this.message);
}

class RecentActivity {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  RecentActivity({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class AnalyticsCubit extends Cubit<AnalyticsState> {
  final IBillRepository _billRepository;
  final IProductRepository _productRepository;

  AnalyticsCubit(this._billRepository, this._productRepository) : super(AnalyticsInitial());

  Future<void> loadAnalytics() async {
    emit(AnalyticsLoading());
    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final allBills = await _billRepository.getAllBills();
      
      double todaySalesTotal = 0.0;
      double monthlySalesTotal = 0.0;
      double monthlyProfitTotal = 0.0;
      final Map<String, double> brandSales = {};

      for (final bill in allBills) {
        final isToday = bill.date.startsWith(todayStr);
        final isThisMonth = bill.date.startsWith(currentMonthStr);

        if (isToday || isThisMonth) {
          final items = await _billRepository.getBillItems(bill.id!);
          
          double billSubtotal = 0.0;
          double billTaxAmount = 0.0;
          double billPurchaseAmount = 0.0;

          for (final item in items) {
            final effectivePrice = item.sellingPrice - (item.itemDiscount ?? 0.0);
            final itemTotal = effectivePrice * item.quantity;
            
            billSubtotal += itemTotal;
            billTaxAmount += itemTotal * ((item.taxRate ?? 0.0) / 100);
            billPurchaseAmount += item.purchasePrice * item.quantity;

            if (isThisMonth) {
              // Track sales by brand/category
              final category = item.itemName.split(' ')[0]; // Simplified: use first word of name as category if brand not available
              brandSales[category] = (brandSales[category] ?? 0) + itemTotal;
            }
          }

          final finalTotalWithTax = billSubtotal + billTaxAmount - (bill.discount ?? 0.0);
          
          if (isToday) todaySalesTotal += finalTotalWithTax;
          if (isThisMonth) {
            monthlySalesTotal += finalTotalWithTax;
            monthlyProfitTotal += (billSubtotal - (bill.discount ?? 0.0)) - billPurchaseAmount;
          }
        }
      }

      final allProducts = await _productRepository.getAllProducts();
      final averageOrderValue = allBills.isEmpty ? 0.0 : monthlySalesTotal / (allBills.where((b) => b.date.startsWith(currentMonthStr)).length.clamp(1, 999999));

      emit(AnalyticsLoaded(
        todaySales: todaySalesTotal,
        monthlySales: monthlySalesTotal,
        monthlyProfit: monthlyProfitTotal,
        totalProducts: allProducts.length,
        averageOrderValue: averageOrderValue,
        categorySales: brandSales,
        recentActivities: _generateRecentActivities(allBills),
      ));
    } catch (e) {
      emit(AnalyticsError('Failed to load analytics: ${e.toString()}'));
    }
  }

  List<RecentActivity> _generateRecentActivities(List<Bill> bills) {
    final sortedBills = List<Bill>.from(bills)..sort((a, b) => b.date.compareTo(a.date));
    return sortedBills.take(5).map((bill) => RecentActivity(
      title: 'Sale completed',
      subtitle: 'Bill #${bill.id} - ₹${bill.finalTotal.toStringAsFixed(0)}',
      time: _getTimeAgo(bill.date),
      icon: Icons.receipt,
      color: Colors.blue,
    )).toList();
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) { return 'Recently'; }
  }
}