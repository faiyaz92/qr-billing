import '../database_helper.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../../domain/repositories/i_bill_repository.dart';

class BillRepositoryImpl implements IBillRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<int> insertBill(Bill bill) => _dbHelper.insertBill(bill);

  @override
  Future<List<Bill>> getBillsByDate(String date) => _dbHelper.getBillsByDate(date);

  @override
  Future<List<Bill>> getAllBills() => _dbHelper.getAllBills();

  @override
  Future<Bill?> getBillById(int id) => _dbHelper.getBillById(id);

  @override
  Future<int> insertBillItem(BillItem item) => _dbHelper.insertBillItem(item);

  @override
  Future<List<BillItem>> getBillItems(int billId) => _dbHelper.getBillItems(billId);

  @override
  Future<double> getBillProfit(int billId) => _dbHelper.getBillProfit(billId);
}