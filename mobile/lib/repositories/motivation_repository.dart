import '../services/api_service.dart';
import '../services/demo_service.dart';

/// Repository that abstracts motivational media and trusted contacts data access.
/// Returns demo data when [isDemoMode] is true, otherwise calls the real API.
class MotivationRepository {
  final ApiService api;
  final DemoService demo;
  final bool isDemoMode;

  MotivationRepository({
    required this.api,
    required this.demo,
    required this.isDemoMode,
  });

  /// Returns all motivational media entries.
  Future<List<Map<String, dynamic>>> getMotivationalMedia() async {
    if (isDemoMode) {
      return demo.motivationalMedia;
    }
    final resp = await api.get('/motivation/media');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Adds a new motivational media entry.
  Future<void> addMotivation(Map<String, dynamic> media) async {
    if (isDemoMode) {
      return;
    }
    await api.post('/motivation/media', data: media);
  }

  /// Returns the user's trusted contacts.
  Future<List<Map<String, dynamic>>> getTrustedContacts() async {
    if (isDemoMode) {
      return demo.trustedContacts;
    }
    final resp = await api.get('/motivation/trusted-contacts');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Adds a new trusted contact.
  Future<void> addTrustedContact(Map<String, dynamic> contact) async {
    if (isDemoMode) {
      return;
    }
    await api.post('/motivation/trusted-contacts', data: contact);
  }
}
