enum AppLanguage { en, hi }

/// Localized strings for the example (English + Hindi), grouped by category —
/// the same nested shape the DebugLens Locale inspector groups on.
abstract final class AppStrings {
  static const Map<AppLanguage, Map<String, Map<String, String>>> data = {
    AppLanguage.en: {
      'HOME': {
        'greeting': 'Good morning, Anupam 👋',
        'glance': 'Here is your day at a glance.',
        'recent_activity': 'Recent activity',
        'pending': 'Pending',
        'completed': 'Completed',
      },
      'ACTIVITY': {
        'add': 'Add activity',
        'new': 'New activity',
        'prompt': 'What do you want to do?',
        'mark_done': 'Mark as done',
        'mark_pending': 'Mark as pending',
      },
    },
    AppLanguage.hi: {
      'HOME': {
        'greeting': 'सुप्रभात, अनुपम 👋',
        'glance': 'एक नज़र में आपका दिन।',
        'recent_activity': 'हाल की गतिविधि',
        'pending': 'लंबित',
        'completed': 'पूर्ण',
      },
      'ACTIVITY': {
        'add': 'गतिविधि जोड़ें',
        'new': 'नई गतिविधि',
        'prompt': 'आप क्या करना चाहते हैं?',
        'mark_done': 'पूर्ण चिह्नित करें',
        'mark_pending': 'लंबित चिह्नित करें',
      },
    },
  };

  static String label(AppLanguage lang) => switch (lang) {
    AppLanguage.en => 'English',
    AppLanguage.hi => 'Hindi',
  };
}

/// Typed accessor for the current language's strings.
class L10n {
  const L10n(this.lang);

  final AppLanguage lang;

  String get greeting => _get('HOME', 'greeting');
  String get glance => _get('HOME', 'glance');
  String get recentActivity => _get('HOME', 'recent_activity');
  String get pending => _get('HOME', 'pending');
  String get completed => _get('HOME', 'completed');
  String get addActivity => _get('ACTIVITY', 'add');
  String get newActivity => _get('ACTIVITY', 'new');
  String get activityPrompt => _get('ACTIVITY', 'prompt');
  String get markDone => _get('ACTIVITY', 'mark_done');
  String get markPending => _get('ACTIVITY', 'mark_pending');

  String _get(String category, String key) =>
      AppStrings.data[lang]![category]![key]!;
}
