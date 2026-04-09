class CallEndpoints {
  const CallEndpoints._();

  // مطابق لـ backend repo: naofalBj/wareed (routes/api.php)
  static String callDetails(int callId) => '/calls/$callId';
  static String callTracking(int callId) => '/calls/$callId/tracking';
  static const String respond = '/respond-to-call';
  static const String cancelAttendance = '/cancel-attendance';
  static const String verifyArrival = '/verify-arrival';
  static const String activeCall = '/user/active-call';
}
