enum CancellationStatus {
  cancelPending,
  submitedToCancel,
  rejected,
  accepted,
}

extension CancellationStatusExtension on CancellationStatus {
  String get value {
    switch (this) {
      case CancellationStatus.cancelPending:
        return 'CancelPending';
      case CancellationStatus.submitedToCancel:
        return 'Cancelled';
      case CancellationStatus.rejected:
        return 'rejected';
      case CancellationStatus.accepted:
        return 'accepted';
    }
  }

  static CancellationStatus? fromString(String? status) {
    switch (status) {
      case 'CancelPending':
        return CancellationStatus.cancelPending;
      case 'Cancelled':
        return CancellationStatus.submitedToCancel;
      case 'rejected':
        return CancellationStatus.rejected;
      case 'accepted':
        return CancellationStatus.accepted;
      default:
        return null;
    }
  }
}
