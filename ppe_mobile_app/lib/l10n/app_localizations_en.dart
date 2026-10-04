// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PPE SMART';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get submit => 'Submit';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String get clear => 'Clear';

  @override
  String get all => 'All';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get optional => 'optional';

  @override
  String get seeAll => 'See all';

  @override
  String get done => 'Done';

  @override
  String get fieldRequired => 'Required';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get offlineBanner => 'Offline – showing saved data';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoInternet =>
      'Cannot reach the server. Check your connection.';

  @override
  String get errorTimeout => 'The server took too long to respond.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorForbidden => 'You don\'t have permission to do this.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get errorValidation => 'Please check the highlighted fields.';

  @override
  String get errInvalidCredentials => 'Invalid Employee ID or password.';

  @override
  String get errActiveRequestExists =>
      'You already have an open request for this item.';

  @override
  String get errSpecialReasonRequired =>
      'Please give a reason for special approval.';

  @override
  String get errSizeRequired => 'Please select a size for every item.';

  @override
  String get errInsufficientStock => 'Not enough stock.';

  @override
  String get errSerialMismatch =>
      'Scanned serial numbers don\'t match the reserved units.';

  @override
  String get errSerialRequired => 'This item needs one serial number per unit.';

  @override
  String get errSerialExists => 'One or more serial numbers already exist.';

  @override
  String get errQrInvalid => 'QR code is invalid, expired or already used.';

  @override
  String get errQrMismatch => 'This QR code belongs to a different request.';

  @override
  String get errInvalidStatus =>
      'This action isn\'t possible in the current status.';

  @override
  String get errNotApprover => 'You are not the approver for this step.';

  @override
  String get errReasonRequired => 'A reason is required.';

  @override
  String get errNegativeStock =>
      'Stock cannot go below zero or below the reserved quantity.';

  @override
  String get errWrongPassword => 'Current password is incorrect.';

  @override
  String get errAlreadyReturned => 'This item was already returned.';

  @override
  String get errItemInactive => 'This item is no longer available.';

  @override
  String get errDuplicateLine => 'The same item appears twice.';

  @override
  String get errExpiredStock =>
      'Cannot receive stock that has already expired.';

  @override
  String get loginSubtitle => 'Personal protective equipment requisition';

  @override
  String get employeeId => 'Employee ID';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get noAccount => 'New employee? Register';

  @override
  String get registerTitle => 'Register';

  @override
  String get displayName => 'Full name';

  @override
  String get department => 'Department';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get supervisorEmployeeId => 'Supervisor Employee ID';

  @override
  String get selectSupervisor => 'Your supervisor';

  @override
  String get searchSupervisor => 'Tap to choose, or type a name or ID';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordTooShort => 'At least 8 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccount => 'Already registered? Sign in';

  @override
  String get registerNote =>
      'New accounts start with the Worker role. An administrator can change roles later.';

  @override
  String get serverSettings => 'Server settings';

  @override
  String get serverUrl => 'API base URL';

  @override
  String get serverUrlHint => 'e.g. http://192.168.1.10:8000/api/v1';

  @override
  String get resetDefault => 'Reset to default';

  @override
  String get demoAccounts => 'Demo accounts (password ChangeMe123!)';

  @override
  String get unlockTitle => 'App locked';

  @override
  String get unlockSubtitle => 'Verify your identity to continue';

  @override
  String get unlock => 'Unlock';

  @override
  String get biometricReason => 'Unlock PPE Management';

  @override
  String get biometricUnavailable =>
      'Biometric authentication is not available on this device.';

  @override
  String get navHome => 'Home';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navRequests => 'Requests';

  @override
  String get navApprovals => 'Approvals';

  @override
  String get navStore => 'Store';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navProfile => 'Profile';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get roleWorker => 'Worker';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleStoreKeeper => 'Store keeper';

  @override
  String get roleEhs => 'EHS officer';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get quickActions => 'Quick actions';

  @override
  String get actionNewRequest => 'New request';

  @override
  String get actionMyPpe => 'My PPE';

  @override
  String get actionScanQr => 'Scan QR';

  @override
  String get actionReceiveStock => 'Receive stock';

  @override
  String get actionPurchaseRequests => 'Purchase requests';

  @override
  String get actionAuditLog => 'Audit log';

  @override
  String get actionUsers => 'Users';

  @override
  String get actionAnalytics => 'Analytics';

  @override
  String get actionManageCatalog => 'Manage catalog';

  @override
  String get recentRequests => 'Recent requests';

  @override
  String get kpiMyOpen => 'My open requests';

  @override
  String get kpiReadyForPickup => 'Ready for pickup';

  @override
  String get kpiMyCompleted => 'Received';

  @override
  String get kpiPendingApproval => 'Pending approval';

  @override
  String get kpiOverdue => 'Overdue (SLA)';

  @override
  String get kpiToPrepare => 'To prepare';

  @override
  String get kpiOnHold => 'On hold (stock)';

  @override
  String get kpiLowStock => 'Low stock items';

  @override
  String get kpiCompletedToday => 'Issued today';

  @override
  String get kpiOpenRequests => 'Open requests';

  @override
  String get replacementDueTitle => 'Replacement due';

  @override
  String replacementDueBody(String codes, String count) {
    return '$count item(s) have reached their lifespan: $codes';
  }

  @override
  String get lowStockTitle => 'Low stock';

  @override
  String availableOfReorder(String available, String reorder) {
    return '$available left · reorder at $reorder';
  }

  @override
  String get complianceTitle => 'Safety compliance';

  @override
  String complianceBody(String ok, String total) {
    return '$ok of $total workers have up-to-date PPE';
  }

  @override
  String get noRecentRequests => 'No requests yet';

  @override
  String pendingSyncBanner(String count) {
    return '$count request(s) waiting to sync';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get catalogTitle => 'PPE Catalog';

  @override
  String get searchPpe => 'Search name, code or size';

  @override
  String get inStockOnly => 'In stock';

  @override
  String get catHead => 'Head';

  @override
  String get catEye => 'Eye';

  @override
  String get catHearing => 'Hearing';

  @override
  String get catRespiratory => 'Respiratory';

  @override
  String get catHand => 'Hand';

  @override
  String get catFoot => 'Foot';

  @override
  String get catBody => 'Body';

  @override
  String get catFall => 'Fall protection';

  @override
  String stockCount(String count) {
    return '$count in stock';
  }

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get lowStockBadge => 'Low stock';

  @override
  String quotaPerRequest(String quota, String unit) {
    return 'Quota $quota $unit / request';
  }

  @override
  String lifespanDays(String days) {
    return 'Lifespan $days days';
  }

  @override
  String get sizes => 'Sizes';

  @override
  String get serialControlled => 'Serial controlled';

  @override
  String get returnable => 'Must be returned / inspected';

  @override
  String get addToRequest => 'Add to request';

  @override
  String get inRequest => 'In request';

  @override
  String get requestThis => 'Request this item';

  @override
  String get eligibilityTitle => 'Your eligibility';

  @override
  String get eligibleNow => 'You can request this item now';

  @override
  String eligibleAt(String date) {
    return 'Next normal request from $date';
  }

  @override
  String lastIssuedAt(String date) {
    return 'Last received $date';
  }

  @override
  String get specialApprovalNeeded =>
      'Needs special approval (Supervisor + EHS)';

  @override
  String get editPolicy => 'Edit policy';

  @override
  String get quotaLabel => 'Quota per request';

  @override
  String get lifespanLabel => 'Lifespan (days)';

  @override
  String get reorderPoint => 'Reorder point';

  @override
  String get activeItem => 'Active in catalog';

  @override
  String get changeReason => 'Reason for change';

  @override
  String get changeReasonHint => 'Required for audit trail';

  @override
  String get policyUpdated => 'Policy updated';

  @override
  String get noItems => 'No PPE found';

  @override
  String get inactive => 'Inactive';

  @override
  String get description => 'Description';

  @override
  String get unitPiece => 'pcs';

  @override
  String get unitPair => 'pairs';

  @override
  String get unitSet => 'sets';

  @override
  String get newRequestTitle => 'New request';

  @override
  String get cartEmpty => 'No items yet. Add PPE from the catalog.';

  @override
  String get browseCatalog => 'Browse catalog';

  @override
  String get addItem => 'Add item';

  @override
  String get size => 'Size';

  @override
  String get quantity => 'Quantity';

  @override
  String get reason => 'Reason';

  @override
  String get reasonDamaged => 'Damaged';

  @override
  String get reasonLifespanExpired => 'Lifespan expired';

  @override
  String get reasonNewEmployee => 'New employee';

  @override
  String get reasonLost => 'Lost';

  @override
  String get reasonReturnScheduled => 'Scheduled replacement';

  @override
  String get reasonOther => 'Other';

  @override
  String get specialReasonLabel => 'Justification for special approval';

  @override
  String get specialReasonHint => 'Explain why you need this item';

  @override
  String get submitRequest => 'Submit request';

  @override
  String requestSubmitted(String no) {
    return 'Request $no submitted';
  }

  @override
  String get requestQueued =>
      'You are offline. The request was saved and will be sent automatically.';

  @override
  String quotaExceededLine(String quota) {
    return 'Above quota ($quota) – special approval';
  }

  @override
  String lifespanNotExpiredLine(String date) {
    return 'Not due until $date – special approval';
  }

  @override
  String get specialItemLine =>
      'Fall protection – always needs special approval';

  @override
  String stockLine(String count) {
    return 'Stock: $count';
  }

  @override
  String get requestsTitle => 'Requests';

  @override
  String get tabActive => 'Active';

  @override
  String get tabHistory => 'History';

  @override
  String get scopeMine => 'Mine';

  @override
  String get scopeTeam => 'Team';

  @override
  String get scopeAll => 'All';

  @override
  String get searchRequests => 'Search request no. or employee';

  @override
  String get noRequests => 'No requests';

  @override
  String itemsCount(String count) {
    return '$count item(s)';
  }

  @override
  String get statusPending => 'Pending approval';

  @override
  String get statusSpecial => 'Special approval';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusOnHold => 'On hold (stock)';

  @override
  String get statusReady => 'Ready for pickup';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get overdue => 'Overdue';

  @override
  String ageHours(String hours) {
    return '$hours h ago';
  }

  @override
  String get requestDetail => 'Request detail';

  @override
  String get requester => 'Requester';

  @override
  String get createdAt => 'Created';

  @override
  String get items => 'Items';

  @override
  String get approvals => 'Approvals';

  @override
  String get comments => 'Comments';

  @override
  String get stockHistory => 'Stock history';

  @override
  String get specialReason => 'Special reason';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get requestInfo => 'Ask for info';

  @override
  String get rejectReason => 'Reason for rejection';

  @override
  String get approveNote => 'Note (optional)';

  @override
  String get infoQuestion => 'What information do you need?';

  @override
  String get addComment => 'Write a comment';

  @override
  String get send => 'Send';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get cancelConfirm =>
      'Cancel this request? Reserved stock will be released.';

  @override
  String get prepare => 'Reserve & prepare';

  @override
  String get issue => 'Issue to employee';

  @override
  String get showPickupQr => 'Show pickup QR';

  @override
  String get pickupQrTitle => 'Pickup QR';

  @override
  String get pickupQrHint =>
      'Show this code to the store keeper. It can be used once.';

  @override
  String expiresAt(String time) {
    return 'Expires at $time';
  }

  @override
  String get qrExpired => 'Code expired';

  @override
  String get regenerate => 'New code';

  @override
  String get serialNumbers => 'Serial numbers';

  @override
  String get serialHint => 'Scan or type, one per line';

  @override
  String expectedSerials(String serials) {
    return 'Reserved: $serials';
  }

  @override
  String get issueConfirmed => 'PPE issued';

  @override
  String get verifiedByQr => 'Verified by pickup QR';

  @override
  String get issueWithoutQr => 'Issue without QR (manual check)';

  @override
  String get returnItem => 'Receive return';

  @override
  String get conditionGood => 'Good – back to stock';

  @override
  String get conditionDamaged => 'Damaged – write off';

  @override
  String get note => 'Note';

  @override
  String get returned => 'Returned';

  @override
  String returnDue(String date) {
    return 'Return / inspect by $date';
  }

  @override
  String get approvalNormal => 'Supervisor approval';

  @override
  String get approvalSpecialSupervisor => 'Special – Supervisor';

  @override
  String get approvalSpecialEhs => 'Special – EHS';

  @override
  String get approvalStoreRelease => 'Store release';

  @override
  String get decisionApproved => 'Approved';

  @override
  String get decisionRejected => 'Rejected';

  @override
  String get infoRequestTag => 'Info requested';

  @override
  String get eventReceipt => 'Received';

  @override
  String get eventReserve => 'Reserved';

  @override
  String get eventIssue => 'Issued';

  @override
  String get eventReturn => 'Returned';

  @override
  String get eventAdjustment => 'Adjusted';

  @override
  String get eventDamage => 'Written off';

  @override
  String get progressSubmitted => 'Submitted';

  @override
  String get progressApproved => 'Approved';

  @override
  String get progressReady => 'Ready';

  @override
  String get progressReceived => 'Received';

  @override
  String get actionSuccess => 'Saved';

  @override
  String get approvalsTitle => 'Approval inbox';

  @override
  String get noApprovals => 'Nothing is waiting for you';

  @override
  String get approvedMsg => 'Request approved';

  @override
  String get rejectedMsg => 'Request rejected';

  @override
  String get infoRequestedMsg => 'Question sent to the requester';

  @override
  String get storeTitle => 'Store fulfilment';

  @override
  String get tabToPrepare => 'To prepare';

  @override
  String get tabOnHold => 'On hold';

  @override
  String get tabReady => 'Ready';

  @override
  String get scanPickupQr => 'Scan pickup QR';

  @override
  String get preparedMsg => 'Stock reserved – ready for pickup';

  @override
  String get onHoldMsg => 'Not enough stock – request put on hold';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get available => 'Available';

  @override
  String get reserved => 'Reserved';

  @override
  String get issued30d => 'Issued 30d';

  @override
  String get needsReorder => 'Reorder';

  @override
  String expiringLots(String count) {
    return '$count lot(s) expiring within 30 days';
  }

  @override
  String get lotsTitle => 'Lots & serials';

  @override
  String get lot => 'Lot';

  @override
  String get serial => 'Serial';

  @override
  String get supplier => 'Supplier';

  @override
  String get expiry => 'Expiry';

  @override
  String get expired => 'Expired';

  @override
  String get expiresSoon => 'Expiring soon';

  @override
  String get adjustStock => 'Adjust';

  @override
  String get adjustDelta => 'Change (+ / −)';

  @override
  String get writeOffDamaged => 'Write off as damaged';

  @override
  String get adjusted => 'Stock updated';

  @override
  String get receiveStockTitle => 'Receive stock';

  @override
  String get ppeItem => 'PPE item';

  @override
  String get lotNumber => 'Lot number';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get pickDate => 'Pick date';

  @override
  String receivedMsg(String count) {
    return '$count unit(s) received';
  }

  @override
  String get purchaseRequest => 'Purchase request';

  @override
  String get filterLowStock => 'Low stock only';

  @override
  String get stockMovements => 'Movements';

  @override
  String get noLots => 'No lots';

  @override
  String get purchaseRequestsTitle => 'Purchase requests';

  @override
  String get newPurchaseRequest => 'New purchase request';

  @override
  String get prStatusPending => 'Pending';

  @override
  String get prStatusApproved => 'Approved';

  @override
  String get prStatusOrdered => 'Ordered';

  @override
  String get prStatusReceived => 'Received';

  @override
  String get prStatusRejected => 'Rejected';

  @override
  String markAs(String status) {
    return 'Mark $status';
  }

  @override
  String get receiveIntoStock => 'Receive into stock';

  @override
  String get noPurchaseRequests => 'No purchase requests';

  @override
  String get scanTitle => 'Scan QR';

  @override
  String get scanHint => 'Point the camera at the employee\'s pickup QR';

  @override
  String get manualEntry => 'Enter code manually';

  @override
  String get qrCode => 'QR code';

  @override
  String get verify => 'Verify';

  @override
  String get openRequest => 'Open request';

  @override
  String get cameraUnavailable =>
      'Camera not available. Enter the code manually.';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markUnread => 'Mark as unread';

  @override
  String get markRead => 'Mark as read';

  @override
  String notifNewRequisition(String no) {
    return 'New request $no';
  }

  @override
  String notifApprovalResult(String no, String status) {
    return '$no: $status';
  }

  @override
  String notifReady(String no) {
    return '$no is ready for pickup';
  }

  @override
  String notifReorder(String code) {
    return 'Low stock: $code';
  }

  @override
  String notifInfoRequested(String no) {
    return 'Message about $no';
  }

  @override
  String notifIssued(String no) {
    return '$no issued';
  }

  @override
  String notifOnHold(String no) {
    return '$no is waiting for stock';
  }

  @override
  String get pushReceived => 'New notification';

  @override
  String get language => 'Language';

  @override
  String get biometricLock => 'Biometric lock';

  @override
  String get biometricLockSub => 'Require fingerprint / face to open the app';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get syncQueue => 'Offline queue';

  @override
  String get syncQueueEmpty => 'Everything is synced';

  @override
  String get syncPending => 'Waiting';

  @override
  String get syncSyncing => 'Sending…';

  @override
  String get syncFailed => 'Failed';

  @override
  String syncedCount(String count) {
    return '$count request(s) sent';
  }

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm => 'Sign out of this device?';

  @override
  String get tools => 'Tools';

  @override
  String get settings => 'Settings';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get myPpeTitle => 'My PPE';

  @override
  String get noIssuedItems => 'You have no PPE on record';

  @override
  String issuedOn(String date) {
    return 'Received $date';
  }

  @override
  String replaceFrom(String date) {
    return 'Replace from $date';
  }

  @override
  String get replacementDueNow => 'Replacement due';

  @override
  String get supervisor => 'Supervisor';

  @override
  String get usersTitle => 'Users';

  @override
  String get searchUsers => 'Search name, ID or department';

  @override
  String get role => 'Role';

  @override
  String get activeUser => 'Active';

  @override
  String get userUpdated => 'User updated';

  @override
  String transferTeam(int count) {
    return 'Move team ($count people) to new supervisor';
  }

  @override
  String transferTeamTo(String name) {
    return 'New supervisor for $name\'s team';
  }

  @override
  String transferTeamDone(int count) {
    return 'Moved $count people to the new supervisor';
  }

  @override
  String get errTeamNotEmpty =>
      'This supervisor still has a team. Move the team to another supervisor first.';

  @override
  String get noOtherSupervisor =>
      'No other active supervisor yet. Create or promote one first.';

  @override
  String get supervisorIdOptional => 'Supervisor user ID (optional)';

  @override
  String get auditTitle => 'Audit log';

  @override
  String get searchAudit => 'Search employee or record ID';

  @override
  String get noAuditEntries => 'No audit entries';

  @override
  String get noUsers => 'No users found';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get requestPipeline => 'Request pipeline';

  @override
  String get stockHealth => 'Stock health';

  @override
  String stockHealthBody(String low, String total) {
    return '$low of $total items at or below reorder point';
  }
}
