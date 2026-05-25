class AppConstants {
  AppConstants._();

  static const String appName = 'NexQ';
  static const String appTagline = 'Skip the wait, join the queue';

  static const int shopsPageSize = 15;
  static const int notificationsPageSize = 20;
  static const int reviewsPageSize = 10;

  static const String onboardingSeenKey = 'onboarding_seen';
  static const String selectedCityKey = 'selected_city';
  static const String selectedAreaKey = 'selected_area';
  static const String themeModeKey = 'theme_mode';

  static const List<String> defaultCities = [
  'Mumbai', 'Palghar', 'Boisar', 'Thane', 'Pune', 'Delhi', 'Bangalore',
];

static const Map<String, List<String>> cityAreas = {
  'Mumbai': ['All Areas', 'Andheri', 'Bandra', 'Dadar', 'Borivali', 'Kurla'],
  'Palghar': ['All Areas', 'Palghar East', 'Palghar West', 'Manor', 'Boisar', 'Kelwa'],
  'Boisar': ['All Areas', 'TAPS Colony', 'Boisar East', 'Boisar West', 'Tarapur'],
  'Thane': ['All Areas', 'Thane West', 'Thane East', 'Kopri', 'Naupada'],
  'Pune': ['All Areas', 'Kothrud', 'Shivajinagar', 'Hadapsar', 'Aundh'],
  'Delhi': ['All Areas', 'Connaught Place', 'Lajpat Nagar', 'Rohini', 'Dwarka'],
  'Bangalore': ['All Areas', 'Koramangala', 'Indiranagar', 'Whitefield', 'HSR Layout'],
};
}
