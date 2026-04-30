# Technical Documentation
## QR-Based Billing System

### System Architecture

#### Technology Stack
- **Frontend**: Flutter (Dart)
- **Database**: SQLite (sqflite)
- **State Management**: Flutter Bloc (Cubit pattern)
- **Dependency Injection**: GetIt
- **Encryption**: AES encryption for sensitive data

#### Architecture Pattern
- **Clean Architecture**: UI → Cubit → Service → Repository → Database
- **Separation of Concerns**: Business logic, data access, UI logic separated
- **SOLID Principles**: Interface-based design with dependency injection

#### Dependency Injection Coding Standard
**Rule: All Cubits, Services, and Repositories must be instantiated only through Dependency Injection**

- **Cubits**: All cubits must inject services and repositories through constructor parameters
- **Services**: All services must inject their dependencies (encryption, settings, etc.) through constructor
- **Repositories**: All repositories must inject their dependencies through constructor
- **UI Layer**: No screen can manually instantiate cubits - only use `getIt<CubitName>()`

**✅ Correct Pattern:**
```dart
// Cubit with injected dependencies
class BillingCubit extends Cubit<BillingState> {
  final IScanService _scanService;
  final IBillRepository _billRepository;

  BillingCubit(this._scanService, this._billRepository) : super(BillingInitial());
}

// getIt registration
getIt.registerFactory<BillingCubit>(() => BillingCubit(
  getIt<IScanService>(),
  getIt<IBillRepository>(),
));

// UI usage
BlocProvider(create: (_) => getIt<BillingCubit>())
```

**❌ Wrong Pattern (Avoid):**
```dart
// Manual instantiation - NOT ALLOWED
BlocProvider(create: (_) => BillingCubit(ScanServiceImpl(), BillRepositoryImpl()))

// getIt inside cubit - NOT ALLOWED
class BillingCubit extends Cubit<BillingState> {
  final IScanService _scanService = getIt<IScanService>(); // ❌ Wrong
}
```

**Benefits:**
- **Testability**: All dependencies can be mocked for unit testing
- **Maintainability**: Dependency changes only need to be made in injection.dart
- **Consistency**: All objects follow the same dependency injection pattern
- **Clean Code**: No manual object creation, only `getIt<ObjectName>()`

### Database Schema

#### 1. products Table
```sql
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  brand TEXT,
  date_of_purchase TEXT,
  purchase_price REAL NOT NULL,
  selling_price REAL NOT NULL,
  original_price REAL,
  tax REAL,
  qr_data TEXT
)
```

#### 2. bills Table
```sql
CREATE TABLE bills (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  total_amount REAL NOT NULL,
  discount REAL,
  final_total REAL NOT NULL
)
```

#### 3. bill_items Table
```sql
CREATE TABLE bill_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bill_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  item_discount REAL,
  FOREIGN KEY (bill_id) REFERENCES bills (id),
  FOREIGN KEY (product_id) REFERENCES products (id)
)
```

### QR Code Technical Specification

#### QR Structure
```json
{
  "encrypted_signature": "base64_encrypted_signature_json",
  "data": {
    "name": "Product Name",
    "brand": "Brand Name",
    "tax": 50.0,
    "selling_price": 600.0,
    "original_price": 650.0,
    "encrypted_sensitive": "base64_encrypted_sensitive_data"
  }
}
```

#### Signature Structure (Decrypted)
```json
{
  "app_signature": "QR_BILLING_APP",
  "store_signature": "user_defined_store_secret",
  "type": 1
}
```

### Add Product Flow (Technical)

1. **Data Collection**: User inputs product details
2. **Data Separation**:
   - Public: name, brand, tax, selling_price, original_price
   - Sensitive: date_of_purchase, purchase_price
3. **Encryption**: Sensitive data encrypted with AES
4. **QR Generation**: Complete JSON structure created
5. **Signature**: App/store/type signature encrypted
6. **Storage**: Product saved to database with full QR data

### QR Scanning Flow (Technical)

1. **Raw Input**: Complete JSON string from QR scanner
2. **JSON Parsing**: `jsonDecode()` converts to Map
3. **Auto-Separation**: `QrData.fromJson()` separates fields
4. **Signature Decryption**: AES decryption of signature field
5. **Validation**: App, store, type signature checks
6. **Data Return**: Validated ScannedData object or null

