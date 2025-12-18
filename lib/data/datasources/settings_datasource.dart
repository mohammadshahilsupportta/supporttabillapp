import '../../core/services/supabase_service.dart';

class SettingsDataSource {
  final SupabaseService _supabase = SupabaseService.instance;

  // Get settings for tenant
  Future<Map<String, dynamic>> getSettings(String tenantId) async {
    try {
      final data = await _supabase
          .from('settings')
          .select()
          .eq('tenant_id', tenantId)
          .single();

      return data as Map<String, dynamic>;
    } catch (e) {
      // Return default settings if none exist
      return {
        'tenant_id': tenantId,
        'gst_enabled': false,
        'gst_number': null,
        'gst_type': 'exclusive',
        'gst_percentage': 0.0,
        'upi_id': null,
        'bank_account_number': null,
        'bank_name': null,
        'bank_branch': null,
        'bank_ifsc_code': null,
      };
    }
  }
}

