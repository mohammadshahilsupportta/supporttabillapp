# Supportta Bill Book - Flutter Mobile App

A comprehensive Flutter mobile application for **Supportta Bill Book** - a multi-tenant, multi-branch SaaS billing and stock management system.

## 🏗️ Architecture

This app follows **Clean MVVM Architecture** with:
- **GetX** for state management and dependency injection
- **Supabase** for backend (PostgreSQL database + Authentication)
- **Clean Architecture** principles with separation of concerns

### Folder Structure

```
lib/
├── core/
│   ├── config/               # App configuration
│   │   └── app_config.dart
│   ├── services/             # Core services
│   │   ├── supabase_service.dart
│   │   └── storage_service.dart
│   ├── theme/               # App theming
│   │   └── app_theme.dart
│   └── routes/              # Navigation routes
│       └── app_routes.dart
├── data/
│   ├── models/              # Data models
│   │   ├── user_model.dart
│   │   ├── tenant_model.dart
│   │   ├── product_model.dart
│   │   ├── stock_model.dart
│   │   ├── bill_model.dart
│   │   └── purchase_model.dart
│   └── datasources/         # Data layer (Repository pattern)
│       ├── auth_datasource.dart
│       ├── product_datasource.dart
│       ├── stock_datasource.dart
│       └── billing_datasource.dart
├── presentation/
│   ├── controllers/         # ViewModels (GetX Controllers)
│   │   └── auth_controller.dart
│   ├── views/              # UI Screens
│   │   ├── auth/
│   │   │   ├── splash_screen.dart
│   │   │   └── login_screen.dart
│   │   ├── branch/
│   │   │   ├── dashboard/
│   │   │   └── billing/
│   │   ├── owner/
│   │   └── superadmin/
│   └── widgets/            # Reusable widgets
└── main.dart               # App entry point
```

## 🚀 Features

### Core Modules
1. **Authentication & Authorization**
   - Role-based access control (Superadmin, Tenant Owner, Branch Admin, Branch Staff)
   - Secure login with Supabase Auth
   - Multi-tenant isolation

2. **Stock Management** ⭐ Priority Module
   - Real-time stock tracking
   - Stock ledger with complete audit trail
   - Stock In/Out/Adjust/Transfer operations
   - Serial number tracking for individual items
   - Low stock alerts

3. **POS Billing System**
   - Fast product search and selection
   - Real-time cart management
   - GST calculation (inclusive/exclusive)
   - Multiple payment modes (Cash, Card, UPI, Credit)
   - Invoice generation
   - Bill printing (A4 + Thermal)
   - Automatic stock deduction

4. **Product Management**
   - Product CRUD operations
   - Categories and brands
   - SKU management
   - Price management
   - GST configuration

5. **Purchase Management**
   - Purchase entry
   - Supplier management
   - Automatic stock updates

6. **Reports & Analytics**
   - Sales reports
   - Product-wise sales analysis
   - Stock reports
   - Branch-wise analytics
   - Profit tracking

7. **Expense Tracking**
   - Expense categories
   - Receipt management
   - Vendor tracking

## 📱 User Roles & Screens

### Superadmin (6 screens)
- Dashboard with global stats
- Tenant management (List, Create, Edit)
- Global reports
- System settings

### Tenant Owner (8 screens)
- Dashboard with tenant stats
- Branch management (List, Create, Edit)
- Product management (List, Create, Edit, Categories, Brands)
- User management (List, Create, Edit)

### Branch Admin/Staff (14 screens)
- Dashboard with branch stats
- Stock management (List, Ledger, In, Out, Adjust, Transfer)
- POS Billing screen
- Bills list and detail view
- Purchase management (Entry, List)
- Sales reports
- Product sales report
- Expense management

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter |
| **Language** | Dart |
| **State Management** | GetX |
| **Backend** | Supabase (PostgreSQL) |
| **Authentication** | Supabase Auth |
| **Local Storage** | GetStorage |
| **HTTP Client** | Dio |
| **PDF Generation** | pdf, printing packages |
| **QR Codes** | qr_flutter |
| **Charts** | fl_chart |
| **Fonts** | Google Fonts (Inter) |

