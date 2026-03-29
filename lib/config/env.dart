/* flutter run --dart-define-from-file=env/.env.dev
 */
class Env {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.dev2.workfloow.app/api/v1',
  );

  static const String someApiKey = String.fromEnvironment(
    'SOME_API_KEY',
    defaultValue: '',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  
}
