class Payment {
  String voucherSerialNumber;
  String customerName;
  String? msisdn;
  String? prNumber;
  String paymentMethod;
  double? amount;
  double? amountCheck;
  int? checkNumber;
  String? bankBranch;
  DateTime? dueDateCheck;
  String? currency;
  String? paymentInvoiceFor;
  String status;
  int? id;
  DateTime? transactionDate;
  DateTime? lastUpdatedDate;
  String? cancelReason;
  DateTime? cancellationDate;
  int isDepositChecked;

  Payment({
    this.transactionDate,
    this.lastUpdatedDate,
    this.voucherSerialNumber = '',
    this.id,
    required this.customerName,
    required this.paymentMethod,
    this.msisdn,
    this.prNumber,
    this.amount,
    this.amountCheck,
    this.checkNumber,
    this.bankBranch,
    this.dueDateCheck,
    this.currency,
    this.paymentInvoiceFor,
    required this.status,
    this.cancelReason= '',
    this.cancellationDate,
    required this.isDepositChecked
  })
  {
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      status: map['status'],
      id: map['id'],
      voucherSerialNumber: map['voucherSerialNumber'] ?? ''  ,
      lastUpdatedDate:(map['lastUpdatedDate'] != 'null' && map['lastUpdatedDate'] != ''&&  map['lastUpdatedDate'] != null) ? DateTime.parse(map['lastUpdatedDate']) : null,
      transactionDate:(map['transactionDate'] != 'null' && map['transactionDate'] != '' &&  map['transactionDate'] != null) ? DateTime.parse(map['transactionDate']) : null,
      paymentMethod: map['paymentMethod'],
      customerName: map['customerName'],
      msisdn: (map['msisdn'] !=null && map.containsKey('msisdn'))?map['msisdn']: null,
      prNumber: (map['prNumber'] !=null && map.containsKey('prNumber'))?map['prNumber']: null,
      amount: (map['amount'] !=null && map.containsKey('amount')) ?map['amount']: null,
      amountCheck: (map['amountCheck']!=null && map.containsKey('amountCheck'))?map['amountCheck']: null,
      checkNumber: (map['checkNumber']!=null && map.containsKey('checkNumber'))?map['checkNumber']: null,
      bankBranch: (map['bankBranch']!=null && map.containsKey('bankBranch'))?map['bankBranch']: null,
      dueDateCheck: (map['dueDateCheck'] != 'null' && map['dueDateCheck'] != '') ? DateTime.parse(map['dueDateCheck']) : null,
      currency: (map['currency'] !=null && map.containsKey('currency'))?map['currency']: null,
      paymentInvoiceFor: (map['paymentInvoiceFor'] !=null && map.containsKey('paymentInvoiceFor'))?map['paymentInvoiceFor']: null,
      cancelReason: (map['cancelReason'] != null && map.containsKey('cancelReason')) ? map['cancelReason'] : null,
      cancellationDate:(map['cancellationDate'] != 'null' && map['cancellationDate'] != '' &&  map['cancellationDate'] != null) ? DateTime.parse(map['cancellationDate']) : null,
      isDepositChecked:map['isDepositChecked'],
    );
  }
  // delete vougher serial number duplicate
  Map<String, dynamic> toMap() {
    return {
      'voucherSerialNumber': voucherSerialNumber,
      'customerName': customerName,
      'msisdn': msisdn,
      'prNumber': prNumber,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'amountCheck': amountCheck,
      'checkNumber': checkNumber,
      'bankBranch': bankBranch,
      'dueDateCheck': dueDateCheck?.toIso8601String(),
      'currency': currency,
      'paymentInvoiceFor': paymentInvoiceFor,
      'status': status,
      'id': id,
      'transactionDate': transactionDate?.toIso8601String(),
      'lastUpdatedDate': lastUpdatedDate?.toIso8601String(),
      'cancelReason': cancelReason,
      'cancellationDate': cancellationDate?.toIso8601String(),
      'isDepositChecked': isDepositChecked,
    };
  }

  @override
  String toString() {
    return 'Payment(voucherSerialNumber: $voucherSerialNumber, customerName: $customerName, msisdn: $msisdn, prNumber: $prNumber, paymentMethod: $paymentMethod, amount: $amount, amountCheck: $amountCheck, checkNumber: $checkNumber, bankBranch: $bankBranch, dueDateCheck: $dueDateCheck, currency: $currency, paymentInvoiceFor: $paymentInvoiceFor, status: $status, id: $id, transactionDate: $transactionDate, lastUpdatedDate: $lastUpdatedDate, cancelReason: $cancelReason, cancellationDate: $cancellationDate)';
  }
}
