import 'package:equatable/equatable.dart';
import '../../data/models/bill.dart';

abstract class DailySalesState extends Equatable {
  const DailySalesState();

  @override
  List<Object?> get props => [];
}

class DailySalesInitial extends DailySalesState {}

class DailySalesLoading extends DailySalesState {}

class DailySalesLoaded extends DailySalesState {
  final List<DailySales> dailySales;
  final int selectedMonth;
  final int selectedYear;
  final String searchQuery;
  final double monthlySales;
  final double monthlyProfit;
  final double monthlyCOGS;

  const DailySalesLoaded(this.dailySales, {
    this.selectedMonth = 4,
    this.selectedYear = 2026,
    this.searchQuery = '',
    this.monthlySales = 0.0,
    this.monthlyProfit = 0.0,
    this.monthlyCOGS = 0.0,
  });

  @override
  List<Object?> get props => [dailySales, selectedMonth, selectedYear, searchQuery, monthlySales, monthlyProfit, monthlyCOGS];
}

class DailySalesError extends DailySalesState {
  final String message;

  const DailySalesError(this.message);

  @override
  List<Object?> get props => [message];
}

class DailySalesViewBill extends DailySalesState {
  final int billId;

  const DailySalesViewBill(this.billId);

  @override
  List<Object?> get props => [billId];
}

class DailySalesEditBill extends DailySalesState {
  final int billId;

  const DailySalesEditBill(this.billId);

  @override
  List<Object?> get props => [billId];
}

class DailySales {
  final String date;
  final double totalSales;
  final double totalPurchase;
  final double totalProfit;
  final double profitPercentage;
  final List<Bill> bills;
  final String trend; // 'up', 'down', or 'neutral'

  DailySales({
    required this.date,
    required this.totalSales,
    required this.totalPurchase,
    required this.totalProfit,
    required this.profitPercentage,
    required this.bills,
    this.trend = 'neutral',
  });
}