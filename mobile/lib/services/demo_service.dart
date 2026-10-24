/// Provides all demo data when backend is unavailable.
class DemoService {
  static final DemoService _instance = DemoService._();
  factory DemoService() => _instance;
  DemoService._();

  Map<String, dynamic> get userProfile => {
    'preferred_name': 'Demo User',
    'cigarettes_per_day': 15,
    'cigarettes_per_pack': 20,
    'price_per_pack': 250.0,
    'currency': 'INR',
    'age_started_smoking': 18,
    'smoking_duration_years': 6,
    'previous_quit_attempts': 2,
    'current_goal': 'reduce',
    'first_smoke_after_waking': '30_minutes',
  };

  // New users start with no recorded smoking events.
  // Events are added in real time as the user logs them via the app.
  List<Map<String, dynamic>> get smokingEvents => [];

  List<Map<String, dynamic>> get weeklySmokingData {
    // All days start at 0 for a fresh user.
    final data = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      data.add({
        'date': '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'count': 0,
      });
    }
    return data;
  }

  int get todaySmokingCount => 0;

  List<Map<String, dynamic>> get cravingEvents => [
    {'id': 1, 'intensity_before': 8, 'intensity_after': 3, 'trigger_category': 'Stress / Anxiety',
     'feeling': '😰 Stressed', 'intervention_used': 'Breathing Exercise', 'intervention_helped': true,
     'created_at': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String()},
    {'id': 2, 'intensity_before': 6, 'intensity_after': 4, 'trigger_category': 'Boredom',
     'feeling': '🥱 Bored', 'intervention_used': '5-Minute Walk', 'intervention_helped': true,
     'created_at': DateTime.now().subtract(const Duration(days: 1, hours: 5)).toIso8601String()},
    {'id': 3, 'intensity_before': 9, 'intensity_after': null, 'trigger_category': 'Social Pressure',
     'feeling': '😟 Anxious', 'intervention_used': null, 'intervention_helped': null,
     'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
  ];

  List<Map<String, dynamic>> get riskZones => [
    {
      'id': 1,
      'name': 'Office Smoking Area',
      'latitude': 28.6139,
      'longitude': 77.2090,
      'radius_meters': 100,
      'risk_level': 'high',
      'trigger_reason': 'Smoke breaks with colleagues during work stress',
      'is_user_confirmed': true,
      'is_active': true,
      'cooldown_minutes': 60,
      'smoking_events_count': 14,
      'craving_events_count': 8,
      'last_event_time': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'explanation': 'High risk confirmed: 14 smoking episodes and 8 intense cravings recorded here.',
      'reminders_enabled': true,
    },
    {
      'id': 2,
      'name': 'Tea Stall Near Home',
      'latitude': 28.6200,
      'longitude': 77.2150,
      'radius_meters': 75,
      'risk_level': 'medium',
      'trigger_reason': 'Morning tea and cigarette habit',
      'is_user_confirmed': true,
      'is_active': true,
      'cooldown_minutes': 90,
      'smoking_events_count': 6,
      'craving_events_count': 4,
      'last_event_time': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'explanation': 'Medium risk confirmed: Habitual association with morning tea breaks.',
      'reminders_enabled': true,
    },
    {
      'id': 3,
      'name': 'Bus Stop Junction',
      'latitude': 28.6180,
      'longitude': 77.2120,
      'radius_meters': 50,
      'risk_level': 'low',
      'trigger_reason': 'Waiting and boredom trigger urge to smoke',
      'is_user_confirmed': false,
      'is_active': true,
      'cooldown_minutes': 120,
      'smoking_events_count': 3,
      'craving_events_count': 2,
      'last_event_time': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'explanation': 'Suggested trigger: You recorded 3 smoking episodes and 2 cravings near this location while waiting.',
      'reminders_enabled': false,
    },
  ];

  List<Map<String, dynamic>> get interventions => [
    {'id': 1, 'name': 'Breathing Exercise', 'category': 'breathing',
     'description': 'A simple deep breathing exercise to calm your body and mind',
     'instructions': 'Breathe in for 4, hold for 4, out for 6. Repeat 4-5 times.',
     'duration_minutes': 3},
    {'id': 2, 'name': 'Grounding Exercise', 'category': 'grounding',
     'description': '5-4-3-2-1 sensory grounding technique',
     'instructions': '5 things you see, 4 you touch, 3 you hear, 2 you smell, 1 you taste.',
     'duration_minutes': 3},
    {'id': 3, 'name': 'Drink Water', 'category': 'physical',
     'description': 'Have a glass of cold water slowly',
     'instructions': 'Pour cold water. Drink slowly, noticing each sip.',
     'duration_minutes': 2},
    {'id': 4, 'name': '5-Minute Walk', 'category': 'activity',
     'description': 'Take a short walk to change your environment',
     'instructions': 'Step outside for 5 minutes. Focus on surroundings.',
     'duration_minutes': 5},
    {'id': 5, 'name': 'Delay 5 Minutes', 'category': 'delay',
     'description': 'Wait 5 minutes before deciding',
     'instructions': 'Set a timer. Most cravings pass within 5–10 minutes.',
     'duration_minutes': 5},
  ];

  Map<String, dynamic> get recommendedIntervention => {
    'intervention': interventions[0],
    'reason': 'This breathing exercise is suggested because you previously rated it helpful during stressful moments.',
    'score': 0.85,
  };

  Map<String, dynamic> get savingsData => {
    'daily_savings': 0.0,
    'weekly_savings': 0.0,
    'monthly_savings': 0.0,
    'total_savings': 0.0,
    'yearly_projection': 0.0,
    'cigarettes_avoided': 0,
    'baseline_daily_cost': 187.50,
    'current_daily_cost': 0.0,
    'currency': 'INR',
  };

  List<Map<String, dynamic>> get savingsGoals => [
    {'id': 1, 'title': 'New Headphones', 'target_amount': 3000.0,
     'current_amount': 0.0, 'icon': 'headphones', 'is_completed': false},
    {'id': 2, 'title': 'Weekend Trip', 'target_amount': 10000.0,
     'current_amount': 0.0, 'icon': 'travel', 'is_completed': false},
  ];

  List<Map<String, dynamic>> get milestones => [
    {'title': 'First Step', 'description': 'Started tracking your smoking', 'achieved': false, 'icon': 'star'},
    {'title': 'First Victory', 'description': 'Resisted your first craving', 'achieved': false, 'icon': 'trophy'},
    {'title': 'Getting Stronger', 'description': 'Resisted 5 cravings', 'achieved': false, 'icon': 'muscle'},
    {'title': 'Double Digits', 'description': 'Resist 10 cravings', 'achieved': false, 'icon': 'fire'},
    {'title': 'Quarter Century', 'description': 'Resist 25 cravings', 'achieved': false, 'icon': 'medal'},
  ];

  Map<String, dynamic> get dailySummary => {
    'date': DateTime.now().toIso8601String().split('T')[0],
    'cigarettes_smoked': 0,
    'cravings_count': 0,
    'cravings_resisted': 0,
    'avg_craving_intensity': 0.0,
  };

  // No historical triggers for a fresh user.
  List<Map<String, dynamic>> get topTriggers => [];

  List<Map<String, dynamic>> get chatMessages => [
    {'id': 1, 'role': 'assistant', 'content':
      "Welcome to CraveCoach! 👋 I'm here to support you on your journey. Whether you're dealing with a craving, want to reflect on your progress, or just need someone to talk to — I'm here.\n\nWhat's on your mind?",
     'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()},
  ];

  List<Map<String, dynamic>> get motivationalMedia => [
    {'id': 1, 'media_type': 'text', 'title': 'My Promise',
     'content_text': 'I am choosing a healthier life for myself and my family.',
     'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
    {'id': 2, 'media_type': 'text', 'title': 'Why I Started',
     'content_text': 'Because I want to breathe freely and run without stopping.',
     'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
  ];

  List<Map<String, dynamic>> get trustedContacts => [
    {'id': 1, 'contact_name': 'Mom', 'contact_method': 'sms', 'contact_value': '+91XXXXXXXXXX',
     'support_type': 'encouragement', 'is_active': true,
     'message_template': "I'm having a difficult moment and could use some encouragement."},
  ];

  String getFallbackChatResponse(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('crav') || msg.contains('urge') || msg.contains('want to smoke')) {
      return "I hear you — cravings can feel overwhelming, but they usually pass within 5-10 minutes. Let's try something together:\n\n🫁 **Breathing exercise**: Breathe in slowly for 4 counts, hold for 4, then breathe out for 6. Repeat 3-4 times.\n\nWhat triggered this craving?";
    } else if (msg.contains('smoked') || msg.contains('lapse') || msg.contains('gave in')) {
      return "Thank you for being honest — it takes real courage. One cigarette doesn't erase your progress. 🌱\n\nWhat was happening right before? Understanding the trigger helps us prepare better next time.\n\nYour journey isn't over. Most people who successfully quit have had setbacks along the way.";
    } else if (msg.contains('stress') || msg.contains('anxious')) {
      return "Stress is one of the most common triggers. Try:\n- 🫁 Box breathing (4-4-4-4)\n- 💧 Splash cold water on your face\n- 🚶 Take a 5-minute walk\n- ✍️ Write down what's stressing you\n\nWhich one feels doable right now?";
    } else if (msg.contains('progress') || msg.contains('how am i')) {
      return "Let's celebrate how far you've come! 🎉 You've been tracking for several days, and every insight matters.\n\nRemember: progress isn't always linear. Some days are harder, and that's completely normal.\n\nWhat's one thing you're proud of?";
    } else if (msg.contains('money') || msg.contains('save')) {
      return "Money saved from reducing smoking is real savings! 💰 Your current trajectory shows meaningful financial progress.\n\nWould you like to set a specific savings goal to stay motivated?";
    }
    return "I'm here to help! You can tell me:\n- 'I'm having a craving' for immediate support\n- 'I smoked' without judgment\n- 'How am I doing?' for progress\n- 'Help me plan' for tomorrow\n\nWhat would be most helpful right now? 💙\n\n_ℹ️ This is a pre-written response. Live AI is not currently configured._";
  }
}



