class CallEndpoints {
  const CallEndpoints._();

  // مطابق لـ backend repo: naofalBj/wareed (routes/api.php)
  static String callDetails(int callId) => '/calls/$callId';
  static const String respond = '/respond-to-call';
  static const String cancelAttendance = '/cancel-attendance';
}
