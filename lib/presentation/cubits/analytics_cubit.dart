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
      // Get current date
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Get today's bills
      final todayBills = await _billRepository.getBillsByDate(today);
      final todaySales = todayBills.fold<double>(0, (sum, bill) => sum + bill.finalTotal);

      // Get all bills for monthly calculations
      final allBills = await _billRepository.getAllBills();
      final monthlyBills = allBills.where((bill) => bill.date.startsWith(currentMonth)).toList();
      final monthlySales = monthlyBills.fold<double>(0, (sum, bill) => sum + bill.finalTotal);

      // Calculate real monthly profit from bill items
      double monthlyProfit = 0.0;
      for (final bill in monthlyBills) {
        final billItems = await _billRepository.getBillItems(bill.id!);
        for (final item in billItems) {
          final profit = (item.sellingPrice - item.purchasePrice - (item.itemDiscount ?? 0)) * item.quantity;
          monthlyProfit += profit;
        }
        // Subtract bill discount
        monthlyProfit -= bill.discount ?? 0;
      }

      // Get total products count
      final allProducts = await _productRepository.getAllProducts();
      final totalProducts = allProducts.length;

      // Calculate average order value
      final averageOrderValue = allBills.isEmpty ? 0.0 : allBills.fold<double>(0, (sum, bill) => sum + bill.finalTotal) / allBills.length;

      // Generate category sales from actual bill items (sales by brand)
      final categorySales = <String, double>{};
      for (final bill in monthlyBills) {
        final billItems = await _billRepository.getBillItems(bill.id!);
        for (final item in billItems) {
          if (item.productId != null) {
            final product = await _productRepository.getProductById(item.productId!);
            if (product != null) {
              final category = product.brand ?? 'Other';
              final salesAmount = item.sellingPrice * item.quantity;
              categorySales[category] = (categorySales[category] ?? 0) + salesAmount;
            }
          }
        }
      }

      // Generate recent activities from real bills
      final recentActivities = _generateRecentActivities(allBills);

      emit(AnalyticsLoaded(
        todaySales: todaySales,
        monthlySales: monthlySales,
        monthlyProfit: monthlyProfit,
        totalProducts: totalProducts,
        averageOrderValue: averageOrderValue,
        categorySales: categorySales,
        recentActivities: recentActivities,
      ));
    } catch (e) {
      emit(AnalyticsError('Failed to load analytics: ${e.toString()}'));
    }
  }

  List<RecentActivity> _generateRecentActivities(List<Bill> bills) {
    final activities = <RecentActivity>[];

    // Sort bills by date (most recent first)
    bills.sort((a, b) => b.date.compareTo(a.date));

    for (final bill in bills.take(4)) {
      activities.add(RecentActivity(
        title: 'Sale completed',
        subtitle: '₹${bill.finalTotal.toStringAsFixed(2)} bill generated',
        time: _getTimeAgo(bill.date),
        icon: Icons.receipt,
        color: Colors.blue,
      ));
    }

    // Add some default activities if we don't have enough bills
    if (activities.length < 4) {
      activities.addAll([
        RecentActivity(
          title: 'Welcome to Analytics',
          subtitle: 'Start making sales to see real data',
          time: 'Now',
          icon: Icons.info,
          color: Colors.blue,
        ),
      ]);
    }

    return activities.take(4).toList();
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return '${difference.inMinutes} min ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}