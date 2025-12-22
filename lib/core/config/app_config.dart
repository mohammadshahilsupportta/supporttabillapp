// Core Configuration Constants
class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://foinykpziaunhwmytmhr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvaW55a3B6aWF1bmh3bXl0bWhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxOTU2OTcsImV4cCI6MjA4MDc3MTY5N30.6NCKWxiN6sUs3HgpLoqa1NMAHOaO4AFLrY5WQHztPlQ';

  // App Information
  static const String appName = 'Supportta Bill Book';
  static const String appVersion = '1.0.0';

  // API Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyTenantId = 'tenant_id';
  static const String keyBranchId = 'branch_id';
  static const String keySelectedBranchId = 'selected_branch_id'; // For tenant owner branch switching
  static const String keyThemeMode = 'theme_mode';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // GST Rates
  static const List<double> gstRates = [0, 5, 12, 18, 28];

  // Payment Modes
  static const List<String> paymentModes = ['cash', 'card', 'upi', 'credit'];

  // Stock Transaction Types
  static const List<String> stockTransactionTypes = [
    'stock_in',
    'stock_out',
    'adjustment',
    'transfer_in',
    'transfer_out',
    'billing',
  ];
}
