// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'PPE SMART';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get submit => '提交';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get confirm => '确认';

  @override
  String get edit => '编辑';

  @override
  String get remove => '移除';

  @override
  String get add => '添加';

  @override
  String get clear => '清除';

  @override
  String get all => '全部';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get optional => '选填';

  @override
  String get seeAll => '查看全部';

  @override
  String get done => '完成';

  @override
  String get fieldRequired => '必填';

  @override
  String get invalidNumber => '请输入有效数字';

  @override
  String get offlineBanner => '离线 – 显示已保存的数据';

  @override
  String get pullToRefresh => '下拉刷新';

  @override
  String get errorGeneric => '出现错误，请重试。';

  @override
  String get errorNoInternet => '无法连接服务器，请检查网络。';

  @override
  String get errorTimeout => '服务器响应超时。';

  @override
  String get errorSessionExpired => '登录已过期，请重新登录。';

  @override
  String get errorForbidden => '您没有执行此操作的权限。';

  @override
  String get errorNotFound => '未找到。';

  @override
  String get errorValidation => '请检查填写的内容。';

  @override
  String get errInvalidCredentials => '工号或密码错误。';

  @override
  String get errActiveRequestExists => '该物品已有未完成的申请。';

  @override
  String get errSpecialReasonRequired => '请填写特别审批理由。';

  @override
  String get errSizeRequired => '请为每个物品选择尺码。';

  @override
  String get errInsufficientStock => '库存不足。';

  @override
  String get errSerialMismatch => '扫描的序列号与预留的物品不一致。';

  @override
  String get errSerialRequired => '该物品每件需要一个序列号。';

  @override
  String get errSerialExists => '序列号已存在。';

  @override
  String get errQrInvalid => '二维码无效、已过期或已使用。';

  @override
  String get errQrMismatch => '该二维码属于其他申请。';

  @override
  String get errInvalidStatus => '当前状态下无法执行此操作。';

  @override
  String get errNotApprover => '您不是此步骤的审批人。';

  @override
  String get errReasonRequired => '必须填写理由。';

  @override
  String get errNegativeStock => '库存不能低于零或低于预留数量。';

  @override
  String get errWrongPassword => '当前密码错误。';

  @override
  String get errAlreadyReturned => '该物品已归还。';

  @override
  String get errItemInactive => '该物品已停用。';

  @override
  String get errDuplicateLine => '同一物品重复出现。';

  @override
  String get errExpiredStock => '不能入库已过期的物品。';

  @override
  String get loginSubtitle => '个人防护用品领用系统';

  @override
  String get employeeId => '工号';

  @override
  String get password => '密码';

  @override
  String get signIn => '登录';

  @override
  String get noAccount => '新员工？立即注册';

  @override
  String get registerTitle => '注册';

  @override
  String get displayName => '姓名';

  @override
  String get department => '部门';

  @override
  String get phoneNumber => '电话号码';

  @override
  String get supervisorEmployeeId => '主管工号';

  @override
  String get selectSupervisor => '您的主管';

  @override
  String get searchSupervisor => '点击选择，或输入姓名/工号搜索';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get passwordTooShort => '至少 8 个字符';

  @override
  String get passwordMismatch => '两次密码不一致';

  @override
  String get createAccount => '创建账号';

  @override
  String get haveAccount => '已有账号？登录';

  @override
  String get registerNote => '新账号默认为员工角色，管理员可稍后修改。';

  @override
  String get serverSettings => '服务器设置';

  @override
  String get serverUrl => 'API 地址';

  @override
  String get serverUrlHint => '例如 http://192.168.1.10:8000/api/v1';

  @override
  String get resetDefault => '恢复默认';

  @override
  String get demoAccounts => '演示账号（密码 ChangeMe123!）';

  @override
  String get unlockTitle => '应用已锁定';

  @override
  String get unlockSubtitle => '请验证身份以继续';

  @override
  String get unlock => '解锁';

  @override
  String get biometricReason => '解锁 PPE 管理系统';

  @override
  String get biometricUnavailable => '此设备不支持生物识别验证。';

  @override
  String get navHome => '首页';

  @override
  String get navCatalog => '目录';

  @override
  String get navRequests => '申请';

  @override
  String get navApprovals => '审批';

  @override
  String get navStore => '仓库';

  @override
  String get navInventory => '库存';

  @override
  String get navProfile => '我的';

  @override
  String get notificationsTitle => '通知';

  @override
  String get roleWorker => '员工';

  @override
  String get roleSupervisor => '主管';

  @override
  String get roleStoreKeeper => '仓管员';

  @override
  String get roleEhs => 'EHS 安全员';

  @override
  String get roleAdmin => '管理员';

  @override
  String greeting(String name) {
    return '您好，$name';
  }

  @override
  String get quickActions => '快捷操作';

  @override
  String get actionNewRequest => '新建申请';

  @override
  String get actionMyPpe => '我的 PPE';

  @override
  String get actionScanQr => '扫描二维码';

  @override
  String get actionReceiveStock => '入库';

  @override
  String get actionPurchaseRequests => '采购申请';

  @override
  String get actionAuditLog => '审计日志';

  @override
  String get actionUsers => '用户';

  @override
  String get actionAnalytics => '数据分析';

  @override
  String get actionManageCatalog => '管理目录';

  @override
  String get recentRequests => '最近申请';

  @override
  String get kpiMyOpen => '我的进行中申请';

  @override
  String get kpiReadyForPickup => '待领取';

  @override
  String get kpiMyCompleted => '已领取';

  @override
  String get kpiPendingApproval => '待审批';

  @override
  String get kpiOverdue => '超时（SLA）';

  @override
  String get kpiToPrepare => '待备货';

  @override
  String get kpiOnHold => '等待库存';

  @override
  String get kpiLowStock => '低库存物品';

  @override
  String get kpiCompletedToday => '今日发放';

  @override
  String get kpiOpenRequests => '进行中申请';

  @override
  String get replacementDueTitle => '需要更换';

  @override
  String replacementDueBody(String codes, String count) {
    return '$count 件物品已到使用期限：$codes';
  }

  @override
  String get lowStockTitle => '低库存';

  @override
  String availableOfReorder(String available, String reorder) {
    return '剩余 $available · 补货点 $reorder';
  }

  @override
  String get complianceTitle => '安全合规';

  @override
  String complianceBody(String ok, String total) {
    return '$total 名员工中有 $ok 名的 PPE 在有效期内';
  }

  @override
  String get noRecentRequests => '暂无申请';

  @override
  String pendingSyncBanner(String count) {
    return '$count 个申请等待同步';
  }

  @override
  String get syncNow => '立即同步';

  @override
  String get catalogTitle => 'PPE 目录';

  @override
  String get searchPpe => '搜索名称、编码或尺码';

  @override
  String get inStockOnly => '有库存';

  @override
  String get catHead => '头部';

  @override
  String get catEye => '眼部';

  @override
  String get catHearing => '听力';

  @override
  String get catRespiratory => '呼吸';

  @override
  String get catHand => '手部';

  @override
  String get catFoot => '足部';

  @override
  String get catBody => '身体';

  @override
  String get catFall => '防坠落';

  @override
  String stockCount(String count) {
    return '库存 $count';
  }

  @override
  String get outOfStock => '缺货';

  @override
  String get lowStockBadge => '库存低';

  @override
  String quotaPerRequest(String quota, String unit) {
    return '每次配额 $quota $unit';
  }

  @override
  String lifespanDays(String days) {
    return '使用期限 $days 天';
  }

  @override
  String get sizes => '尺码';

  @override
  String get serialControlled => '序列号管理';

  @override
  String get returnable => '需归还/检查';

  @override
  String get addToRequest => '加入申请';

  @override
  String get inRequest => '已在申请中';

  @override
  String get requestThis => '申请此物品';

  @override
  String get eligibilityTitle => '您的领用资格';

  @override
  String get eligibleNow => '您现在可以申请此物品';

  @override
  String eligibleAt(String date) {
    return '$date 起可正常申请';
  }

  @override
  String lastIssuedAt(String date) {
    return '上次领取 $date';
  }

  @override
  String get specialApprovalNeeded => '需要特别审批（主管 + EHS）';

  @override
  String get editPolicy => '编辑政策';

  @override
  String get quotaLabel => '每次配额';

  @override
  String get lifespanLabel => '使用期限（天）';

  @override
  String get reorderPoint => '补货点';

  @override
  String get activeItem => '在目录中启用';

  @override
  String get changeReason => '修改原因';

  @override
  String get changeReasonHint => '审计记录必填';

  @override
  String get policyUpdated => '政策已更新';

  @override
  String get noItems => '未找到 PPE';

  @override
  String get inactive => '已停用';

  @override
  String get description => '说明';

  @override
  String get unitPiece => '件';

  @override
  String get unitPair => '双';

  @override
  String get unitSet => '套';

  @override
  String get newRequestTitle => '新建申请';

  @override
  String get cartEmpty => '暂无物品，请从目录中添加 PPE。';

  @override
  String get browseCatalog => '浏览目录';

  @override
  String get addItem => '添加物品';

  @override
  String get size => '尺码';

  @override
  String get quantity => '数量';

  @override
  String get reason => '原因';

  @override
  String get reasonDamaged => '损坏';

  @override
  String get reasonLifespanExpired => '到期更换';

  @override
  String get reasonNewEmployee => '新员工';

  @override
  String get reasonLost => '遗失';

  @override
  String get reasonReturnScheduled => '定期更换';

  @override
  String get reasonOther => '其他';

  @override
  String get specialReasonLabel => '特别审批理由';

  @override
  String get specialReasonHint => '请说明需要该物品的原因';

  @override
  String get submitRequest => '提交申请';

  @override
  String requestSubmitted(String no) {
    return '申请 $no 已提交';
  }

  @override
  String get requestQueued => '当前离线，申请已保存，恢复网络后将自动提交。';

  @override
  String quotaExceededLine(String quota) {
    return '超出配额（$quota）– 需特别审批';
  }

  @override
  String lifespanNotExpiredLine(String date) {
    return '$date 前未到更换期 – 需特别审批';
  }

  @override
  String get specialItemLine => '防坠落用品 – 每次都需特别审批';

  @override
  String stockLine(String count) {
    return '库存：$count';
  }

  @override
  String get requestsTitle => '申请';

  @override
  String get tabActive => '进行中';

  @override
  String get tabHistory => '历史';

  @override
  String get scopeMine => '我的';

  @override
  String get scopeTeam => '团队';

  @override
  String get scopeAll => '全部';

  @override
  String get searchRequests => '搜索申请编号或员工';

  @override
  String get noRequests => '暂无申请';

  @override
  String itemsCount(String count) {
    return '$count 件物品';
  }

  @override
  String get statusPending => '待审批';

  @override
  String get statusSpecial => '待特别审批';

  @override
  String get statusApproved => '已批准';

  @override
  String get statusOnHold => '等待库存';

  @override
  String get statusReady => '待领取';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusRejected => '已驳回';

  @override
  String get statusCancelled => '已取消';

  @override
  String get overdue => '已超时';

  @override
  String ageHours(String hours) {
    return '$hours 小时前';
  }

  @override
  String get requestDetail => '申请详情';

  @override
  String get requester => '申请人';

  @override
  String get createdAt => '创建时间';

  @override
  String get items => '物品';

  @override
  String get approvals => '审批记录';

  @override
  String get comments => '留言';

  @override
  String get stockHistory => '库存记录';

  @override
  String get specialReason => '特别理由';

  @override
  String get approve => '批准';

  @override
  String get reject => '驳回';

  @override
  String get requestInfo => '要求补充信息';

  @override
  String get rejectReason => '驳回原因';

  @override
  String get approveNote => '备注（选填）';

  @override
  String get infoQuestion => '需要补充哪些信息？';

  @override
  String get addComment => '写留言';

  @override
  String get send => '发送';

  @override
  String get cancelRequest => '取消申请';

  @override
  String get cancelConfirm => '确定取消此申请？已预留的库存将被释放。';

  @override
  String get prepare => '预留并备货';

  @override
  String get issue => '发放给员工';

  @override
  String get showPickupQr => '显示领取二维码';

  @override
  String get pickupQrTitle => '领取二维码';

  @override
  String get pickupQrHint => '请向仓管员出示此二维码，仅可使用一次。';

  @override
  String expiresAt(String time) {
    return '$time 过期';
  }

  @override
  String get qrExpired => '二维码已过期';

  @override
  String get regenerate => '重新生成';

  @override
  String get serialNumbers => '序列号';

  @override
  String get serialHint => '扫描或输入，每行一个';

  @override
  String expectedSerials(String serials) {
    return '已预留：$serials';
  }

  @override
  String get issueConfirmed => 'PPE 已发放';

  @override
  String get verifiedByQr => '已通过领取二维码验证';

  @override
  String get issueWithoutQr => '不扫码发放（人工核对）';

  @override
  String get returnItem => '接收归还';

  @override
  String get conditionGood => '完好 – 退回库存';

  @override
  String get conditionDamaged => '损坏 – 报废';

  @override
  String get note => '备注';

  @override
  String get returned => '已归还';

  @override
  String returnDue(String date) {
    return '请于 $date 前归还/检查';
  }

  @override
  String get approvalNormal => '主管审批';

  @override
  String get approvalSpecialSupervisor => '特别 – 主管';

  @override
  String get approvalSpecialEhs => '特别 – EHS';

  @override
  String get approvalStoreRelease => '仓库放行';

  @override
  String get decisionApproved => '批准';

  @override
  String get decisionRejected => '驳回';

  @override
  String get infoRequestTag => '要求补充信息';

  @override
  String get eventReceipt => '入库';

  @override
  String get eventReserve => '预留';

  @override
  String get eventIssue => '发放';

  @override
  String get eventReturn => '归还';

  @override
  String get eventAdjustment => '调整';

  @override
  String get eventDamage => '报废';

  @override
  String get progressSubmitted => '已提交';

  @override
  String get progressApproved => '已批准';

  @override
  String get progressReady => '待领取';

  @override
  String get progressReceived => '已领取';

  @override
  String get actionSuccess => '已保存';

  @override
  String get approvalsTitle => '审批收件箱';

  @override
  String get noApprovals => '没有待您审批的申请';

  @override
  String get approvedMsg => '申请已批准';

  @override
  String get rejectedMsg => '申请已驳回';

  @override
  String get infoRequestedMsg => '已向申请人发送问题';

  @override
  String get storeTitle => '仓库发放';

  @override
  String get tabToPrepare => '待备货';

  @override
  String get tabOnHold => '等待库存';

  @override
  String get tabReady => '待领取';

  @override
  String get scanPickupQr => '扫描领取二维码';

  @override
  String get preparedMsg => '已预留库存 – 可领取';

  @override
  String get onHoldMsg => '库存不足 – 申请已暂挂';

  @override
  String get inventoryTitle => '库存';

  @override
  String get available => '可用';

  @override
  String get reserved => '已预留';

  @override
  String get issued30d => '30 天发放';

  @override
  String get needsReorder => '需补货';

  @override
  String expiringLots(String count) {
    return '$count 个批次将在 30 天内过期';
  }

  @override
  String get lotsTitle => '批次与序列号';

  @override
  String get lot => '批次';

  @override
  String get serial => '序列号';

  @override
  String get supplier => '供应商';

  @override
  String get expiry => '有效期';

  @override
  String get expired => '已过期';

  @override
  String get expiresSoon => '即将过期';

  @override
  String get adjustStock => '调整';

  @override
  String get adjustDelta => '变动数量（+ / −）';

  @override
  String get writeOffDamaged => '按损坏报废';

  @override
  String get adjusted => '库存已更新';

  @override
  String get receiveStockTitle => '入库';

  @override
  String get ppeItem => 'PPE 物品';

  @override
  String get lotNumber => '批号';

  @override
  String get expiryDate => '有效期至';

  @override
  String get pickDate => '选择日期';

  @override
  String receivedMsg(String count) {
    return '已入库 $count 件';
  }

  @override
  String get purchaseRequest => '采购申请';

  @override
  String get filterLowStock => '仅低库存';

  @override
  String get stockMovements => '库存变动';

  @override
  String get noLots => '暂无批次';

  @override
  String get purchaseRequestsTitle => '采购申请';

  @override
  String get newPurchaseRequest => '新建采购申请';

  @override
  String get prStatusPending => '待处理';

  @override
  String get prStatusApproved => '已批准';

  @override
  String get prStatusOrdered => '已下单';

  @override
  String get prStatusReceived => '已入库';

  @override
  String get prStatusRejected => '已驳回';

  @override
  String markAs(String status) {
    return '标记为$status';
  }

  @override
  String get receiveIntoStock => '入库';

  @override
  String get noPurchaseRequests => '暂无采购申请';

  @override
  String get scanTitle => '扫描二维码';

  @override
  String get scanHint => '将摄像头对准员工的领取二维码';

  @override
  String get manualEntry => '手动输入编码';

  @override
  String get qrCode => '二维码';

  @override
  String get verify => '验证';

  @override
  String get openRequest => '打开申请';

  @override
  String get cameraUnavailable => '摄像头不可用，请手动输入编码。';

  @override
  String get markAllRead => '全部标为已读';

  @override
  String get noNotifications => '暂无通知';

  @override
  String get markUnread => '标为未读';

  @override
  String get markRead => '标为已读';

  @override
  String notifNewRequisition(String no) {
    return '新申请 $no';
  }

  @override
  String notifApprovalResult(String no, String status) {
    return '$no：$status';
  }

  @override
  String notifReady(String no) {
    return '$no 可以领取了';
  }

  @override
  String notifReorder(String code) {
    return '低库存：$code';
  }

  @override
  String notifInfoRequested(String no) {
    return '关于 $no 的消息';
  }

  @override
  String notifIssued(String no) {
    return '$no 已发放';
  }

  @override
  String notifOnHold(String no) {
    return '$no 等待库存';
  }

  @override
  String get pushReceived => '新通知';

  @override
  String get language => '语言';

  @override
  String get biometricLock => '生物识别锁';

  @override
  String get biometricLockSub => '打开应用时需要指纹/面容验证';

  @override
  String get appearance => '外观';

  @override
  String get themeSystem => '自动';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get changePassword => '修改密码';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get passwordChanged => '密码已修改';

  @override
  String get editProfile => '编辑资料';

  @override
  String get profileSaved => '资料已保存';

  @override
  String get syncQueue => '离线队列';

  @override
  String get syncQueueEmpty => '全部已同步';

  @override
  String get syncPending => '等待中';

  @override
  String get syncSyncing => '发送中…';

  @override
  String get syncFailed => '失败';

  @override
  String syncedCount(String count) {
    return '已发送 $count 个申请';
  }

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirm => '确定在此设备上退出登录？';

  @override
  String get tools => '工具';

  @override
  String get settings => '设置';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get myPpeTitle => '我的 PPE';

  @override
  String get noIssuedItems => '暂无 PPE 领用记录';

  @override
  String issuedOn(String date) {
    return '$date 领取';
  }

  @override
  String replaceFrom(String date) {
    return '$date 起可更换';
  }

  @override
  String get replacementDueNow => '需要更换';

  @override
  String get supervisor => '主管';

  @override
  String get usersTitle => '用户';

  @override
  String get searchUsers => '搜索姓名、工号或部门';

  @override
  String get role => '角色';

  @override
  String get activeUser => '启用';

  @override
  String get userUpdated => '用户已更新';

  @override
  String transferTeam(int count) {
    return '将团队（$count 人）移交给新主管';
  }

  @override
  String transferTeamTo(String name) {
    return '$name 团队的新主管';
  }

  @override
  String transferTeamDone(int count) {
    return '已将 $count 人移交给新主管';
  }

  @override
  String get errTeamNotEmpty => '该主管仍有团队成员，请先将团队移交给其他主管。';

  @override
  String get noOtherSupervisor => '暂无其他在职主管，请先创建或将用户设为主管。';

  @override
  String get supervisorIdOptional => '主管用户 ID（选填）';

  @override
  String get auditTitle => '审计日志';

  @override
  String get searchAudit => '搜索员工或记录 ID';

  @override
  String get noAuditEntries => '暂无审计记录';

  @override
  String get noUsers => '未找到用户';

  @override
  String get analyticsTitle => '数据分析';

  @override
  String get requestPipeline => '申请流程概况';

  @override
  String get stockHealth => '库存健康度';

  @override
  String stockHealthBody(String low, String total) {
    return '$total 个物品中有 $low 个处于或低于补货点';
  }
}
