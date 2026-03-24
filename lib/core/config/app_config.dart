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
    defaultValue: 'http://187.124.98.120:8080/ride-mate',
  );

  // ─── PayHere Configuration ───────────────────────────────────────

  /// PayHere Merchant ID (from PayHere dashboard).
  /// Pass via: --dart-define=PAYHERE_MERCHANT_ID=1xxxxxx
  static const String _payhereMerchantId = String.fromEnvironment(
    'PAYHERE_MERCHANT_ID',
    defaultValue: '1234563',
  );

  /// PayHere Merchant Secret (generated in PayHere dashboard for your App ID).
  /// Pass via: --dart-define=PAYHERE_MERCHANT_SECRET=xxxxxxxxxxxx
  static const String _payhereMerchantSecret = String.fromEnvironment(
    'PAYHERE_MERCHANT_SECRET',
    defaultValue: 'MjAxNjExODM1OTE5ODYwMzkzNzMzMjcwMTk5OTM2MTY1MjEyNjY4OQ==',
  );

  /// Whether to use PayHere sandbox (true) or production (false).
  /// Pass via: --dart-define=PAYHERE_SANDBOX=true
  static const String _payhereSandbox = String.fromEnvironment(
    'PAYHERE_SANDBOX',
    defaultValue: 'true',
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

  // ─── PayHere Public API ──────────────────────────────────────────

  /// PayHere Merchant ID.
  static String get payhereMerchantId => _payhereMerchantId;

  /// PayHere Merchant Secret (used by the SDK to generate hash client-side).
  static String get payhereMerchantSecret => _payhereMerchantSecret;

  /// Whether PayHere is in sandbox mode.
  static bool get payhereSandbox => _payhereSandbox.toLowerCase() == 'true';
}

