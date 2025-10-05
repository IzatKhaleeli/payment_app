enum CancellationStatus {
  cancelPending,
  submitedToCancel,
  rejected,
  completed,
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
      case CancellationStatus.completed:
        return 'completed';
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
      case 'completed':
        return CancellationStatus.completed;
      default:
        return null;
    }
  }
}
