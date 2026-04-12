# Complete QR Code Pipeline for Product (Type 1)

This document details the end-to-end data flow for generating and scanning a QR code for a product in the QR-Based Billing app. It visualizes data transformation at each stage, from user input to final scanned data.

## 1. User Input (Add Product Form)

**Source**: `AddProductScreen` form fields.

**Data Structure** (Map<String, dynamic> passed to `AddProductCubit.addProduct()`):
```json
{
  "name": "Laptop",
  "brand": "Dell",
  "date_of_purchase": "2024-01-01",
  "purchase_price": 500.0,
  "selling_price": 600.0,
  "original_price": 650.0,
  "tax": 50.0
}
```

- All fields are plain text/numbers from user input.
- No encryption yet.

## 2. Cubit Processing (Encryption of Sensitive Data)

**Location**: `AddProductCubit.addProduct()`.

**Process**:
- Extract sensitive fields: `date_of_purchase`, `purchase_price`.
- Encrypt as JSON: `{"date_of_purchase": "2024-01-01", "purchase_price": 500.0}` → Base64 encrypted string.
- Prepare `qrDataMap` with public + encrypted sensitive.

**Data After Processing** (`qrDataMap`):
```json
{
  "name": "Laptop",
  "brand": "Dell",
  "tax": 50.0,
  "selling_price": 600.0,
  "original_price": 650.0,
  "encrypted_sensitive": "U2FsdGVkX1+...base64_encrypted_sensitive_json..."
}
```

- Public fields: `name`, `brand`, `tax`, `selling_price`, `original_price`.
- Sensitive: Encrypted into `encrypted_sensitive`.

## 3. QR Generation (Signature Addition & Encryption)

**Location**: `QrGeneratorService.generateQrData(1, qrDataMap)`.

**Process**:
- Fetch store secret from settings.
- Create `QrSignature`: `{"as": "QR_BILLING_APP", "ss": "store_secret", "t": 1}` (compact format).
- Encrypt signature JSON → Base64.
- Create `QrData`: `{"es": "base64...", "d": qrDataMap}` (compact format).
- Return plain JSON string.

**Final QR String** (Compact JSON for better scannability):
```json
{
  "es": "U2FsdGVkX1+...base64_encrypted_signature_json...",
  "d": {
    "n": "Laptop",
    "b": "Dell",
    "t": 50.0,
    "sp": 600.0,
    "op": 650.0,
    "esd": "U2FsdGVkX1+...base64_encrypted_sensitive_json..."
  }
}
```

- This string is stored in `Product.qrData` and displayed as QR/barcode.

## 4. QR Display (Visual)

**Location**: `ProductListScreen` or `AddProductScreen` success state.

- QR: Generated from the plain JSON string using `QrImageView`.
- Barcode: Generated from the same string using `BarcodeWidget` (Code128).
- External scan shows the plain JSON (public data visible, encrypted parts hidden).

## 5. Scanning (Initial Parse & Signature Validation)

**Location**: `ScanService.scanAndDecode(qrString)`.

**Process**:
- Parse JSON to `QrData` (supports both compact and verbose formats).
- Decrypt `encrypted_signature` → `QrSignature` (supports both compact and verbose formats).
- Validate: `app_signature` == "QR_BILLING_APP", `store_signature` == current store secret.
- If invalid, return `null`.
- Map compact field names back to full field names for internal use.
- If valid, return `ScannedData(signature: QrSignature, data: mappedDataMap)`.

**Data After Scanning** (`ScannedData.data` - mapped to full field names):
```json
{
  "name": "Laptop",
  "brand": "Dell",
  "tax": 50.0,
  "selling_price": 600.0,
  "original_price": 650.0,
  "encrypted_sensitive": "U2FsdGVkX1+...base64_encrypted_sensitive_json..."
}
```

- Signature is decrypted and validated.
- `data` fields are mapped from compact format (`n`, `b`, `t`, etc.) to full format (`name`, `brand`, `tax`, etc.) for backward compatibility.
- `encrypted_sensitive` remains encrypted.

## 6. Cubit Processing (Type-Specific Decryption)

**Location**: Future `BillingCubit` (e.g., `scanProduct()`).

**Process**:
- Check `ScannedData.signature.type` == 1.
- If yes, decrypt `encrypted_sensitive` → JSON `{"date_of_purchase": "2024-01-01", "purchase_price": 500.0}`.
- Merge into final data: Remove `encrypted_sensitive`, add decrypted fields.

**Final Scanned Data** (`ScannedData.data` - fully decrypted):
```json
{
  "name": "Laptop",
  "brand": "Dell",
  "tax": 50.0,
  "selling_price": 600.0,
  "original_price": 650.0,
  "date_of_purchase": "2024-01-01",
  "purchase_price": 500.0
}
```

- Now ready for billing (add to bill, calculate profit, etc.).

## Reverse Process Summary

- **Generation**: Plain input → Encrypt sensitive → Add encrypted signature → Plain JSON QR.
- **Scanning**: Plain JSON → Decrypt signature (validate) → Raw data → Decrypt sensitive (if type 1) → Full data.

## Key Points

- **Security**: Only signature and sensitive data encrypted; public data readable for quick display.
- **Pipeline**: Form → Cubit (encrypt) → Generator (sign) → QR → Scan (validate) → Cubit (decrypt) → Use.
- **Type Handling**: Type 1 = Product (decrypt sensitive); Other types can have custom logic.
- **Consistency**: All encryption/decryption via `EncryptionService`; signatures via `QrGeneratorService`/`ScanService`.

This ensures secure, traceable data flow with clear visibility at each stage.</content>
<parameter name="filePath">/Users/faiyaz/Qr-Based Billing/qr_based_billing/docs/qr_pipeline.md