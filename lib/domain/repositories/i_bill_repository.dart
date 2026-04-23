import '../../data/models/bill.dart';
import '../../data/models/bill_item.dart';

abstract class IBillRepository {
  Future<int> insertBill(Bill bill);
  Future<int> updateBill(Bill bill);
  Future<List<Bill>> getBillsByDate(String date);
  Future<List<Bill>> getAllBills();
  Future<Bill?> getBillById(int id);
  Future<int> insertBillItem(BillItem item);
  Future<int> deleteBillItems(int billId);
  Future<List<BillItem>> getBillItems(int billId);
  Future<double> getBillProfit(int billId);
}