## 📦 Setup Instructions

### Prerequisites
- Flutter SDK (^3.10.4)
- Dart SDK (^3.10.4)
- Android Studio / VS Code
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   cd c:/Users/moham/OneDrive/Desktop/flutter_supportta/supporttabill
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project
   - Run the database migrations from the web app repository
   - Update `lib/core/config/app_config.dart`:
     ```dart
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🗄️ Database Schema

The app uses the same Supabase database as the web app with tables:

- `users` - User profiles with roles
- `tenants` - Tenant (shop) information
- `branches` - Branch information per tenant
- `products` - Product catalog
- `categories` - Product categories
- `brands` - Product brands
- `current_stock` - Current stock levels (denormalized)
- `stock_ledger` - Complete stock movement audit trail
- `product_serial_numbers` - Serial number tracking
- `bills` - Billing records
- `bill_items` - Bill line items
- `purchases` - Purchase records
- `purchase_items` - Purchase line items
- `customers` - Customer information
- `expenses` - Expense tracking
- `payment_transactions` - Payment tracking

All tables have Row Level Security (RLS) policies for multi-tenant data isolation.

## 🎨 Design System

- **Color Scheme**: Modern blue primary color with semantic colors (success green, warning orange, error red)
- **Typography**: Google Fonts Inter for clean, professional look
- **Components**: Material Design 3 with custom styling
- **Dark Mode**: Full support for light and dark themes
- **Animations**: Smooth transitions and micro-interactions

## 🔐 Security Features

- Row Level Security (RLS) at database level
- Role-based access control in app
- Tenant and branch isolation
- Secure authentication with Supabase
- Local storage encryption with GetStorage

## 📖 Development Guide

### Adding a New Feature

1. **Create Model** in `lib/data/models/`
2. **Create Data Source** in `lib/data/datasources/`
3. **Create Controller** in `lib/presentation/controllers/`
4. **Create View** in `lib/presentation/views/`
5. **Add Route** in `lib/core/routes/app_routes.dart`
6. **Update Permissions** in `AuthController`

### Example: Adding Product Search

```dart
// 1. Data Source Method
Future<List<Product>> searchProducts(String query) async {
  final data = await _supabase.from('products')
    .select()
    .ilike('name', '%$query%')
    .limit(20);
  return (data as List).map((e) => Product.fromJson(e)).toList();
}

// 2. Controller Method
final searchResults = <Product>[].obs;
void searchProducts(String query) async {
  isLoading.value = true;
  searchResults.value = await _dataSource.searchProducts(query);
  isLoading.value = false;
}

// 3. UI Widget
Obx(() => ListView.builder(
  itemCount: controller.searchResults.length,
  itemBuilder: (context, index) {
    final product = controller.searchResults[index];
    return ProductTile(product: product);
  },
))
```

## 🧪 Testing

### Demo Credentials
```
Superadmin: superadmin@example.com / password123
Tenant Owner: owner@example.com / password123
Branch Admin: admin@example.com / password123
Branch Staff: staff@example.com / password123
```

## 📝 TODO

- [ ] Complete Stock Management UI
- [ ] Complete POS Billing UI with cart
- [ ] Product search with barcode scanner
- [ ] PDF invoice generation
- [ ] Thermal printer support
- [ ] Reports with charts
- [ ] Expense management UI
- [ ] Customer management UI
- [ ] Settings screen
- [ ] Profile management
- [ ] Offline mode support
- [ ] Push notifications

## 🤝 Contributing

This is a private project. For questions or support, contact the development team.

## 📄 License

Private - All rights reserved

---

**Built with ❤️ using Flutter & Supabase**