### Signature Recognition Mechanism

#### Validation Process
```dart
// Extract signature
final qrData = QrData.fromJson(jsonDecode(qrCode));
final decryptedSig = _encryption.decryptData(qrData.encryptedSignature);
final signature = QrSignature.fromJson(jsonDecode(decryptedSig));

// Validate components
if (signature.appSignature != 'QR_BILLING_APP') return null;
if (signature.storeSignature != currentStoreSecret) return null;
if (signature.type != 1) return null;
```

#### Security Layers
- **App Validation**: Prevents fake QR codes
- **Store Validation**: Ensures store-specific QR codes
- **Type Validation**: Future-proof format changes
- **Encryption**: AES protection of signature data

### Cubit State Management

#### BillingCubit States
- `BillingInitial`: Initial state
- `BillingLoading`: Processing scan/add operations
- `BillingUpdated`: Cart updated with items, discounts, customer info
- `BillingError`: Error state with message

#### DailySalesCubit States
- `DailySalesInitial`: Initial state
- `DailySalesLoading`: Loading sales data
- `DailySalesLoaded`: Sales data loaded with filters
- `DailySalesError`: Error state
- `DailySalesViewBill`: Trigger bill view navigation
- `DailySalesEditBill`: Trigger bill edit navigation

### Key Calculations

#### Profit Calculations
```dart
// Per bill profit
billProfit = (sellingPrice × quantity) - (purchasePrice × quantity) - itemDiscount - billDiscount

// Daily profit
dailyProfit = Σ(billProfit for all bills in day)

// Monthly profit
monthlyProfit = Σ(dailyProfit for all days in month)
```

#### Tax Calculations
```dart
// Tax per product (after discount)
taxAmount = (sellingPrice - itemDiscount) × (taxPercentage / 100)

// Total tax
totalTax = Σ(taxAmount for all items)
```

#### Validation Rules
```dart
// Product loss check
isLoss = (sellingPrice - itemDiscount) < purchasePrice

// Bill loss check
isBillLoss = totalSellingAmount < totalPurchaseAmount
```

### Dependencies & Libraries

#### Core Dependencies
- `flutter_bloc: ^9.1.1` - State management
- `sqflite: ^2.3.0` - SQLite database
- `mobile_scanner: ^3.5.6` - QR scanning
- `qr_flutter: ^4.1.0` - QR generation
- `encrypt: ^5.0.3` - AES encryption

#### UI & Utilities
- `audioplayers: ^6.6.0` - Scan beep sound
- `share_plus: ^10.0.2` - File sharing
- `url_launcher: ^6.3.0` - WhatsApp/Email integration
- `esc_pos_printer: ^4.1.0` - Thermal printing
- `pdf: ^3.8.4` - PDF generation

### State Management & UI Performance Standards (Fine-Grained Reactivity)

**Rule: No business logic or complex calculations allowed in the UI layer. Use Targeted Rebuilds for high performance.**

#### 1. Selective Rebuilding (`buildWhen`)
Every `BlocBuilder` must use the `buildWhen` property to prevent unnecessary UI updates. A widget should only rebuild if the specific data it displays has changed.

```dart
// ✅ GOOD: Selective Rebuild
BlocBuilder<BillingCubit, BillingState>(
  buildWhen: (prev, curr) => curr is BillingUpdated && prev.showProfitLossMode != curr.showProfitLossMode,
  builder: (context, state) => ToggleWidget(active: state.showProfitLossMode),
)
```

#### 2. Atomic UI Components (Component Isolation)
Complex list items or repeating UI blocks must be extracted into separate widgets with their own targeted `BlocBuilder`.

- **Concept**: If Item #5 in a list of 100 updates, only Item #5 should rebuild. Items #1-4 and #6-100 must remain untouched.
- **Implementation**: Use a separate `StatefulWidget` or `StatelessWidget` for list tiles and wrap their content in a `BlocBuilder` with a specific `buildWhen` condition.

#### 3. State Derivation (Computed Properties)
Move all math, filtering, and summary logic from UI to the Cubit.

