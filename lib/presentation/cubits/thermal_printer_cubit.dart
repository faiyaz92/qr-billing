import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/i_thermal_printer_service.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';

abstract class ThermalPrinterState {}

class ThermalPrinterInitial extends ThermalPrinterState {}

class ThermalPrinterLoading extends ThermalPrinterState {
  final String message;
  ThermalPrinterLoading(this.message);
}

class ThermalPrinterLoaded extends ThermalPrinterState {
  final bool isConnected;
  final List<String> discoveredPrinters;
  final String? selectedPrinterAddress;
  final bool isScanning;
  final bool isInitialized;

  ThermalPrinterLoaded({
    required this.isConnected,
    required this.discoveredPrinters,
    this.selectedPrinterAddress,
    this.isScanning = false,
    this.isInitialized = false,
  });

  ThermalPrinterLoaded copyWith({
    bool? isConnected,
    List<String>? discoveredPrinters,
    String? selectedPrinterAddress,
    bool? isScanning,
    bool? isInitialized,
  }) {
    return ThermalPrinterLoaded(
      isConnected: isConnected ?? this.isConnected,
      discoveredPrinters: discoveredPrinters ?? this.discoveredPrinters,
      selectedPrinterAddress: selectedPrinterAddress ?? this.selectedPrinterAddress,
      isScanning: isScanning ?? this.isScanning,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ThermalPrinterError extends ThermalPrinterState {
  final String message;
  ThermalPrinterError(this.message);
}

class ThermalPrinterCubit extends Cubit<ThermalPrinterState> {
  final IThermalPrinterService _printerService;

  ThermalPrinterCubit(this._printerService) : super(ThermalPrinterInitial()) {
    checkStatus();
  }

  void checkStatus() {
    final isConnected = _printerService.isConnected;
    emit(ThermalPrinterLoaded(
      isConnected: isConnected,
      discoveredPrinters: [],
      isInitialized: isConnected,
    ));
  }

  Future<void> initializeBluetooth() async {
    final currentState = state;
    if (currentState is ThermalPrinterLoaded) {
      emit(ThermalPrinterLoading('Initializing Bluetooth...'));
      // Logic handled in screen for permissions for now, or move to a service
      emit(currentState.copyWith(isInitialized: true));
    }
  }

  Future<void> scanPrinters() async {
    final currentState = state;
    if (currentState is ThermalPrinterLoaded) {
      emit(currentState.copyWith(isScanning: true));
      try {
        final printers = await _printerService.discoverPrinters();
        emit(currentState.copyWith(discoveredPrinters: printers, isScanning: false));
      } catch (e) {
        emit(ThermalPrinterError('Scan failed: $e'));
        emit(currentState.copyWith(isScanning: false));
      }
    }
  }

  void selectPrinter(String address) {
    final currentState = state;
    if (currentState is ThermalPrinterLoaded) {
      emit(currentState.copyWith(selectedPrinterAddress: address));
    }
  }

  Future<void> connect() async {
    final currentState = state;
    if (currentState is ThermalPrinterLoaded && currentState.selectedPrinterAddress != null) {
      emit(currentState.copyWith(isScanning: true)); // Reuse scanning for connection loading
      try {
        final success = await _printerService.connectToPrinter(currentState.selectedPrinterAddress!);
        emit(currentState.copyWith(isConnected: success, isScanning: false));
      } catch (e) {
        emit(ThermalPrinterError('Connection failed: $e'));
        emit(currentState.copyWith(isScanning: false));
      }
    }
  }

  Future<void> disconnect() async {
    final currentState = state;
    if (currentState is ThermalPrinterLoaded) {
      await _printerService.disconnect();
      emit(currentState.copyWith(isConnected: false));
    }
  }

  Future<void> testPrint() async {
    final currentState = state;
    if (currentState is ThermalPrinterLoaded && currentState.isConnected) {
      final testData = [
        LineText(type: LineText.TYPE_TEXT, content: 'Test Print', align: LineText.ALIGN_CENTER),
        LineText(linefeed: 2),
      ];
      await _printerService.printReceipt(testData);
    }
  }
}
