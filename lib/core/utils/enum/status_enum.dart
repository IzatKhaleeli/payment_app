enum Status {
  pending,
  rejected,
  completed,
  approved,
}

extension StatusExtension on Status {
  String get value {
    switch (this) {
      case Status.pending:
        return 'Pending';
      case Status.rejected:
        return 'Rejected';
      case Status.completed:
        return 'Completed';
      case Status.approved:
        return 'Approved';
    }
  }

  static Status? fromString(String? status) {
    switch (status) {
      case 'Pending':
        return Status.pending;
      case 'Rejected':
        return Status.rejected;
      case 'Completed':
        return Status.completed;
      case 'Approved':
        return Status.approved;
      default:
        return null;
    }
  }
}
