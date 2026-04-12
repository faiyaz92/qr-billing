# QR-Based Billing App

A Flutter application for local QR-based billing system using SQLite. This app allows users to manage products, generate QR codes for products, scan QR codes to add products to bills, and track daily sales with profit calculations.

## Documentation Structure

This project has organized documentation for better maintainability:

- **[Business Requirements Document (BRD)](docs/BRD.md)**: Complete business requirements, features, user journeys, and success metrics
- **[Technical Documentation](docs/Technical_Documentation.md)**: Detailed technical implementation, architecture, database schema, and API specifications

## Features

- **Product Management**: Add products with QR code generation
- **QR Scanning**: Continuous scanning for billing with automatic quantity management
- **Billing System**: Cart management with discounts, tax calculations, and profit tracking
- **Security**: AES encryption for sensitive data and store-specific QR validation
- **Reporting**: Daily sales tracking with profit/loss analysis
- **Sharing & Printing**: PDF generation, WhatsApp sharing, and thermal printing support

## Quick Start

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

3. **Initial Setup**:
   - Set your store secret in Settings (PIN protected)
   - Add products via the Add Product screen
   - Start billing by scanning QR codes

## Key Workflows

### Adding Products
1. Navigate to Add Product screen
2. Fill product details (name, brand, prices, tax)
3. Generate QR code (automatically encrypts sensitive data)
4. QR contains both public data and encrypted sensitive information

### Billing Process
1. Start Billing from home screen
2. Scan product QR codes continuously
3. Adjust quantities and apply discounts
4. Review calculations (tax, profit/loss highlighting)
5. Share via WhatsApp or print receipt

### Security Features
- Store-specific QR validation
- AES encryption for sensitive data
- PIN-protected settings
- Automatic loss detection and highlighting

## Dependencies

Core dependencies include:
- `flutter_bloc`: State management
- `sqflite`: SQLite database
- `mobile_scanner`: QR scanning
- `qr_flutter`: QR generation
- `encrypt`: AES encryption

For complete dependency list and technical details, see [Technical Documentation](docs/Technical_Documentation.md).

## Database

Uses SQLite with three main tables:
- `products`: Product catalog with QR data
- `bills`: Bill headers with totals
- `bill_items`: Bill line items with quantities and discounts

For detailed schema and relationships, see [Technical Documentation](docs/Technical_Documentation.md).

## Business Requirements

For complete business requirements, user journeys, success metrics, and feature specifications, see [Business Requirements Document](docs/BRD.md).
