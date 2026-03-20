/// Centralised environment configuration.
///
/// Values are injected at **build time** via `--dart-define` flags.
///
/// ```
/// # Local (default)
/// flutter run
///
/// # Production
/// flutter build apk --dart-define=ENV=prod --dart-define=BASE_URL=https://api.example.com/ride-mate
/// ```
///
/// On **Codemagic** add these as environment variables:
///   ENV      = prod
///   BASE_URL = https://your-production-domain.com/ride-mate
///
/// Then in the build command use:
///   flutter build apk --dart-define=ENV=$ENV --dart-define=BASE_URL=$BASE_URL
class AppConfig {
  AppConfig._();

  // ─── Compile-time constants from --dart-define ────────────────────

  static const String _env = String.fromEnvironment(
    'ENV',
    defaultValue: 'local',
  );

  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080/ride-mate',
  );

  // ─── Public API ──────────────────────────────────────────────────

  /// Current environment name: `local` | `prod`.
  static String get environment => _env;

  /// Whether the app is running in production mode.
  static bool get isProduction => _env == 'prod';

  /// Whether the app is running in local / development mode.
  static bool get isLocal => _env == 'local';

  /// The base URL for all API calls.
  ///
  /// * **local** → `http://localhost:8080/ride-mate`  (default)
  /// * **prod**  → whatever is passed via `--dart-define=BASE_URL=…`
  static String get baseUrl => _baseUrl;
}

