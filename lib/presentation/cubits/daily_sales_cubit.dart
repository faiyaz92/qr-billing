import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_bill_repository.dart';
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
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';

  DailySalesCubit(this._billRepository) : super(DailySalesInitial()) {
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
        final matchesSearch = _searchQuery.isEmpty || bill.id.toString().contains(_searchQuery);
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

        double totalSales = 0;
        double totalPurchase = 0;

        for (final bill in dayBills) {
          totalSales += bill.finalTotal;
          // Calculate purchase amount from bill items for accurate profit tracking
          final items = await _billRepository.getBillItems(bill.id!);
          double billPurchaseAmount = 0.0;
          for (final item in items) {
            billPurchaseAmount += item.purchasePrice * item.quantity;
          }
          totalPurchase += billPurchaseAmount;
        }

        final totalProfit = totalSales - totalPurchase;
        final profitPercentage = totalSales > 0 ? (totalProfit / totalSales) * 100 : 0.0;

        dailySales.add(DailySales(
          date: date,
          totalSales: totalSales,
          totalPurchase: totalPurchase,
          totalProfit: totalProfit,
          profitPercentage: profitPercentage,
          bills: dayBills,
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

      // Generate PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Center(
                    child: pw.Text(
                      'BILL RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Bill Info
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill ID: ${bill.id}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Customer: ${bill.customerName ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          'Mobile: ${bill.customerMobile ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          'Date: ${bill.date}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Items Header
                  pw.Text(
                    'Items:',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),

                  // Items List
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Header Row
                      pw.TableRow(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      // Item Rows
                      ...billItems.map((item) {
                        final itemTotal = item.sellingPrice * item.quantity;
                        return pw.TableRow(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(item.itemName),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('${item.quantity}'),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('₹${item.sellingPrice.toStringAsFixed(2)}'),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('₹${itemTotal.toStringAsFixed(2)}'),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Summary
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Subtotal: ₹${bill.totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        // Note: Tax amount is not stored separately in Bill model
                        if (bill.discount != null && bill.discount! > 0)
                          pw.Text(
                            'Discount: ₹${bill.discount!.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 14),
                          ),
                        pw.Text(
                          'Final Total: ₹${bill.finalTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save PDF to temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/bill_${billId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Bill Receipt - ${bill.customerName ?? 'Customer'}',
        subject: 'Bill Receipt',
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