- **Bad**: `final total = state.cart.fold(...)` inside the `build` method.
- **Good**: `final total = cubit.getSummaryData().total` - UI receives pre-calculated data.

#### 4. Immutability & Predictive Updates
- Always use `Equatable` for states and models.
- Use `copyWith` for state transitions to ensure only the intended properties change.

### Flutter UI Development Guidelines

#### Widget Code Organization
- **Maximum Lines per Widget Class**: Stateful and Stateless widget classes should not exceed 1000 lines of code
- **Large Widget Splitting**: If a widget exceeds 1000 lines, split it into separate widget files
- **Clean Column Structure**: Keep main `Column` widgets clean and readable by extracting complex UI sections into separate methods or widgets

#### Code Structure Best Practices
```dart
// ✅ GOOD: Clean main build method with extracted widgets
class BillingScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildScannerSection(),
          _buildCartSection(),
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildScannerSection() => QrScannerWidget();
  Widget _buildCartSection() => CartListWidget();
  Widget _buildSummarySection() => BillingSummaryWidget();
}

// ❌ AVOID: Monolithic build method
class BillingScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 500+ lines of scanner UI code...
          Container(/* scanner implementation */),
          // 500+ lines of cart UI code...
          ListView(/* cart implementation */),
          // 500+ lines of summary UI code...
          Card(/* summary implementation */),
        ],
      ),
    );
  }
}
```

#### Widget Splitting Strategy
- **Extract Complex Sections**: Move complex UI sections to separate widget files
- **Reusable Components**: Create reusable widgets for common patterns
- **Method Extraction**: Use private methods for complex build logic within the same file
- **File Organization**: Keep related widgets in the same directory with clear naming

#### Performance Considerations
- **Widget Rebuild Optimization**: Use `const` constructors where possible
- **Key Usage**: Provide keys for dynamic lists to maintain state
- **Lazy Loading**: Implement lazy loading for large lists
- **Memory Management**: Dispose controllers and clean up resources properly

### API Interfaces

#### Service Interfaces
```dart
abstract class IScanService {
  Future<ScannedData?> scanAndDecode(String qrCode);
}

abstract class IEncryptionService {
  String encryptData(String data);
  String decryptData(String encryptedData);
}

abstract class ISettingsService {
  Future<String> getStoreSecret();
  Future<void> saveStoreSecret(String secret);
}
```

### Error Handling

#### Scan Errors
- Invalid QR format → JSON parsing fails
- Wrong encryption → Decryption fails
- Invalid signature → Validation fails
- Unknown product → Database lookup fails

#### Business Logic Errors
- Negative quantities → UI validation
- Invalid discounts → Calculation errors
- Database constraints → SQLite errors

### Performance Considerations

#### Database Optimization
- Indexed foreign keys for fast joins
- Batch operations for bulk inserts
- Connection pooling with sqflite

#### UI Performance
- Bloc state management prevents unnecessary rebuilds
- Lazy loading for large product lists
- Efficient list rendering with keys

#### Memory Management
- Stream disposal in cubits
- Image caching for QR codes
- Temporary file cleanup for PDFs

### Security Implementation

#### Data Encryption
- AES encryption for sensitive data
- Base64 encoding for transport
- Fixed encryption key (configurable)

#### Access Control
- PIN protection for settings
- Store-specific QR validation
- Encrypted local storage

### Testing Strategy

#### Unit Tests
- Cubit state transitions
- Service method outputs
- Calculation accuracy
- Validation logic

#### Integration Tests
- Database operations
- QR generation/scanning
- UI interactions

#### Manual Testing
- End-to-end billing flows
- Edge case handling
- Performance validation

### Deployment & Build

#### Build Configuration
```yaml
# Release build
flutter build apk --release

# Debug build
flutter build apk --debug
```

#### Platform Support
- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 11.0+

#### Permissions Required
- Camera (QR scanning)
- Storage (PDF generation)
- Bluetooth (thermal printing)

### Future Technical Enhancements

#### Scalability
- Cloud database integration
- Multi-store architecture
- Real-time synchronization

#### Performance
- Database query optimization
- Image caching improvements
- Background processing

#### Features
- Advanced analytics
- Customer management
- Inventory forecasting
- API integrations