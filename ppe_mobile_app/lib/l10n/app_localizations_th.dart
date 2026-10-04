// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'PPE SMART';

  @override
  String get ok => 'ตกลง';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get save => 'บันทึก';

  @override
  String get submit => 'ส่ง';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get close => 'ปิด';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get edit => 'แก้ไข';

  @override
  String get remove => 'ลบออก';

  @override
  String get add => 'เพิ่ม';

  @override
  String get clear => 'ล้าง';

  @override
  String get all => 'ทั้งหมด';

  @override
  String get yes => 'ใช่';

  @override
  String get no => 'ไม่';

  @override
  String get optional => 'ไม่บังคับ';

  @override
  String get seeAll => 'ดูทั้งหมด';

  @override
  String get done => 'เสร็จสิ้น';

  @override
  String get fieldRequired => 'จำเป็นต้องกรอก';

  @override
  String get invalidNumber => 'กรุณากรอกตัวเลขให้ถูกต้อง';

  @override
  String get offlineBanner => 'ออฟไลน์ – กำลังแสดงข้อมูลที่บันทึกไว้';

  @override
  String get pullToRefresh => 'ดึงลงเพื่อรีเฟรช';

  @override
  String get errorGeneric => 'เกิดข้อผิดพลาด กรุณาลองใหม่';

  @override
  String get errorNoInternet =>
      'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';

  @override
  String get errorTimeout => 'เซิร์ฟเวอร์ตอบสนองช้าเกินไป';

  @override
  String get errorSessionExpired => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง';

  @override
  String get errorForbidden => 'คุณไม่มีสิทธิ์ทำรายการนี้';

  @override
  String get errorNotFound => 'ไม่พบข้อมูล';

  @override
  String get errorValidation => 'กรุณาตรวจสอบข้อมูลที่กรอก';

  @override
  String get errInvalidCredentials => 'รหัสพนักงานหรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get errActiveRequestExists =>
      'คุณมีคำขอเบิกรายการนี้ที่ยังไม่เสร็จอยู่แล้ว';

  @override
  String get errSpecialReasonRequired =>
      'กรุณาระบุเหตุผลประกอบการขออนุมัติพิเศษ';

  @override
  String get errSizeRequired => 'กรุณาเลือกขนาดให้ครบทุกรายการ';

  @override
  String get errInsufficientStock => 'สต็อกไม่เพียงพอ';

  @override
  String get errSerialMismatch => 'Serial ที่สแกนไม่ตรงกับรายการที่จองไว้';

  @override
  String get errSerialRequired =>
      'รายการนี้ต้องระบุ Serial 1 หมายเลขต่อ 1 ชิ้น';

  @override
  String get errSerialExists => 'มี Serial นี้อยู่ในระบบแล้ว';

  @override
  String get errQrInvalid => 'QR ไม่ถูกต้อง หมดอายุ หรือถูกใช้ไปแล้ว';

  @override
  String get errQrMismatch => 'QR นี้เป็นของคำขออื่น';

  @override
  String get errInvalidStatus => 'ไม่สามารถทำรายการนี้ในสถานะปัจจุบันได้';

  @override
  String get errNotApprover => 'คุณไม่ใช่ผู้อนุมัติในขั้นตอนนี้';

  @override
  String get errReasonRequired => 'กรุณาระบุเหตุผล';

  @override
  String get errNegativeStock => 'สต็อกต้องไม่ติดลบหรือน้อยกว่ายอดที่จองไว้';

  @override
  String get errWrongPassword => 'รหัสผ่านปัจจุบันไม่ถูกต้อง';

  @override
  String get errAlreadyReturned => 'รายการนี้คืนแล้ว';

  @override
  String get errItemInactive => 'รายการนี้ยกเลิกการใช้งานแล้ว';

  @override
  String get errDuplicateLine => 'มีรายการซ้ำในคำขอ';

  @override
  String get errExpiredStock => 'ไม่สามารถรับของที่หมดอายุแล้วเข้าคลัง';

  @override
  String get loginSubtitle => 'ระบบเบิกจ่ายอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล';

  @override
  String get employeeId => 'รหัสพนักงาน';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get signIn => 'เข้าสู่ระบบ';

  @override
  String get noAccount => 'พนักงานใหม่? ลงทะเบียน';

  @override
  String get registerTitle => 'ลงทะเบียน';

  @override
  String get displayName => 'ชื่อ-นามสกุล';

  @override
  String get department => 'แผนก';

  @override
  String get phoneNumber => 'เบอร์โทรศัพท์';

  @override
  String get supervisorEmployeeId => 'รหัสพนักงานของหัวหน้างาน';

  @override
  String get selectSupervisor => 'หัวหน้างานของคุณ';

  @override
  String get searchSupervisor => 'แตะเพื่อเลือก หรือพิมพ์ชื่อ/รหัสเพื่อค้นหา';

  @override
  String get confirmPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get passwordTooShort => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get passwordMismatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get createAccount => 'สร้างบัญชี';

  @override
  String get haveAccount => 'มีบัญชีแล้ว? เข้าสู่ระบบ';

  @override
  String get registerNote =>
      'บัญชีใหม่จะได้รับสิทธิ์พนักงาน (Worker) ผู้ดูแลระบบสามารถเปลี่ยนสิทธิ์ภายหลังได้';

  @override
  String get serverSettings => 'ตั้งค่าเซิร์ฟเวอร์';

  @override
  String get serverUrl => 'ที่อยู่ API';

  @override
  String get serverUrlHint => 'เช่น http://192.168.1.10:8000/api/v1';

  @override
  String get resetDefault => 'คืนค่าเริ่มต้น';

  @override
  String get demoAccounts => 'บัญชีทดลอง (รหัสผ่าน ChangeMe123!)';

  @override
  String get unlockTitle => 'แอปถูกล็อก';

  @override
  String get unlockSubtitle => 'ยืนยันตัวตนเพื่อใช้งานต่อ';

  @override
  String get unlock => 'ปลดล็อก';

  @override
  String get biometricReason => 'ปลดล็อกระบบเบิก PPE';

  @override
  String get biometricUnavailable =>
      'อุปกรณ์นี้ไม่รองรับการยืนยันตัวตนด้วยไบโอเมตริก';

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navCatalog => 'แคตตาล็อก';

  @override
  String get navRequests => 'คำขอเบิก';

  @override
  String get navApprovals => 'อนุมัติ';

  @override
  String get navStore => 'คลัง';

  @override
  String get navInventory => 'สต็อก';

  @override
  String get navProfile => 'โปรไฟล์';

  @override
  String get notificationsTitle => 'การแจ้งเตือน';

  @override
  String get roleWorker => 'พนักงาน';

  @override
  String get roleSupervisor => 'หัวหน้างาน';

  @override
  String get roleStoreKeeper => 'เจ้าหน้าที่คลัง';

  @override
  String get roleEhs => 'จป. / EHS';

  @override
  String get roleAdmin => 'ผู้ดูแลระบบ';

  @override
  String greeting(String name) {
    return 'สวัสดี $name';
  }

  @override
  String get quickActions => 'เมนูลัด';

  @override
  String get actionNewRequest => 'เบิก PPE';

  @override
  String get actionMyPpe => 'PPE ของฉัน';

  @override
  String get actionScanQr => 'สแกน QR';

  @override
  String get actionReceiveStock => 'รับของเข้าคลัง';

  @override
  String get actionPurchaseRequests => 'ขอสั่งซื้อ';

  @override
  String get actionAuditLog => 'ประวัติการใช้งาน';

  @override
  String get actionUsers => 'ผู้ใช้งาน';

  @override
  String get actionAnalytics => 'สรุปภาพรวม';

  @override
  String get actionManageCatalog => 'จัดการรายการ PPE';

  @override
  String get recentRequests => 'คำขอล่าสุด';

  @override
  String get kpiMyOpen => 'คำขอที่กำลังดำเนินการ';

  @override
  String get kpiReadyForPickup => 'พร้อมรับของ';

  @override
  String get kpiMyCompleted => 'รับแล้ว';

  @override
  String get kpiPendingApproval => 'รออนุมัติ';

  @override
  String get kpiOverdue => 'เกินกำหนด (SLA)';

  @override
  String get kpiToPrepare => 'รอจัดของ';

  @override
  String get kpiOnHold => 'รอสต็อก';

  @override
  String get kpiLowStock => 'รายการสต็อกต่ำ';

  @override
  String get kpiCompletedToday => 'จ่ายวันนี้';

  @override
  String get kpiOpenRequests => 'คำขอที่เปิดอยู่';

  @override
  String get replacementDueTitle => 'ถึงกำหนดเปลี่ยน';

  @override
  String replacementDueBody(String codes, String count) {
    return '$count รายการครบอายุการใช้งาน: $codes';
  }

  @override
  String get lowStockTitle => 'สต็อกต่ำ';

  @override
  String availableOfReorder(String available, String reorder) {
    return 'เหลือ $available · จุดสั่งซื้อ $reorder';
  }

  @override
  String get complianceTitle => 'การปฏิบัติตามความปลอดภัย';

  @override
  String complianceBody(String ok, String total) {
    return 'พนักงาน $ok จาก $total คนมี PPE ที่ยังไม่หมดอายุ';
  }

  @override
  String get noRecentRequests => 'ยังไม่มีคำขอ';

  @override
  String pendingSyncBanner(String count) {
    return 'มี $count คำขอรอส่ง';
  }

  @override
  String get syncNow => 'ส่งตอนนี้';

  @override
  String get catalogTitle => 'รายการ PPE';

  @override
  String get searchPpe => 'ค้นหาชื่อ รหัส หรือขนาด';

  @override
  String get inStockOnly => 'มีของ';

  @override
  String get catHead => 'ศีรษะ';

  @override
  String get catEye => 'ดวงตา';

  @override
  String get catHearing => 'การได้ยิน';

  @override
  String get catRespiratory => 'ระบบหายใจ';

  @override
  String get catHand => 'มือ';

  @override
  String get catFoot => 'เท้า';

  @override
  String get catBody => 'ลำตัว';

  @override
  String get catFall => 'ป้องกันการตก';

  @override
  String stockCount(String count) {
    return 'คงเหลือ $count';
  }

  @override
  String get outOfStock => 'ของหมด';

  @override
  String get lowStockBadge => 'ใกล้หมด';

  @override
  String quotaPerRequest(String quota, String unit) {
    return 'โควต้า $quota $unit / ครั้ง';
  }

  @override
  String lifespanDays(String days) {
    return 'อายุการใช้งาน $days วัน';
  }

  @override
  String get sizes => 'ขนาด';

  @override
  String get serialControlled => 'ควบคุม Serial';

  @override
  String get returnable => 'ต้องส่งคืน/ตรวจสภาพ';

  @override
  String get addToRequest => 'เพิ่มในคำขอ';

  @override
  String get inRequest => 'อยู่ในคำขอแล้ว';

  @override
  String get requestThis => 'เบิกรายการนี้';

  @override
  String get eligibilityTitle => 'สิทธิ์การเบิกของคุณ';

  @override
  String get eligibleNow => 'คุณสามารถเบิกรายการนี้ได้ทันที';

  @override
  String eligibleAt(String date) {
    return 'เบิกตามปกติได้ตั้งแต่ $date';
  }

  @override
  String lastIssuedAt(String date) {
    return 'รับครั้งล่าสุด $date';
  }

  @override
  String get specialApprovalNeeded =>
      'ต้องได้รับอนุมัติพิเศษ (หัวหน้างาน + จป.)';

  @override
  String get editPolicy => 'แก้ไขนโยบาย';

  @override
  String get quotaLabel => 'โควต้าต่อครั้ง';

  @override
  String get lifespanLabel => 'อายุการใช้งาน (วัน)';

  @override
  String get reorderPoint => 'จุดสั่งซื้อ';

  @override
  String get activeItem => 'เปิดใช้งานในแคตตาล็อก';

  @override
  String get changeReason => 'เหตุผลในการแก้ไข';

  @override
  String get changeReasonHint => 'จำเป็นสำหรับบันทึก Audit';

  @override
  String get policyUpdated => 'อัปเดตนโยบายแล้ว';

  @override
  String get noItems => 'ไม่พบรายการ PPE';

  @override
  String get inactive => 'ปิดใช้งาน';

  @override
  String get description => 'รายละเอียด';

  @override
  String get unitPiece => 'ชิ้น';

  @override
  String get unitPair => 'คู่';

  @override
  String get unitSet => 'ชุด';

  @override
  String get newRequestTitle => 'สร้างคำขอเบิก';

  @override
  String get cartEmpty => 'ยังไม่มีรายการ เพิ่ม PPE จากแคตตาล็อก';

  @override
  String get browseCatalog => 'เลือกจากแคตตาล็อก';

  @override
  String get addItem => 'เพิ่มรายการ';

  @override
  String get size => 'ขนาด';

  @override
  String get quantity => 'จำนวน';

  @override
  String get reason => 'เหตุผล';

  @override
  String get reasonDamaged => 'ชำรุด';

  @override
  String get reasonLifespanExpired => 'ครบอายุการใช้งาน';

  @override
  String get reasonNewEmployee => 'พนักงานใหม่';

  @override
  String get reasonLost => 'สูญหาย';

  @override
  String get reasonReturnScheduled => 'เปลี่ยนตามรอบ';

  @override
  String get reasonOther => 'อื่น ๆ';

  @override
  String get specialReasonLabel => 'เหตุผลประกอบการขออนุมัติพิเศษ';

  @override
  String get specialReasonHint => 'อธิบายเหตุผลที่ต้องใช้อุปกรณ์นี้';

  @override
  String get submitRequest => 'ส่งคำขอ';

  @override
  String requestSubmitted(String no) {
    return 'ส่งคำขอ $no แล้ว';
  }

  @override
  String get requestQueued =>
      'ขณะนี้ออฟไลน์ ระบบบันทึกคำขอไว้และจะส่งให้อัตโนมัติ';

  @override
  String quotaExceededLine(String quota) {
    return 'เกินโควต้า ($quota) – ต้องอนุมัติพิเศษ';
  }

  @override
  String lifespanNotExpiredLine(String date) {
    return 'ยังไม่ถึงกำหนดเปลี่ยนจนถึง $date – ต้องอนุมัติพิเศษ';
  }

  @override
  String get specialItemLine => 'อุปกรณ์กันตก – ต้องอนุมัติพิเศษทุกครั้ง';

  @override
  String stockLine(String count) {
    return 'คงเหลือ: $count';
  }

  @override
  String get requestsTitle => 'คำขอเบิก';

  @override
  String get tabActive => 'กำลังดำเนินการ';

  @override
  String get tabHistory => 'ประวัติ';

  @override
  String get scopeMine => 'ของฉัน';

  @override
  String get scopeTeam => 'ทีม';

  @override
  String get scopeAll => 'ทั้งหมด';

  @override
  String get searchRequests => 'ค้นหาเลขที่คำขอหรือพนักงาน';

  @override
  String get noRequests => 'ไม่มีคำขอ';

  @override
  String itemsCount(String count) {
    return '$count รายการ';
  }

  @override
  String get statusPending => 'รออนุมัติ';

  @override
  String get statusSpecial => 'รออนุมัติพิเศษ';

  @override
  String get statusApproved => 'อนุมัติแล้ว';

  @override
  String get statusOnHold => 'รอสต็อก';

  @override
  String get statusReady => 'พร้อมรับของ';

  @override
  String get statusCompleted => 'รับของแล้ว';

  @override
  String get statusRejected => 'ไม่อนุมัติ';

  @override
  String get statusCancelled => 'ยกเลิก';

  @override
  String get overdue => 'เกินกำหนด';

  @override
  String ageHours(String hours) {
    return '$hours ชม. ที่แล้ว';
  }

  @override
  String get requestDetail => 'รายละเอียดคำขอ';

  @override
  String get requester => 'ผู้ขอเบิก';

  @override
  String get createdAt => 'วันที่สร้าง';

  @override
  String get items => 'รายการ';

  @override
  String get approvals => 'การอนุมัติ';

  @override
  String get comments => 'ความคิดเห็น';

  @override
  String get stockHistory => 'ประวัติการเคลื่อนไหวสต็อก';

  @override
  String get specialReason => 'เหตุผลพิเศษ';

  @override
  String get approve => 'อนุมัติ';

  @override
  String get reject => 'ไม่อนุมัติ';

  @override
  String get requestInfo => 'ขอข้อมูลเพิ่ม';

  @override
  String get rejectReason => 'เหตุผลที่ไม่อนุมัติ';

  @override
  String get approveNote => 'หมายเหตุ (ไม่บังคับ)';

  @override
  String get infoQuestion => 'ต้องการข้อมูลอะไรเพิ่มเติม?';

  @override
  String get addComment => 'เขียนความคิดเห็น';

  @override
  String get send => 'ส่ง';

  @override
  String get cancelRequest => 'ยกเลิกคำขอ';

  @override
  String get cancelConfirm => 'ยืนยันยกเลิกคำขอนี้? สต็อกที่จองไว้จะถูกคืน';

  @override
  String get prepare => 'จองและจัดของ';

  @override
  String get issue => 'จ่ายของให้พนักงาน';

  @override
  String get showPickupQr => 'แสดง QR รับของ';

  @override
  String get pickupQrTitle => 'QR สำหรับรับของ';

  @override
  String get pickupQrHint => 'แสดงรหัสนี้ให้เจ้าหน้าที่คลัง ใช้ได้ครั้งเดียว';

  @override
  String expiresAt(String time) {
    return 'หมดอายุเวลา $time';
  }

  @override
  String get qrExpired => 'รหัสหมดอายุแล้ว';

  @override
  String get regenerate => 'สร้างรหัสใหม่';

  @override
  String get serialNumbers => 'หมายเลข Serial';

  @override
  String get serialHint => 'สแกนหรือพิมพ์ บรรทัดละ 1 หมายเลข';

  @override
  String expectedSerials(String serials) {
    return 'ที่จองไว้: $serials';
  }

  @override
  String get issueConfirmed => 'จ่าย PPE เรียบร้อย';

  @override
  String get verifiedByQr => 'ยืนยันด้วย QR รับของแล้ว';

  @override
  String get issueWithoutQr => 'จ่ายโดยไม่สแกน QR (ตรวจสอบด้วยตนเอง)';

  @override
  String get returnItem => 'รับคืน';

  @override
  String get conditionGood => 'สภาพดี – คืนเข้าสต็อก';

  @override
  String get conditionDamaged => 'ชำรุด – ตัดจำหน่าย';

  @override
  String get note => 'หมายเหตุ';

  @override
  String get returned => 'คืนแล้ว';

  @override
  String returnDue(String date) {
    return 'ส่งคืน/ตรวจสภาพภายใน $date';
  }

  @override
  String get approvalNormal => 'หัวหน้างานอนุมัติ';

  @override
  String get approvalSpecialSupervisor => 'อนุมัติพิเศษ – หัวหน้างาน';

  @override
  String get approvalSpecialEhs => 'อนุมัติพิเศษ – จป.';

  @override
  String get approvalStoreRelease => 'คลังอนุมัติจ่าย';

  @override
  String get decisionApproved => 'อนุมัติ';

  @override
  String get decisionRejected => 'ไม่อนุมัติ';

  @override
  String get infoRequestTag => 'ขอข้อมูลเพิ่ม';

  @override
  String get eventReceipt => 'รับเข้า';

  @override
  String get eventReserve => 'จอง';

  @override
  String get eventIssue => 'จ่ายออก';

  @override
  String get eventReturn => 'รับคืน';

  @override
  String get eventAdjustment => 'ปรับยอด';

  @override
  String get eventDamage => 'ตัดชำรุด';

  @override
  String get progressSubmitted => 'ส่งคำขอ';

  @override
  String get progressApproved => 'อนุมัติ';

  @override
  String get progressReady => 'พร้อมรับ';

  @override
  String get progressReceived => 'รับของ';

  @override
  String get actionSuccess => 'บันทึกแล้ว';

  @override
  String get approvalsTitle => 'รายการรออนุมัติ';

  @override
  String get noApprovals => 'ไม่มีรายการรออนุมัติ';

  @override
  String get approvedMsg => 'อนุมัติคำขอแล้ว';

  @override
  String get rejectedMsg => 'ไม่อนุมัติคำขอแล้ว';

  @override
  String get infoRequestedMsg => 'ส่งคำถามถึงผู้ขอเบิกแล้ว';

  @override
  String get storeTitle => 'งานจ่ายของคลัง';

  @override
  String get tabToPrepare => 'รอจัดของ';

  @override
  String get tabOnHold => 'รอสต็อก';

  @override
  String get tabReady => 'พร้อมรับ';

  @override
  String get scanPickupQr => 'สแกน QR รับของ';

  @override
  String get preparedMsg => 'จองสต็อกแล้ว – พร้อมให้รับของ';

  @override
  String get onHoldMsg => 'สต็อกไม่พอ – พักคำขอไว้ก่อน';

  @override
  String get inventoryTitle => 'สต็อกคงคลัง';

  @override
  String get available => 'พร้อมจ่าย';

  @override
  String get reserved => 'จองแล้ว';

  @override
  String get issued30d => 'จ่าย 30 วัน';

  @override
  String get needsReorder => 'ควรสั่งซื้อ';

  @override
  String expiringLots(String count) {
    return '$count ล็อตจะหมดอายุภายใน 30 วัน';
  }

  @override
  String get lotsTitle => 'ล็อตและ Serial';

  @override
  String get lot => 'ล็อต';

  @override
  String get serial => 'Serial';

  @override
  String get supplier => 'ผู้จำหน่าย';

  @override
  String get expiry => 'วันหมดอายุ';

  @override
  String get expired => 'หมดอายุ';

  @override
  String get expiresSoon => 'ใกล้หมดอายุ';

  @override
  String get adjustStock => 'ปรับยอด';

  @override
  String get adjustDelta => 'จำนวนที่เปลี่ยน (+ / −)';

  @override
  String get writeOffDamaged => 'ตัดจำหน่ายเนื่องจากชำรุด';

  @override
  String get adjusted => 'อัปเดตสต็อกแล้ว';

  @override
  String get receiveStockTitle => 'รับของเข้าคลัง';

  @override
  String get ppeItem => 'รายการ PPE';

  @override
  String get lotNumber => 'เลขล็อต';

  @override
  String get expiryDate => 'วันหมดอายุ';

  @override
  String get pickDate => 'เลือกวันที่';

  @override
  String receivedMsg(String count) {
    return 'รับเข้า $count หน่วยแล้ว';
  }

  @override
  String get purchaseRequest => 'คำขอสั่งซื้อ';

  @override
  String get filterLowStock => 'เฉพาะสต็อกต่ำ';

  @override
  String get stockMovements => 'การเคลื่อนไหว';

  @override
  String get noLots => 'ไม่มีล็อต';

  @override
  String get purchaseRequestsTitle => 'คำขอสั่งซื้อ';

  @override
  String get newPurchaseRequest => 'สร้างคำขอสั่งซื้อ';

  @override
  String get prStatusPending => 'รอพิจารณา';

  @override
  String get prStatusApproved => 'อนุมัติ';

  @override
  String get prStatusOrdered => 'สั่งซื้อแล้ว';

  @override
  String get prStatusReceived => 'รับเข้าคลังแล้ว';

  @override
  String get prStatusRejected => 'ไม่อนุมัติ';

  @override
  String markAs(String status) {
    return 'เปลี่ยนเป็น $status';
  }

  @override
  String get receiveIntoStock => 'รับเข้าคลัง';

  @override
  String get noPurchaseRequests => 'ไม่มีคำขอสั่งซื้อ';

  @override
  String get scanTitle => 'สแกน QR';

  @override
  String get scanHint => 'หันกล้องไปที่ QR รับของของพนักงาน';

  @override
  String get manualEntry => 'กรอกรหัสเอง';

  @override
  String get qrCode => 'รหัส QR';

  @override
  String get verify => 'ตรวจสอบ';

  @override
  String get openRequest => 'เปิดคำขอ';

  @override
  String get cameraUnavailable => 'ใช้กล้องไม่ได้ กรุณากรอกรหัสเอง';

  @override
  String get markAllRead => 'อ่านทั้งหมดแล้ว';

  @override
  String get noNotifications => 'ไม่มีการแจ้งเตือน';

  @override
  String get markUnread => 'ทำเครื่องหมายว่ายังไม่อ่าน';

  @override
  String get markRead => 'ทำเครื่องหมายว่าอ่านแล้ว';

  @override
  String notifNewRequisition(String no) {
    return 'คำขอใหม่ $no';
  }

  @override
  String notifApprovalResult(String no, String status) {
    return '$no: $status';
  }

  @override
  String notifReady(String no) {
    return '$no พร้อมให้รับของ';
  }

  @override
  String notifReorder(String code) {
    return 'สต็อกต่ำ: $code';
  }

  @override
  String notifInfoRequested(String no) {
    return 'ข้อความเกี่ยวกับ $no';
  }

  @override
  String notifIssued(String no) {
    return 'จ่ายของ $no แล้ว';
  }

  @override
  String notifOnHold(String no) {
    return '$no รอสต็อก';
  }

  @override
  String get pushReceived => 'มีการแจ้งเตือนใหม่';

  @override
  String get language => 'ภาษา';

  @override
  String get biometricLock => 'ล็อกด้วยไบโอเมตริก';

  @override
  String get biometricLockSub => 'ต้องสแกนลายนิ้วมือ/ใบหน้าเมื่อเปิดแอป';

  @override
  String get appearance => 'ธีม';

  @override
  String get themeSystem => 'อัตโนมัติ';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get changePassword => 'เปลี่ยนรหัสผ่าน';

  @override
  String get currentPassword => 'รหัสผ่านปัจจุบัน';

  @override
  String get newPassword => 'รหัสผ่านใหม่';

  @override
  String get passwordChanged => 'เปลี่ยนรหัสผ่านแล้ว';

  @override
  String get editProfile => 'แก้ไขโปรไฟล์';

  @override
  String get profileSaved => 'บันทึกโปรไฟล์แล้ว';

  @override
  String get syncQueue => 'คิวรอส่ง (ออฟไลน์)';

  @override
  String get syncQueueEmpty => 'ส่งข้อมูลครบแล้ว';

  @override
  String get syncPending => 'รอส่ง';

  @override
  String get syncSyncing => 'กำลังส่ง…';

  @override
  String get syncFailed => 'ส่งไม่สำเร็จ';

  @override
  String syncedCount(String count) {
    return 'ส่งแล้ว $count คำขอ';
  }

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get logoutConfirm => 'ออกจากระบบบนอุปกรณ์นี้?';

  @override
  String get tools => 'เครื่องมือ';

  @override
  String get settings => 'ตั้งค่า';

  @override
  String version(String version) {
    return 'เวอร์ชัน $version';
  }

  @override
  String get myPpeTitle => 'PPE ของฉัน';

  @override
  String get noIssuedItems => 'ยังไม่มีประวัติการรับ PPE';

  @override
  String issuedOn(String date) {
    return 'รับเมื่อ $date';
  }

  @override
  String replaceFrom(String date) {
    return 'เปลี่ยนได้ตั้งแต่ $date';
  }

  @override
  String get replacementDueNow => 'ถึงกำหนดเปลี่ยน';

  @override
  String get supervisor => 'หัวหน้างาน';

  @override
  String get usersTitle => 'ผู้ใช้งาน';

  @override
  String get searchUsers => 'ค้นหาชื่อ รหัส หรือแผนก';

  @override
  String get role => 'สิทธิ์การใช้งาน';

  @override
  String get activeUser => 'ใช้งานอยู่';

  @override
  String get userUpdated => 'อัปเดตผู้ใช้แล้ว';

  @override
  String transferTeam(int count) {
    return 'ย้ายลูกทีม ($count คน) ไปหัวหน้าใหม่';
  }

  @override
  String transferTeamTo(String name) {
    return 'หัวหน้าใหม่ของทีม $name';
  }

  @override
  String transferTeamDone(int count) {
    return 'ย้าย $count คนไปหัวหน้าใหม่แล้ว';
  }

  @override
  String get errTeamNotEmpty =>
      'หัวหน้างานคนนี้ยังมีลูกทีมอยู่ ให้ย้ายลูกทีมไปหัวหน้าคนอื่นก่อน';

  @override
  String get noOtherSupervisor =>
      'ยังไม่มีหัวหน้างานคนอื่นที่ใช้งานอยู่ ให้สร้างหรือเปลี่ยนสิทธิ์ผู้ใช้เป็นหัวหน้างานก่อน';

  @override
  String get supervisorIdOptional => 'รหัสผู้ใช้ของหัวหน้างาน (ไม่บังคับ)';

  @override
  String get auditTitle => 'ประวัติการใช้งานระบบ';

  @override
  String get searchAudit => 'ค้นหาพนักงานหรือรหัสรายการ';

  @override
  String get noAuditEntries => 'ไม่มีประวัติ';

  @override
  String get noUsers => 'ไม่พบผู้ใช้';

  @override
  String get analyticsTitle => 'สรุปภาพรวม';

  @override
  String get requestPipeline => 'สถานะคำขอทั้งหมด';

  @override
  String get stockHealth => 'สุขภาพสต็อก';

  @override
  String stockHealthBody(String low, String total) {
    return '$low จาก $total รายการต่ำกว่าจุดสั่งซื้อ';
  }
}
