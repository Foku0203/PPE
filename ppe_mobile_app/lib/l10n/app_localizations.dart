import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my'),
    Locale('th'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PPE SMART'**
  String get appTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline – showing saved data'**
  String get offlineBanner;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection.'**
  String get errorNoInternet;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond.'**
  String get errorTimeout;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get errorValidation;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid Employee ID or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errActiveRequestExists.
  ///
  /// In en, this message translates to:
  /// **'You already have an open request for this item.'**
  String get errActiveRequestExists;

  /// No description provided for @errSpecialReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please give a reason for early replacement or quantity above quota.'**
  String get errSpecialReasonRequired;

  /// No description provided for @errSizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a size for every item.'**
  String get errSizeRequired;

  /// No description provided for @errInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock.'**
  String get errInsufficientStock;

  /// No description provided for @errSerialMismatch.
  ///
  /// In en, this message translates to:
  /// **'Scanned serial numbers don\'t match the reserved units.'**
  String get errSerialMismatch;

  /// No description provided for @errSerialRequired.
  ///
  /// In en, this message translates to:
  /// **'This item needs one serial number per unit.'**
  String get errSerialRequired;

  /// No description provided for @errSerialExists.
  ///
  /// In en, this message translates to:
  /// **'One or more serial numbers already exist.'**
  String get errSerialExists;

  /// No description provided for @errQrInvalid.
  ///
  /// In en, this message translates to:
  /// **'QR code is invalid, expired or already used.'**
  String get errQrInvalid;

  /// No description provided for @errQrMismatch.
  ///
  /// In en, this message translates to:
  /// **'This QR code belongs to a different request.'**
  String get errQrMismatch;

  /// No description provided for @errInvalidStatus.
  ///
  /// In en, this message translates to:
  /// **'This action isn\'t possible in the current status.'**
  String get errInvalidStatus;

  /// No description provided for @errNotApprover.
  ///
  /// In en, this message translates to:
  /// **'You are not the approver for this step.'**
  String get errNotApprover;

  /// No description provided for @errReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required.'**
  String get errReasonRequired;

  /// No description provided for @errNegativeStock.
  ///
  /// In en, this message translates to:
  /// **'Stock cannot go below zero or below the reserved quantity.'**
  String get errNegativeStock;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get errWrongPassword;

  /// No description provided for @errAlreadyReturned.
  ///
  /// In en, this message translates to:
  /// **'This item was already returned.'**
  String get errAlreadyReturned;

  /// No description provided for @errItemInactive.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get errItemInactive;

  /// No description provided for @errDuplicateLine.
  ///
  /// In en, this message translates to:
  /// **'The same item appears twice.'**
  String get errDuplicateLine;

  /// No description provided for @errExpiredStock.
  ///
  /// In en, this message translates to:
  /// **'Cannot receive stock that has already expired.'**
  String get errExpiredStock;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personal protective equipment requisition'**
  String get loginSubtitle;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New employee? Register'**
  String get noAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get displayName;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @supervisorEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Employee ID'**
  String get supervisorEmployeeId;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already registered? Sign in'**
  String get haveAccount;

  /// No description provided for @registerNote.
  ///
  /// In en, this message translates to:
  /// **'New accounts start with the Worker role. An administrator can change roles later.'**
  String get registerNote;

  /// No description provided for @serverSettings.
  ///
  /// In en, this message translates to:
  /// **'Server settings'**
  String get serverSettings;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. http://192.168.1.10:8000/api/v1'**
  String get serverUrlHint;

  /// No description provided for @resetDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetDefault;

  /// No description provided for @demoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts (password ChangeMe123!)'**
  String get demoAccounts;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'App locked'**
  String get unlockTitle;

  /// No description provided for @unlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to continue'**
  String get unlockSubtitle;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock PPE Management'**
  String get biometricReason;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device.'**
  String get biometricUnavailable;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get navCatalog;

  /// No description provided for @navRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// No description provided for @navApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get navApprovals;

  /// No description provided for @navStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get navStore;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @roleWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get roleWorker;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @roleStoreKeeper.
  ///
  /// In en, this message translates to:
  /// **'Store keeper'**
  String get roleStoreKeeper;

  /// No description provided for @roleEhs.
  ///
  /// In en, this message translates to:
  /// **'EHS officer'**
  String get roleEhs;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greeting(String name);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @actionNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get actionNewRequest;

  /// No description provided for @actionMyPpe.
  ///
  /// In en, this message translates to:
  /// **'My PPE'**
  String get actionMyPpe;

  /// No description provided for @actionScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get actionScanQr;

  /// No description provided for @actionReceiveStock.
  ///
  /// In en, this message translates to:
  /// **'Receive stock'**
  String get actionReceiveStock;

  /// No description provided for @actionPurchaseRequests.
  ///
  /// In en, this message translates to:
  /// **'Purchase requests'**
  String get actionPurchaseRequests;

  /// No description provided for @actionAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get actionAuditLog;

  /// No description provided for @actionUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get actionUsers;

  /// No description provided for @actionAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get actionAnalytics;

  /// No description provided for @actionManageCatalog.
  ///
  /// In en, this message translates to:
  /// **'Manage catalog'**
  String get actionManageCatalog;

  /// No description provided for @recentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent requests'**
  String get recentRequests;

  /// No description provided for @kpiMyOpen.
  ///
  /// In en, this message translates to:
  /// **'My open requests'**
  String get kpiMyOpen;

  /// No description provided for @kpiReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get kpiReadyForPickup;

  /// No description provided for @kpiMyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get kpiMyCompleted;

  /// No description provided for @kpiPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get kpiPendingApproval;

  /// No description provided for @kpiOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue (SLA)'**
  String get kpiOverdue;

  /// No description provided for @kpiToPrepare.
  ///
  /// In en, this message translates to:
  /// **'To prepare'**
  String get kpiToPrepare;

  /// No description provided for @kpiOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold (stock)'**
  String get kpiOnHold;

  /// No description provided for @kpiLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock items'**
  String get kpiLowStock;

  /// No description provided for @kpiCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'Issued today'**
  String get kpiCompletedToday;

  /// No description provided for @kpiOpenRequests.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get kpiOpenRequests;

  /// No description provided for @replacementDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Replacement due'**
  String get replacementDueTitle;

  /// No description provided for @replacementDueBody.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) have reached their lifespan: {codes}'**
  String replacementDueBody(String codes, String count);

  /// No description provided for @lowStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockTitle;

  /// No description provided for @availableOfReorder.
  ///
  /// In en, this message translates to:
  /// **'{available} left · reorder at {reorder}'**
  String availableOfReorder(String available, String reorder);

  /// No description provided for @complianceTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety compliance'**
  String get complianceTitle;

  /// No description provided for @complianceBody.
  ///
  /// In en, this message translates to:
  /// **'{ok} of {total} workers have up-to-date PPE'**
  String complianceBody(String ok, String total);

  /// No description provided for @noRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRecentRequests;

  /// No description provided for @pendingSyncBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} request(s) waiting to sync'**
  String pendingSyncBanner(String count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'PPE Catalog'**
  String get catalogTitle;

  /// No description provided for @searchPpe.
  ///
  /// In en, this message translates to:
  /// **'Search name, code or size'**
  String get searchPpe;

  /// No description provided for @inStockOnly.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStockOnly;

  /// No description provided for @catHead.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get catHead;

  /// No description provided for @catEye.
  ///
  /// In en, this message translates to:
  /// **'Eye'**
  String get catEye;

  /// No description provided for @catHearing.
  ///
  /// In en, this message translates to:
  /// **'Hearing'**
  String get catHearing;

  /// No description provided for @catRespiratory.
  ///
  /// In en, this message translates to:
  /// **'Respiratory'**
  String get catRespiratory;

  /// No description provided for @catHand.
  ///
  /// In en, this message translates to:
  /// **'Hand'**
  String get catHand;

  /// No description provided for @catFoot.
  ///
  /// In en, this message translates to:
  /// **'Foot'**
  String get catFoot;

  /// No description provided for @catBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get catBody;

  /// No description provided for @catFall.
  ///
  /// In en, this message translates to:
  /// **'Fall protection'**
  String get catFall;

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String stockCount(String count);

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @lowStockBadge.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockBadge;

  /// No description provided for @quotaPerRequest.
  ///
  /// In en, this message translates to:
  /// **'Quota {quota} {unit} / request'**
  String quotaPerRequest(String quota, String unit);

  /// No description provided for @lifespanDays.
  ///
  /// In en, this message translates to:
  /// **'Lifespan {days} days'**
  String lifespanDays(String days);

  /// No description provided for @sizes.
  ///
  /// In en, this message translates to:
  /// **'Sizes'**
  String get sizes;

  /// No description provided for @serialControlled.
  ///
  /// In en, this message translates to:
  /// **'Serial controlled'**
  String get serialControlled;

  /// No description provided for @returnable.
  ///
  /// In en, this message translates to:
  /// **'Must be returned / inspected'**
  String get returnable;

  /// No description provided for @addToRequest.
  ///
  /// In en, this message translates to:
  /// **'Add to request'**
  String get addToRequest;

  /// No description provided for @inRequest.
  ///
  /// In en, this message translates to:
  /// **'In request'**
  String get inRequest;

  /// No description provided for @requestThis.
  ///
  /// In en, this message translates to:
  /// **'Request this item'**
  String get requestThis;

  /// No description provided for @eligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your eligibility'**
  String get eligibilityTitle;

  /// No description provided for @eligibleNow.
  ///
  /// In en, this message translates to:
  /// **'You can request this item now'**
  String get eligibleNow;

  /// No description provided for @eligibleAt.
  ///
  /// In en, this message translates to:
  /// **'Next normal request from {date}'**
  String eligibleAt(String date);

  /// No description provided for @lastIssuedAt.
  ///
  /// In en, this message translates to:
  /// **'Last received {date}'**
  String lastIssuedAt(String date);

  /// No description provided for @specialApprovalNeeded.
  ///
  /// In en, this message translates to:
  /// **'Needs special approval (Supervisor + EHS)'**
  String get specialApprovalNeeded;

  /// No description provided for @editPolicy.
  ///
  /// In en, this message translates to:
  /// **'Edit policy'**
  String get editPolicy;

  /// No description provided for @quotaLabel.
  ///
  /// In en, this message translates to:
  /// **'Quota per request'**
  String get quotaLabel;

  /// No description provided for @lifespanLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifespan (days)'**
  String get lifespanLabel;

  /// No description provided for @reorderPoint.
  ///
  /// In en, this message translates to:
  /// **'Reorder point'**
  String get reorderPoint;

  /// No description provided for @activeItem.
  ///
  /// In en, this message translates to:
  /// **'Active in catalog'**
  String get activeItem;

  /// No description provided for @changeReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for change'**
  String get changeReason;

  /// No description provided for @changeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Required for audit trail'**
  String get changeReasonHint;

  /// No description provided for @policyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Policy updated'**
  String get policyUpdated;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No PPE found'**
  String get noItems;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @unitPiece.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get unitPiece;

  /// No description provided for @unitPair.
  ///
  /// In en, this message translates to:
  /// **'pairs'**
  String get unitPair;

  /// No description provided for @unitSet.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get unitSet;

  /// No description provided for @newRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequestTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Add PPE from the catalog.'**
  String get cartEmpty;

  /// No description provided for @browseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Browse catalog'**
  String get browseCatalog;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reasonDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get reasonDamaged;

  /// No description provided for @reasonLifespanExpired.
  ///
  /// In en, this message translates to:
  /// **'Lifespan expired'**
  String get reasonLifespanExpired;

  /// No description provided for @reasonNewEmployee.
  ///
  /// In en, this message translates to:
  /// **'New employee'**
  String get reasonNewEmployee;

  /// No description provided for @reasonLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get reasonLost;

  /// No description provided for @reasonReturnScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled replacement'**
  String get reasonReturnScheduled;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @specialReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Justification for special approval'**
  String get specialReasonLabel;

  /// No description provided for @specialReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Explain why you need it early or above quota'**
  String get specialReasonHint;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get submitRequest;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request {no} submitted'**
  String requestSubmitted(String no);

  /// No description provided for @requestQueued.
  ///
  /// In en, this message translates to:
  /// **'You are offline. The request was saved and will be sent automatically.'**
  String get requestQueued;

  /// No description provided for @quotaExceededLine.
  ///
  /// In en, this message translates to:
  /// **'Above quota ({quota}) – special approval'**
  String quotaExceededLine(String quota);

  /// No description provided for @lifespanNotExpiredLine.
  ///
  /// In en, this message translates to:
  /// **'Not due until {date} – special approval'**
  String lifespanNotExpiredLine(String date);

  /// No description provided for @stockLine.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String stockLine(String count);

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTitle;

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @scopeMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get scopeMine;

  /// No description provided for @scopeTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get scopeTeam;

  /// No description provided for @scopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scopeAll;

  /// No description provided for @searchRequests.
  ///
  /// In en, this message translates to:
  /// **'Search request no. or employee'**
  String get searchRequests;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequests;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s)'**
  String itemsCount(String count);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get statusPending;

  /// No description provided for @statusSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special approval'**
  String get statusSpecial;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold (stock)'**
  String get statusOnHold;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get statusReady;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @ageHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String ageHours(String hours);

  /// No description provided for @requestDetail.
  ///
  /// In en, this message translates to:
  /// **'Request detail'**
  String get requestDetail;

  /// No description provided for @requester.
  ///
  /// In en, this message translates to:
  /// **'Requester'**
  String get requester;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAt;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @stockHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get stockHistory;

  /// No description provided for @specialReason.
  ///
  /// In en, this message translates to:
  /// **'Special reason'**
  String get specialReason;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @requestInfo.
  ///
  /// In en, this message translates to:
  /// **'Ask for info'**
  String get requestInfo;

  /// No description provided for @rejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get rejectReason;

  /// No description provided for @approveNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get approveNote;

  /// No description provided for @infoQuestion.
  ///
  /// In en, this message translates to:
  /// **'What information do you need?'**
  String get infoQuestion;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get addComment;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @cancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request? Reserved stock will be released.'**
  String get cancelConfirm;

  /// No description provided for @prepare.
  ///
  /// In en, this message translates to:
  /// **'Reserve & prepare'**
  String get prepare;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue to employee'**
  String get issue;

  /// No description provided for @showPickupQr.
  ///
  /// In en, this message translates to:
  /// **'Show pickup QR'**
  String get showPickupQr;

  /// No description provided for @pickupQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup QR'**
  String get pickupQrTitle;

  /// No description provided for @pickupQrHint.
  ///
  /// In en, this message translates to:
  /// **'Show this code to the store keeper. It can be used once.'**
  String get pickupQrHint;

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires at {time}'**
  String expiresAt(String time);

  /// No description provided for @qrExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get qrExpired;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get regenerate;

  /// No description provided for @serialNumbers.
  ///
  /// In en, this message translates to:
  /// **'Serial numbers'**
  String get serialNumbers;

  /// No description provided for @serialHint.
  ///
  /// In en, this message translates to:
  /// **'Scan or type, one per line'**
  String get serialHint;

  /// No description provided for @expectedSerials.
  ///
  /// In en, this message translates to:
  /// **'Reserved: {serials}'**
  String expectedSerials(String serials);

  /// No description provided for @issueConfirmed.
  ///
  /// In en, this message translates to:
  /// **'PPE issued'**
  String get issueConfirmed;

  /// No description provided for @verifiedByQr.
  ///
  /// In en, this message translates to:
  /// **'Verified by pickup QR'**
  String get verifiedByQr;

  /// No description provided for @issueWithoutQr.
  ///
  /// In en, this message translates to:
  /// **'Issue without QR (manual check)'**
  String get issueWithoutQr;

  /// No description provided for @returnItem.
  ///
  /// In en, this message translates to:
  /// **'Receive return'**
  String get returnItem;

  /// No description provided for @conditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good – back to stock'**
  String get conditionGood;

  /// No description provided for @conditionDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged – write off'**
  String get conditionDamaged;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @returnDue.
  ///
  /// In en, this message translates to:
  /// **'Return / inspect by {date}'**
  String returnDue(String date);

  /// No description provided for @approvalNormal.
  ///
  /// In en, this message translates to:
  /// **'Supervisor approval'**
  String get approvalNormal;

  /// No description provided for @approvalSpecialSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Special – Supervisor'**
  String get approvalSpecialSupervisor;

  /// No description provided for @approvalSpecialEhs.
  ///
  /// In en, this message translates to:
  /// **'Special – EHS'**
  String get approvalSpecialEhs;

  /// No description provided for @approvalStoreRelease.
  ///
  /// In en, this message translates to:
  /// **'Store release'**
  String get approvalStoreRelease;

  /// No description provided for @decisionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get decisionApproved;

  /// No description provided for @decisionRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get decisionRejected;

  /// No description provided for @infoRequestTag.
  ///
  /// In en, this message translates to:
  /// **'Info requested'**
  String get infoRequestTag;

  /// No description provided for @eventReceipt.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get eventReceipt;

  /// No description provided for @eventReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get eventReserve;

  /// No description provided for @eventIssue.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get eventIssue;

  /// No description provided for @eventReturn.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get eventReturn;

  /// No description provided for @eventAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjusted'**
  String get eventAdjustment;

  /// No description provided for @eventDamage.
  ///
  /// In en, this message translates to:
  /// **'Written off'**
  String get eventDamage;

  /// No description provided for @progressSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get progressSubmitted;

  /// No description provided for @progressApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get progressApproved;

  /// No description provided for @progressReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get progressReady;

  /// No description provided for @progressReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get progressReceived;

  /// No description provided for @actionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get actionSuccess;

  /// No description provided for @approvalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval inbox'**
  String get approvalsTitle;

  /// No description provided for @noApprovals.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for you'**
  String get noApprovals;

  /// No description provided for @approvedMsg.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get approvedMsg;

  /// No description provided for @rejectedMsg.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get rejectedMsg;

  /// No description provided for @infoRequestedMsg.
  ///
  /// In en, this message translates to:
  /// **'Question sent to the requester'**
  String get infoRequestedMsg;

  /// No description provided for @storeTitle.
  ///
  /// In en, this message translates to:
  /// **'Store fulfilment'**
  String get storeTitle;

  /// No description provided for @tabToPrepare.
  ///
  /// In en, this message translates to:
  /// **'To prepare'**
  String get tabToPrepare;

  /// No description provided for @tabOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get tabOnHold;

  /// No description provided for @tabReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get tabReady;

  /// No description provided for @scanPickupQr.
  ///
  /// In en, this message translates to:
  /// **'Scan pickup QR'**
  String get scanPickupQr;

  /// No description provided for @preparedMsg.
  ///
  /// In en, this message translates to:
  /// **'Stock reserved – ready for pickup'**
  String get preparedMsg;

  /// No description provided for @onHoldMsg.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock – request put on hold'**
  String get onHoldMsg;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

  /// No description provided for @issued30d.
  ///
  /// In en, this message translates to:
  /// **'Issued 30d'**
  String get issued30d;

  /// No description provided for @needsReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get needsReorder;

  /// No description provided for @expiringLots.
  ///
  /// In en, this message translates to:
  /// **'{count} lot(s) expiring within 30 days'**
  String expiringLots(String count);

  /// No description provided for @lotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lots & serials'**
  String get lotsTitle;

  /// No description provided for @lot.
  ///
  /// In en, this message translates to:
  /// **'Lot'**
  String get lot;

  /// No description provided for @serial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serial;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiry;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expiresSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiresSoon;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjustStock;

  /// No description provided for @adjustDelta.
  ///
  /// In en, this message translates to:
  /// **'Change (+ / −)'**
  String get adjustDelta;

  /// No description provided for @writeOffDamaged.
  ///
  /// In en, this message translates to:
  /// **'Write off as damaged'**
  String get writeOffDamaged;

  /// No description provided for @adjusted.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get adjusted;

  /// No description provided for @receiveStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive stock'**
  String get receiveStockTitle;

  /// No description provided for @ppeItem.
  ///
  /// In en, this message translates to:
  /// **'PPE item'**
  String get ppeItem;

  /// No description provided for @lotNumber.
  ///
  /// In en, this message translates to:
  /// **'Lot number'**
  String get lotNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @receivedMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} unit(s) received'**
  String receivedMsg(String count);

  /// No description provided for @purchaseRequest.
  ///
  /// In en, this message translates to:
  /// **'Purchase request'**
  String get purchaseRequest;

  /// No description provided for @filterLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock only'**
  String get filterLowStock;

  /// No description provided for @stockMovements.
  ///
  /// In en, this message translates to:
  /// **'Movements'**
  String get stockMovements;

  /// No description provided for @noLots.
  ///
  /// In en, this message translates to:
  /// **'No lots'**
  String get noLots;

  /// No description provided for @purchaseRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase requests'**
  String get purchaseRequestsTitle;

  /// No description provided for @newPurchaseRequest.
  ///
  /// In en, this message translates to:
  /// **'New purchase request'**
  String get newPurchaseRequest;

  /// No description provided for @prStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get prStatusPending;

  /// No description provided for @prStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get prStatusApproved;

  /// No description provided for @prStatusOrdered.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get prStatusOrdered;

  /// No description provided for @prStatusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get prStatusReceived;

  /// No description provided for @prStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get prStatusRejected;

  /// No description provided for @markAs.
  ///
  /// In en, this message translates to:
  /// **'Mark {status}'**
  String markAs(String status);

  /// No description provided for @receiveIntoStock.
  ///
  /// In en, this message translates to:
  /// **'Receive into stock'**
  String get receiveIntoStock;

  /// No description provided for @noPurchaseRequests.
  ///
  /// In en, this message translates to:
  /// **'No purchase requests'**
  String get noPurchaseRequests;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the employee\'s pickup QR'**
  String get scanHint;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get manualEntry;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get qrCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @openRequest.
  ///
  /// In en, this message translates to:
  /// **'Open request'**
  String get openRequest;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera not available. Enter the code manually.'**
  String get cameraUnavailable;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markUnread;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markRead;

  /// No description provided for @notifNewRequisition.
  ///
  /// In en, this message translates to:
  /// **'New request {no}'**
  String notifNewRequisition(String no);

  /// No description provided for @notifApprovalResult.
  ///
  /// In en, this message translates to:
  /// **'{no}: {status}'**
  String notifApprovalResult(String no, String status);

  /// No description provided for @notifReady.
  ///
  /// In en, this message translates to:
  /// **'{no} is ready for pickup'**
  String notifReady(String no);

  /// No description provided for @notifReorder.
  ///
  /// In en, this message translates to:
  /// **'Low stock: {code}'**
  String notifReorder(String code);

  /// No description provided for @notifInfoRequested.
  ///
  /// In en, this message translates to:
  /// **'Message about {no}'**
  String notifInfoRequested(String no);

  /// No description provided for @notifIssued.
  ///
  /// In en, this message translates to:
  /// **'{no} issued'**
  String notifIssued(String no);

  /// No description provided for @notifOnHold.
  ///
  /// In en, this message translates to:
  /// **'{no} is waiting for stock'**
  String notifOnHold(String no);

  /// No description provided for @pushReceived.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get pushReceived;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @biometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric lock'**
  String get biometricLock;

  /// No description provided for @biometricLockSub.
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint / face to open the app'**
  String get biometricLockSub;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @syncQueue.
  ///
  /// In en, this message translates to:
  /// **'Offline queue'**
  String get syncQueue;

  /// No description provided for @syncQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced'**
  String get syncQueueEmpty;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get syncPending;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get syncSyncing;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syncFailed;

  /// No description provided for @syncedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} request(s) sent'**
  String syncedCount(String count);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device?'**
  String get logoutConfirm;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @myPpeTitle.
  ///
  /// In en, this message translates to:
  /// **'My PPE'**
  String get myPpeTitle;

  /// No description provided for @noIssuedItems.
  ///
  /// In en, this message translates to:
  /// **'You have no PPE on record'**
  String get noIssuedItems;

  /// No description provided for @issuedOn.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String issuedOn(String date);

  /// No description provided for @replaceFrom.
  ///
  /// In en, this message translates to:
  /// **'Replace from {date}'**
  String replaceFrom(String date);

  /// No description provided for @replacementDueNow.
  ///
  /// In en, this message translates to:
  /// **'Replacement due'**
  String get replacementDueNow;

  /// No description provided for @supervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get supervisor;

  /// No description provided for @usersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTitle;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search name, ID or department'**
  String get searchUsers;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @activeUser.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeUser;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get userUpdated;

  /// No description provided for @supervisorIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Supervisor user ID (optional)'**
  String get supervisorIdOptional;

  /// No description provided for @auditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditTitle;

  /// No description provided for @searchAudit.
  ///
  /// In en, this message translates to:
  /// **'Search employee or record ID'**
  String get searchAudit;

  /// No description provided for @noAuditEntries.
  ///
  /// In en, this message translates to:
  /// **'No audit entries'**
  String get noAuditEntries;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsers;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @requestPipeline.
  ///
  /// In en, this message translates to:
  /// **'Request pipeline'**
  String get requestPipeline;

  /// No description provided for @stockHealth.
  ///
  /// In en, this message translates to:
  /// **'Stock health'**
  String get stockHealth;

  /// No description provided for @stockHealthBody.
  ///
  /// In en, this message translates to:
  /// **'{low} of {total} items at or below reorder point'**
  String stockHealthBody(String low, String total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'my', 'th', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
