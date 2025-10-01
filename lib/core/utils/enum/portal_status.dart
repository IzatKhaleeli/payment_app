enum PortalStatus {
  pending,
  rejected,
  completed,
}

extension PortalStatusExtension on PortalStatus {
  String get value {
    switch (this) {
      case PortalStatus.pending:
        return 'Pending';
      case PortalStatus.rejected:
        return 'Rejected';
      case PortalStatus.completed:
        return 'Completed';
    }
  }

  static PortalStatus? fromString(String? status) {
    switch (status) {
      case 'Pending':
        return PortalStatus.pending;
      case 'Rejected':
        return PortalStatus.rejected;
      case 'Completed':
        return PortalStatus.completed;
      default:
        return null;
    }
  }
}
