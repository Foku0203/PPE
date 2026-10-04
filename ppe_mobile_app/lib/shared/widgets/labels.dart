import 'package:flutter/widgets.dart';

import '../../core/errors/app_exceptions.dart';
import '../../l10n/app_localizations.dart';
import '../models/notification_model.dart';
import '../models/ppe_item_model.dart';
import '../models/requisition_model.dart';
import '../models/user_model.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Maps enums and backend codes to localized strings.
extension Labels on AppLocalizations {
  String status(RequisitionStatus s) => switch (s) {
        RequisitionStatus.pending => statusPending,
        RequisitionStatus.special => statusSpecial,
        RequisitionStatus.approved => statusApproved,
        RequisitionStatus.onHold => statusOnHold,
        RequisitionStatus.ready => statusReady,
        RequisitionStatus.completed => statusCompleted,
        RequisitionStatus.rejected => statusRejected,
        RequisitionStatus.cancelled => statusCancelled,
      };

  String statusCode(String? code) => status(RequisitionStatus.fromApi(code));

  String roleName(UserRole r) => switch (r) {
        UserRole.worker => roleWorker,
        UserRole.supervisor => roleSupervisor,
        UserRole.storeKeeper => roleStoreKeeper,
        UserRole.ehs => roleEhs,
        UserRole.admin => roleAdmin,
      };

  String reasonLabel(RequestReason r) => switch (r) {
        RequestReason.damaged => reasonDamaged,
        RequestReason.lifespanExpired => reasonLifespanExpired,
        RequestReason.newEmployee => reasonNewEmployee,
        RequestReason.lost => reasonLost,
        RequestReason.returnScheduled => reasonReturnScheduled,
        RequestReason.other => reasonOther,
      };

  String category(PpeCategory c) => switch (c) {
        PpeCategory.head => catHead,
        PpeCategory.eye => catEye,
        PpeCategory.hearing => catHearing,
        PpeCategory.respiratory => catRespiratory,
        PpeCategory.hand => catHand,
        PpeCategory.foot => catFoot,
        PpeCategory.body => catBody,
        PpeCategory.fall => catFall,
      };

  String unit(String unit) => switch (unit) {
        'pair' => unitPair,
        'set' => unitSet,
        'piece' => unitPiece,
        _ => unit,
      };

  String approvalKind(String kind) => switch (kind) {
        'SPECIAL_SUPERVISOR' => approvalSpecialSupervisor,
        'SPECIAL_EHS' => approvalSpecialEhs,
        'STORE_RELEASE' => approvalStoreRelease,
        _ => approvalNormal,
      };

  String stockEvent(String type) => switch (type) {
        'RECEIPT' => eventReceipt,
        'RESERVE' => eventReserve,
        'ISSUE' => eventIssue,
        'RETURN' => eventReturn,
        'DAMAGE' => eventDamage,
        _ => eventAdjustment,
      };

  String purchaseStatus(String status) => switch (status) {
        'APPROVED' => prStatusApproved,
        'ORDERED' => prStatusOrdered,
        'RECEIVED' => prStatusReceived,
        'REJECTED' => prStatusRejected,
        _ => prStatusPending,
      };

  /// Localized notification title built from type + payload (server titles are English).
  String notificationTitle(AppNotification n) {
    final no = n.requestNo ?? '';
    return switch (n.kind) {
      NotificationKind.newRequisition when no.isNotEmpty => notifNewRequisition(no),
      NotificationKind.approvalResult when no.isNotEmpty => notifApprovalResult(no, statusCode(n.status)),
      NotificationKind.readyForPickup when no.isNotEmpty => notifReady(no),
      NotificationKind.reorderPoint when n.payload['code'] != null && n.payload['purchase_request_id'] == null => notifReorder('${n.payload['code']}'),
      NotificationKind.infoRequested when no.isNotEmpty => notifInfoRequested(no),
      NotificationKind.issued when no.isNotEmpty => notifIssued(no),
      NotificationKind.onHold when no.isNotEmpty => notifOnHold(no),
      _ => n.title,
    };
  }

  /// User-facing message for any failure (README §7.4 error handling strategy).
  String errorMessage(Object error) {
    if (error is NoInternetException) return errorNoInternet;
    if (error is RequestTimeoutException) return errorTimeout;
    if (error is AppException) {
      final mapped = switch (error.code) {
        'INVALID_CREDENTIALS' => errInvalidCredentials,
        'TOKEN_INVALID' || 'UNAUTHORIZED' => errorSessionExpired,
        'FORBIDDEN' => errorForbidden,
        'NOT_FOUND' || 'ITEM_NOT_FOUND' => errorNotFound,
        'ACTIVE_REQUEST_EXISTS' => errActiveRequestExists,
        'SPECIAL_REASON_REQUIRED' => errSpecialReasonRequired,
        'SIZE_REQUIRED' => errSizeRequired,
        'INSUFFICIENT_STOCK' => errInsufficientStock,
        'SERIAL_MISMATCH' => errSerialMismatch,
        'SERIAL_REQUIRED' => errSerialRequired,
        'SERIAL_EXISTS' => errSerialExists,
        'QR_INVALID' => errQrInvalid,
        'QR_MISMATCH' => errQrMismatch,
        'INVALID_STATUS' => errInvalidStatus,
        'NOT_ALLOWED_TO_APPROVE' => errNotApprover,
        'REASON_REQUIRED' || 'MESSAGE_REQUIRED' => errReasonRequired,
        'NEGATIVE_STOCK' => errNegativeStock,
        'WRONG_PASSWORD' => errWrongPassword,
        'ALREADY_RETURNED' => errAlreadyReturned,
        'ITEM_INACTIVE' => errItemInactive,
        'DUPLICATE_LINE' => errDuplicateLine,
        'EXPIRED_STOCK' => errExpiredStock,
        'TEAM_NOT_EMPTY' => errTeamNotEmpty,
        _ => null,
      };
      if (mapped != null) return mapped;
      if (error is ValidationException) {
        final first = error.fieldErrors.values.firstOrNull;
        return first != null && first.isNotEmpty ? first : errorValidation;
      }
      if (error.message.isNotEmpty) return error.message;
    }
    return errorGeneric;
  }
}
