class CancelReason {
  const CancelReason(this.code, this.label);

  final String code;
  final String label;
}

const List<CancelReason> defaultCancelReasons = [
  CancelReason('traffic', 'ازدحام مروري'),
  CancelReason('health_issue', 'عارض صحي'),
  CancelReason('personal', 'ظرف شخصي'),
  CancelReason('other', 'سبب آخر'),
];
