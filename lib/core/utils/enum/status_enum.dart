enum Status {
  confirmed,
  synced,
  accepted,
  rejected,
}

extension StatusExtension on Status {
  String get value {
    switch (this) {
      case Status.confirmed:
        return 'Confirmed';
      case Status.synced:
        return 'Synced';
      case Status.accepted:
        return 'Accepted';
      case Status.rejected:
        return 'Rejected';
    }
  }

  static Status? fromString(String? status) {
    switch (status) {
      case 'Confirmed':
        return Status.confirmed;
      case 'Synced':
        return Status.synced;
      case 'Accepted':
        return Status.accepted;
      case 'Rejected':
        return Status.rejected;
      default:
        return null;
    }
  }
}
