import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_bill_repository.dart';
import '../../core/services/i_settings_service.dart';
import '../../core/services/pdf_generator_service.dart';
import '../../data/models/bill.dart';
import '../../data/models/bill_item.dart';
import 'daily_sales_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class DailySalesCubit extends Cubit<DailySalesState> {
  final IBillRepository _billRepository;
  final ISettingsService _settingsService;
  final PdfGeneratorService _pdfGeneratorService;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';

  DailySalesCubit(this._billRepository, this._settingsService, this._pdfGeneratorService) : super(DailySalesInitial()) {
    loadSales();
  }

  Future<void> loadSales({int? month, int? year}) async {
    emit(DailySalesLoading());
    try {
      if (month != null) _selectedMonth = month;
      if (year != null) _selectedYear = year;
      final bills = await _billRepository.getAllBills();
      final filteredBills = bills.where((bill) {
        final billDate = DateTime.parse(bill.date);
        final matchesMonthYear = billDate.month == _selectedMonth && billDate.year == _selectedYear;
        
        final query = _searchQuery.toLowerCase();
        final matchesSearch = _searchQuery.isEmpty || 
            bill.id.toString().contains(_searchQuery) ||
            (bill.customerName?.toLowerCase().contains(query) ?? false) ||
            (bill.customerMobile?.contains(_searchQuery) ?? false);
            
        return matchesMonthYear && matchesSearch;
      }).toList();
      final Map<String, List<Bill>> billsByDate = {};

      for (final bill in filteredBills) {
        final date = bill.date.split(' ')[0]; // Assuming date is in YYYY-MM-DD format
        if (!billsByDate.containsKey(date)) {
          billsByDate[date] = [];
        }
        billsByDate[date]!.add(bill);
      }

      final List<DailySales> dailySales = [];
      for (final entry in billsByDate.entries) {
        final date = entry.key;
        final dayBills = entry.value;

        double totalSales = 0;    // with tax — what customer paid
        double totalPurchase = 0;
        double totalRevenue = 0;   // without tax — our actual revenue for profit
        final Map<int, double> billDisplayTotals = {}; // bill_id → finalTotal with tax

        for (final bill in dayBills) {
          final items = await _billRepository.getBillItems(bill.id!);

          double billSubtotal = 0.0;
          double billTaxAmount = 0.0;
          double billPurchaseAmount = 0.0;

          for (final item in items) {
            final sellingPrice = item.sellingPrice;
            final itemDiscount = item.itemDiscount ?? 0.0;
            final effectivePrice = sellingPrice - itemDiscount;
            final itemTotal = effectivePrice * item.quantity;
            final taxRate = item.taxRate ?? 0.0;
            
            billSubtotal += itemTotal;
            billTaxAmount += itemTotal * (taxRate / 100);
            billPurchaseAmount += item.purchasePrice * item.quantity;
          }

          final finalTotalWithTax = billSubtotal + billTaxAmount - (bill.discount ?? 0.0);
          
          billDisplayTotals[bill.id!] = finalTotalWithTax;
          totalSales += finalTotalWithTax;
          
          totalRevenue += billSubtotal - (bill.discount ?? 0.0);
          totalPurchase += billPurchaseAmount;
        }

        final totalProfit = totalRevenue - totalPurchase;
 // profit without tax ✅
        final profitPercentage = totalPurchase > 0 ? (totalProfit / totalPurchase) * 100 : 0.0;

        dailySales.add(DailySales(
          date: date,
          totalSales: totalSales,
          totalPurchase: totalPurchase,
          totalProfit: totalProfit,
          profitPercentage: profitPercentage,
          bills: dayBills,
          billDisplayTotals: billDisplayTotals,
        ));
      }

      // Sort by date descending
      dailySales.sort((a, b) => b.date.compareTo(a.date));

      // Calculate trends
      for (int i = 0; i < dailySales.length - 1; i++) {
        final current = dailySales[i];
        final previous = dailySales[i + 1];
        if (current.totalSales > previous.totalSales) {
          dailySales[i] = DailySales(
            date: current.date,
            totalSales: current.totalSales,
            totalPurchase: current.totalPurchase,
            totalProfit: current.totalProfit,
            profitPercentage: current.profitPercentage,
            bills: current.bills,
            billDisplayTotals: current.billDisplayTotals,
            trend: 'up',
          );
        } else if (current.totalSales < previous.totalSales) {
          dailySales[i] = DailySales(
            date: current.date,
            totalSales: current.totalSales,
            totalPurchase: current.totalPurchase,
            totalProfit: current.totalProfit,
            profitPercentage: current.profitPercentage,
            bills: current.bills,
            billDisplayTotals: current.billDisplayTotals,
            trend: 'down',
          );
        } else {
          dailySales[i] = DailySales(
            date: current.date,
            totalSales: current.totalSales,
            totalPurchase: current.totalPurchase,
            totalProfit: current.totalProfit,
            profitPercentage: current.profitPercentage,
            bills: current.bills,
            billDisplayTotals: current.billDisplayTotals,
            trend: 'neutral',
          );
        }
      }

      // Calculate monthly totals
      double monthlySales = 0.0;
      double monthlyProfit = 0.0;
      double monthlyCOGS = 0.0;
      for (final day in dailySales) {
        monthlySales += day.totalSales;
        monthlyProfit += day.totalProfit;
        monthlyCOGS += day.totalPurchase;
      }

      emit(DailySalesLoaded(dailySales, selectedMonth: _selectedMonth, selectedYear: _selectedYear, searchQuery: _searchQuery, monthlySales: monthlySales, monthlyProfit: monthlyProfit, monthlyCOGS: monthlyCOGS));
    } catch (e) {
      emit(DailySalesError(e.toString()));
    }
  }

  void changeMonth(int month) {
    _selectedMonth = month;
    loadSales();
  }

  void changeYear(int year) {
    _selectedYear = year;
    loadSales();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadSales();
  }

  Future<void> shareBillPdf(int billId) async {
    try {
      // Get bill data
      final bill = await _billRepository.getBillById(billId);
      if (bill == null) {
        throw Exception('Bill not found');
      }

      // Get bill items
      final billItems = await _billRepository.getBillItems(billId);

      // Get store name
      final storeName = await _settingsService.getStoreName() ?? 'Store';

      // Generate PDF using centralized service
      final items = billItems.map((item) {
        final sellingPrice = item.sellingPrice;
        final discount = item.itemDiscount ?? 0.0;
        final effectivePrice = sellingPrice - discount;
        final itemTotalBeforeTax = effectivePrice * item.quantity;
        final taxRate = item.taxRate ?? 0.0;
        final taxAmount = itemTotalBeforeTax * (taxRate / 100);
        final itemTotalAfterTax = itemTotalBeforeTax + taxAmount;

        return {
          'name': item.itemName ?? 'Unknown',
          'quantity': item.quantity,
          'mrp': item.originalPrice ?? sellingPrice,
          'price': sellingPrice,
          'discount': discount,
          'amtExclTax': itemTotalBeforeTax,
          'taxRate': taxRate,
          'taxAmount': taxAmount,
          'total': itemTotalAfterTax,
        };
      }).toList();

      // Calculate Rock Solid savings for PDF
      final subtotal = bill.totalAmount;
      final taxAmount = billItems.fold<double>(0, (sum, item) => sum + (((item.sellingPrice - (item.itemDiscount ?? 0.0)) * item.quantity) * (item.taxRate ?? 0.0) / 100));
      final taxRate = subtotal > 0 ? (taxAmount / subtotal) : 0.0;
      // Now using stored originalPrice (MRP) from database
      final originalTotal = billItems.fold<double>(0, (sum, item) => sum + ((item.originalPrice ?? item.sellingPrice) * item.quantity));
      final originalTotalWithTax = originalTotal + (originalTotal * taxRate);
      final youSave = originalTotalWithTax - bill.finalTotal;

      final summary = {
        'subtotal': subtotal,
        'totalItemDiscounts': billItems.fold<double>(0, (sum, item) => sum + ((item.itemDiscount ?? 0.0) * item.quantity)),
        'taxAmount': taxAmount,
        'discount': bill.discount ?? 0.0,
        'finalTotal': bill.finalTotal,
        'youSave': youSave,
      };

      final pdfBytes = await _pdfGeneratorService.generateBillPdf(
        storeName: storeName,
        customerName: bill.customerName ?? 'N/A',
        customerMobile: bill.customerMobile ?? 'N/A',
        date: bill.date,
        items: items,
        summary: summary,
      );

      // Save PDF to temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/bill_${billId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);

      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$storeName bill - ${bill.customerName ?? 'Customer'}',
        subject: '$storeName Bill',
      );
    } catch (e) {
      throw Exception('Failed to share bill PDF: $e');
    }
  }

  Future<void> viewBill(int billId) async {
    emit(DailySalesViewBill(billId));
  }

  Future<void> editBill(int billId) async {
    emit(DailySalesEditBill(billId));
  }
}