class AppConstants {
  static const String appName = 'CraveGuard';
  static const String apiBaseUrl = 'http://10.0.2.2:8001/api/v1';
  static const String apiBaseUrlDesktop = 'http://localhost:8001/api/v1';
  static const String tokenKey = 'auth_token';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String demoModeKey = 'demo_mode';
  static const String defaultCurrency = '₹';
  static const int defaultCigsPerPack = 20;
  static const double defaultPricePerPack = 250.0;

  static const List<String> triggerOptions = [
    'Stress / Anxiety',
    'Sadness / Loneliness',
    'Anger / Frustration',
    'Boredom',
    'Habit / Routine',
    'After Meals',
    'With Tea / Coffee',
    'Work / Study',
    'Social Pressure',
    'While Travelling',
    'Difficulty Concentrating',
    'Difficulty Relaxing',
    'Alcohol',
    'Nicotine Withdrawal',
  ];

  static const List<String> moodOptions = [
    '😊 Happy',
    '😐 Neutral',
    '😟 Anxious',
    '😢 Sad',
    '😠 Angry',
    '😰 Stressed',
    '😴 Tired',
    '🥱 Bored',
  ];

  static const List<String> quitReasonOptions = [
    'Family & Loved Ones',
    'Better Health',
    'Better Fitness',
    'Saving Money',
    'Better Breathing',
    'Personal Confidence',
    'Freedom from Dependence',
    'Healthcare Advice',
  ];

  static const List<String> suggestedPrompts = [
    "I'm craving a cigarette",
    "Help me get through 5 minutes",
    "I smoked again. What now?",
    "Why do I smoke when stressed?",
    "Show my progress",
    "Help me plan tomorrow",
    "Suggest something instead of smoking",
    "I'm around friends who smoke",
  ];
}
