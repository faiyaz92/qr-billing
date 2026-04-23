import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/i_scan_service.dart';
import '../../data/models/scanned_data.dart';

abstract class QuickScanState {}

class QuickScanInitial extends QuickScanState {}

class QuickScanLoading extends QuickScanState {}

class QuickScanSuccess extends QuickScanState {
  final ScannedData scannedData;
  QuickScanSuccess(this.scannedData);
}

class QuickScanError extends QuickScanState {
  final String message;
  QuickScanError(this.message);
}

class QuickScanCubit extends Cubit<QuickScanState> {
  final IScanService _scanService;

  QuickScanCubit(this._scanService) : super(QuickScanInitial());

  Future<void> quickScanProduct(String qrCode) async {
    emit(QuickScanLoading());
    try {
      final scannedData = await _scanService.scanAndDecode(qrCode);
      if (scannedData != null) {
        // Check if type is 1 (customer product)
        if (scannedData.signature?.type == 1) {
          emit(QuickScanSuccess(scannedData));
        } else {
          emit(QuickScanError('This QR code is not for customer product display. Type: ${scannedData.signature?.type ?? 'unknown'}'));
        }
      } else {
        emit(QuickScanError('Invalid QR code'));
      }
    } catch (e) {
      emit(QuickScanError(e.toString()));
    }
  }
}