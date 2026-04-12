# QR/Barcode Data Format Tech Doc

This document outlines the simplified data structures and flow for QR/barcode generation, scanning, and decryption in the QR-Based Billing app. QrData is now the same for both generation and scanning.

## 1. Plain Data During Product Addition

When adding a product via the Add Product screen, the form collects plain data, encrypts sensitive parts, and prepares the data map for QR.

## 2. Data Stored on QR/Barcode (Plain JSON String)

The QR/barcode encodes a plain JSON string representing the `QrData` model.

**QrData JSON (compact format for better scannability):**
```json
{
  "es": "base64_encrypted_signature_json",
  "d": {
    "n": "Product Name",
    "b": "Brand Name",
    "t": 5.0,
    "sp": 100.0,
    "op": 120.0,
    "esd": "base64_encrypted_sensitive_json"
  }
}
```

**Field Mapping:**
- `es`: encrypted_signature (Base64 AES-encrypted `QrSignature` JSON)
- `d`: data (Plain map with compact field names)
- `n`: name
- `b`: brand  
- `t`: tax
- `sp`: selling_price
- `op`: original_price
- `esd`: encrypted_sensitive (Base64 AES-encrypted sensitive data JSON)

**Legacy Support:** The system supports both compact and verbose field names for backward compatibility.

### Encryption
- Only `QrSignature` JSON is encrypted to base64; `data` remains plain but contains encrypted sub-fields.

## 3. Data Obtained from QR/Barcode Scan

Scanning returns the plain JSON string. Parsed into `QrData` with `encryptedSignature` and `data`.

## 4. Data Obtained After Decryption

Decryption yields `ScannedData` with decrypted signature and merged data. For type 1, sensitive data is decrypted.

**Decryption Process:**
1. Parse plain JSON to `QrData`.
2. Decrypt `encrypted_signature` to get `QrSignature`.
3. Validate signatures (app and store match).
4. Return `ScannedData` with signature and raw `data` (including `encrypted_sensitive`).

Type-specific decryption (e.g., sensitive data for type 1) is handled in the Cubit using `EncryptionService`.

**Decrypted Data Structure (`ScannedData.data` for type 1):**
```json
{
  "name": "Product Name",
  "brand": "Brand Name",
  "tax": 5.0,
  "selling_price": 100.0,
  "original_price": 120.0,
  "date_of_purchase": "2024-01-01",
  "purchase_price": 80.0
}
```

For other types, data remains as in the QR, with `encrypted_sensitive` if present.

## 5. App-Wide Consistency Rules

- **Generation**: `QrGeneratorService.generateQrData(type, dataMap)` creates QrData, encrypts signature, returns plain JSON string.
- **Encryption**: `EncryptionService` only encrypts/decrypts strings, no logic.
- **Scanning**: `ScanService` decrypts signature, validates, returns raw data. Cubit handles type-specific decryption via `EncryptionService`.
- **Models**: `QrData` and `ScannedData` are identical structures.
- **Extensibility**: Pass any `type` and `data` map; handle decryption logic per type in ScanService.

This ensures simplicity, consistency, and extensibility.</content>
<parameter name="filePath">/Users/faiyaz/Qr-Based Billing/qr_based_billing/docs/data_format.md