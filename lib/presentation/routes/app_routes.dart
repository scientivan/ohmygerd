class AppRoutes {
  //=========== Intro pages routes ===========
  static const splashscreen = '/splashscreen';
  static const onboarding1 = '/onboarding1';
  static const onboarding2 = '/onboarding2';
  static const onboarding3 = '/onboarding3';
  static const onboarding4 = '/onboarding4';
  static const onboarding = '/onboarding';

  //=========== auth pages routes ===========
  static const register = '/register';
  static const biodata = '/biodata';
  static const preference = '/preference';
  static const connections = '/connections';
  static const login = '/login';

  //=========== main pages routes ===========
  static const home = '/home';
  static const calendar = '/calendar';
  static const chatbot = '/chatbot';
  static const profile = '/profile';
  static const photo = '/photo';

  //=========== settings page routes ===========
  static const settings = '/settings';
  static const profileSettings = 'profile';
  static const preferenceSettings = 'preference';
  static const connectionsSettings = 'connections';
  // helper buat settings
  static String getSettingsPath(String subRoute) => '$settings/$subRoute';

  //=========== pages-pages lainnya routes ===========
  static const notification = '/notification';
  static const foodComponent = '/foodcomponent';
  static const foodResult = '/food-result';
  static const mealDetails = '/meal-details';
  static const achievement = '/achievement';
  static const mealScan = '/mealScan';
  static const mealResult = '/mealResult';
}
