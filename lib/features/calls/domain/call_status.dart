enum CallStatus {
  sent,
  accepted,
  rejected,
  waitingList,
  arrived,
  expired,
  medicalRejection,
  unknown,
}

extension CallStatusX on CallStatus {
  String get apiValue {
    switch (this) {
      case CallStatus.sent:
        return 'sent';
      case CallStatus.accepted:
        return 'accepted';
      case CallStatus.rejected:
        return 'rejected';
      case CallStatus.waitingList:
        return 'waiting_list';
      case CallStatus.arrived:
        return 'arrived';
      case CallStatus.expired:
        return 'expired';
      case CallStatus.medicalRejection:
        return 'medical_rejection';
      case CallStatus.unknown:
        return 'unknown';
    }
  }

  String get labelAr {
    switch (this) {
      case CallStatus.sent:
        return 'تم الإرسال';
      case CallStatus.accepted:
        return 'أنا قادم';
      case CallStatus.rejected:
        return 'اعتذار';
      case CallStatus.waitingList:
        return 'قائمة الانتظار';
      case CallStatus.arrived:
        return 'وصل';
      case CallStatus.expired:
        return 'منتهي';
      case CallStatus.medicalRejection:
        return 'رفض طبي';
      case CallStatus.unknown:
        return 'غير معروف';
    }
  }
}

CallStatus callStatusFromApi(String? value) {
  switch (value) {
    case 'sent':
      return CallStatus.sent;
    case 'accepted':
      return CallStatus.accepted;
    case 'rejected':
      return CallStatus.rejected;
    case 'waiting_list':
      return CallStatus.waitingList;
    case 'arrived':
      return CallStatus.arrived;
    case 'expired':
      return CallStatus.expired;
    case 'medical_rejection':
      return CallStatus.medicalRejection;
    default:
      return CallStatus.unknown;
  }
}
