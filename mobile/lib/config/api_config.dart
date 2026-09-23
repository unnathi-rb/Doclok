/// Central place to point the app at your FastAPI backend.
///
/// - Android EMULATOR -> 10.0.2.2 maps to your computer's localhost.
/// - Physical PHONE   -> use your computer's LAN IP.
/// - Deployed backend  -> use its real https:// URL once hosted.
class ApiConfig {
  static const String baseUrl = 'https://doclok.onrender.com';

  // Auth
  static const String signup = '$baseUrl/auth/signup';
  static const String loginPassword = '$baseUrl/auth/login/password';
  static const String resendOtp = '$baseUrl/auth/login/resend-otp';
  static const String verifyOtp = '$baseUrl/auth/login/verify-otp';
  static const String verifyPin = '$baseUrl/auth/login/verify-pin';

  // Profile
  static const String profile = '$baseUrl/profile';

  // Folders
  static const String folders = '$baseUrl/folders';

  // Account
  static const String account = '$baseUrl/account';
}