import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/SupabaseConfig.dart';
import '../models/report.dart';

class ReportService {
  final _client = SupabaseConfig.client;

  // Récupérer tous les rapports
  Future<List<Report>> getReports() async {
    try {
      print('Envoi de la requête à Supabase'); // Ajout de log pour le débogage
      final response = await _client
          .from('reports')
          .select('*, users(username), events(title)')
          .order('created_at', ascending: false);
      
      print('Réponse de Supabase: $response'); // Ajout de log pour le débogage
      
      return response.map<Report>((data) => Report.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  // Créer un nouveau rapport
  Future<String?> createReport({
    required String eventId,
    required String userId,
    required String reason,
  }) async {
    try {
      final response = await _client
          .from('reports')
          .insert({
            'event_id': eventId,
            'user_id': userId,
            'reason': reason,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating report: $e');
      return null;
    }
  }

  // Supprimer un rapport
  Future<bool> deleteReport(String reportId) async {
    try {
      await _client
          .from('reports')
          .delete()
          .eq('id', reportId);
      return true;
    } catch (e) {
      print('Error deleting report: $e');
      return false;
    }
  }

  // Mettre à jour le statut d'un rapport
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      await _client
          .from('reports')
          .update({'status': status})
          .eq('id', reportId);
      return true;
    } catch (e) {
      print('Error updating report status: $e');
      return false;
    }
  }
}