from datetime import timedelta

from django.db.models import F, Prefetch, Q, Sum
from django.db.models.functions import Coalesce
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from .auth import EmployeeIdTokenSerializer
from .exceptions import BusinessRuleError
from .models import (
    AuditLog,
    DeviceToken,
    Notification,
    PpeItem,
    PpePurchaseRequest,
    PurchaseRequestStatus,
    Requisition,
    RequisitionItem,
    RequisitionStatus,
    Role,
    SerialStatus,
    StockEvent,
    StockLot,
    User,
)
from .permissions import CanManageMasterDataOrReadOnly, IsAdmin, IsEhsOrAdmin, IsStoreOrHigher, IsSupervisorOrHigher
from .serializers import (
    AdjustStockSerializer,
    ApprovalInputSerializer,
    AuditLogSerializer,
    ChangePasswordSerializer,
    CommentInputSerializer,
    CommentSerializer,
    CreateRequisitionSerializer,
    DeviceTokenSerializer,
    EligibilitySerializer,
    IssueInputSerializer,
    NotificationSerializer,
    PpeItemSerializer,
    PpeItemWriteSerializer,
    PurchaseRequestSerializer,
    RegisterSerializer,
    RequisitionDetailSerializer,
    RequisitionSerializer,
    ReturnInputSerializer,
    ReceiveStockSerializer,
    StockEventSerializer,
    StockLotSerializer,
    UserAdminSerializer,
    UserSerializer,
)
from .services import (
    STORE_ROLES,
    add_comment,
    adjust_lot,
    approval_inbox,
    approve_requisition,
    audit,
    available_stock,
    cancel_requisition,
    create_qr_challenge,
    create_requisition,
    dashboard_summary,
    evaluate_line,
    issue_requisition,
    notify_users,
    receive_stock,
    replacement_due,
    reserve_and_prepare,
    resolve_qr,
    return_item,
    visible_requisitions,
)


class StandardPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = 'page_size'
    max_page_size = 200


def _tokens_for(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {'refresh': str(refresh), 'access': str(refresh.access_token), 'user': UserSerializer(user).data}


# ---------------------------------------------------------------------------
# Auth & profile
# ---------------------------------------------------------------------------

class EmployeeIdTokenView(APIView):
    """Login with Employee ID + password -> JWT pair + user profile."""
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = EmployeeIdTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user_obj']
        user.last_login = timezone.now()
        user.save(update_fields=['last_login'])
        audit(actor=user, action='LOGIN', entity='User', entity_id=user.pk)
        return Response(_tokens_for(user))


class RegisterView(APIView):
    """Self-registration for workers. New accounts always get the WORKER role."""
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        audit(actor=user, action='REGISTER', entity='User', entity_id=user.pk)
        return Response(_tokens_for(user), status=status.HTTP_201_CREATED)


class LogoutView(APIView):
    """Revokes the refresh token and deactivates the device push token (device revoke)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh = request.data.get('refresh')
        if refresh:
            try:
                RefreshToken(refresh).blacklist()
            except TokenError:
                pass
        device_token = request.data.get('device_token')
        if device_token:
            DeviceToken.objects.filter(token=device_token, user=request.user).update(active=False)
        audit(actor=request.user, action='LOGOUT', entity='User', entity_id=request.user.pk)
        return Response({'success': True})


class UserMeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if not request.user.check_password(serializer.validated_data['current_password']):
            raise BusinessRuleError('WRONG_PASSWORD', 'Current password is incorrect.', 400)
        request.user.set_password(serializer.validated_data['new_password'])
        request.user.save(update_fields=['password'])
        audit(actor=request.user, action='CHANGE_PASSWORD', entity='User', entity_id=request.user.pk)
        return Response({'success': True})


class MyIssuedItemsView(APIView):
    """PPE currently held by the user with replacement due dates."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user_id = request.query_params.get('user_id')
        user = request.user
        if user_id and request.user.role in [Role.SUPERVISOR, *STORE_ROLES]:
            user = get_object_or_404(User, pk=user_id)
        lines = (RequisitionItem.objects.filter(requisition__requester=user, requisition__status=RequisitionStatus.COMPLETED, is_returned=False)
                 .select_related('ppe_item', 'requisition').prefetch_related('ppe_item__translations').order_by('-requisition__updated_at'))
        from .serializers import RequisitionItemSerializer
        data = []
        for line in lines:
            row = RequisitionItemSerializer(line, context={'request': request}).data
            row['request_no'] = line.requisition.request_no
            row['requisition_id'] = line.requisition_id
            row['issued_at'] = line.requisition.updated_at
            lifespan = line.ppe_item.lifespan_days
            row['replace_at'] = line.requisition.updated_at + timedelta(days=lifespan) if lifespan else None
            data.append(row)
        return Response({'items': data, 'replacement_due': replacement_due(user)})


class UserListView(generics.ListAPIView):
    permission_classes = [IsSupervisorOrHigher]
    serializer_class = UserAdminSerializer
    pagination_class = StandardPagination

    def get_queryset(self):
        queryset = User.objects.select_related('supervisor').order_by('employee_id')
        if self.request.user.role == Role.SUPERVISOR:
            queryset = queryset.filter(supervisor=self.request.user)
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(Q(employee_id__icontains=search) | Q(display_name__icontains=search) | Q(department__icontains=search))
        role = self.request.query_params.get('role')
        if role:
            queryset = queryset.filter(role=role)
        return queryset


class UserDetailView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAdmin]
    serializer_class = UserAdminSerializer
    queryset = User.objects.all()

    def perform_update(self, serializer):
        before = {'role': serializer.instance.role, 'is_active': serializer.instance.is_active, 'supervisor': serializer.instance.supervisor_id}
        user = serializer.save()
        audit(actor=self.request.user, action='UPDATE_USER', entity='User', entity_id=user.pk, before=before,
              after={'role': user.role, 'is_active': user.is_active, 'supervisor': user.supervisor_id})


class DeviceTokenView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        device, _ = DeviceToken.objects.update_or_create(
            token=serializer.validated_data['token'],
            defaults={'user': request.user, 'platform': serializer.validated_data['platform'], 'active': True, 'last_seen_at': timezone.now()},
        )
        return Response(DeviceTokenSerializer(device).data, status=status.HTTP_201_CREATED)


# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------

class NotificationListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer
    pagination_class = StandardPagination

    def get_queryset(self):
        queryset = Notification.objects.filter(recipient=self.request.user).order_by('-created_at')
        if self.request.query_params.get('unread') == '1':
            queryset = queryset.filter(read_at__isnull=True)
        return queryset

    def list(self, request, *args, **kwargs):
        response = super().list(request, *args, **kwargs)
        response.data['unread_count'] = Notification.objects.filter(recipient=request.user, read_at__isnull=True).count()
        return response


class NotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        notification = get_object_or_404(Notification, pk=pk, recipient=request.user)
        notification.read_at = None if request.data.get('unread') else timezone.now()
        notification.save(update_fields=['read_at'])
        return Response(NotificationSerializer(notification).data)


class NotificationReadAllView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        updated = Notification.objects.filter(recipient=request.user, read_at__isnull=True).update(read_at=timezone.now())
        return Response({'updated': updated})


class NotificationUnreadCountView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({'unread_count': Notification.objects.filter(recipient=request.user, read_at__isnull=True).count()})


# ---------------------------------------------------------------------------
# Catalog
# ---------------------------------------------------------------------------

def catalog_queryset():
    now = timezone.now()
    usable = Q(stock_lots__serial_status=SerialStatus.AVAILABLE) & (Q(stock_lots__expiry_at__isnull=True) | Q(stock_lots__expiry_at__gt=now))
    return PpeItem.objects.prefetch_related('translations').annotate(
        stock=Coalesce(Sum(F('stock_lots__quantity') - F('stock_lots__reserved_quantity'), filter=usable), 0),
        reserved=Coalesce(Sum('stock_lots__reserved_quantity'), 0),
    ).order_by('category', 'code')


class PpeCatalogView(generics.ListCreateAPIView):
    permission_classes = [CanManageMasterDataOrReadOnly]
    pagination_class = None

    def get_serializer_class(self):
        return PpeItemWriteSerializer if self.request.method == 'POST' else PpeItemSerializer

    def get_queryset(self):
        queryset = catalog_queryset()
        if not (self.request.query_params.get('include_inactive') == '1' and self.request.user.has_permission_code('MANAGE_MASTER_DATA')):
            queryset = queryset.filter(active=True)
        search = self.request.query_params.get('search')
        if search:
            ids = PpeItem.objects.filter(Q(code__icontains=search) | Q(translations__name__icontains=search) | Q(translations__short_name__icontains=search)).values('id')
            queryset = queryset.filter(id__in=ids)
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        return queryset

    def create(self, request, *args, **kwargs):
        serializer = PpeItemWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        item = serializer.save_with_translations()
        audit(actor=request.user, action='CREATE', entity='PpeItem', entity_id=item.pk, after={'code': item.code})
        return Response(PpeItemSerializer(catalog_queryset().get(pk=item.pk), context={'request': request}).data, status=status.HTTP_201_CREATED)


class PpeItemDetailView(APIView):
    permission_classes = [CanManageMasterDataOrReadOnly]

    def get(self, request, pk):
        return Response(PpeItemSerializer(get_object_or_404(catalog_queryset(), pk=pk), context={'request': request}).data)

    def patch(self, request, pk):
        item = get_object_or_404(PpeItem, pk=pk)
        before = {f: getattr(item, f) for f in ['quota', 'lifespan_days', 'reorder_point', 'active', 'sizes']}
        serializer = PpeItemWriteSerializer(item, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        reason = serializer.validated_data.get('change_reason', '')
        item = serializer.save_with_translations()
        audit(actor=request.user, action='UPDATE', entity='PpeItem', entity_id=item.pk, before=before,
              after={**{f: getattr(item, f) for f in before}, 'reason': reason})
        return Response(PpeItemSerializer(catalog_queryset().get(pk=item.pk), context={'request': request}).data)


class PpeEligibilityView(APIView):
    """Pre-check quota / lifespan / duplicate for the current user before creating a request."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        item = get_object_or_404(PpeItem, pk=pk)
        try:
            quantity = max(1, int(request.query_params.get('quantity', 1)))
        except ValueError:
            quantity = 1
        result = evaluate_line(request.user, item, quantity)
        result.update({'stock': available_stock(item), 'quota': item.quota})
        return Response(EligibilitySerializer(result).data)


# ---------------------------------------------------------------------------
# Requisitions
# ---------------------------------------------------------------------------

def _with_relations(queryset):
    return queryset.prefetch_related(
        Prefetch('items', queryset=RequisitionItem.objects.select_related('ppe_item').prefetch_related('ppe_item__translations')),
        'approvals__approver',
    )


class RequisitionListCreateView(generics.ListCreateAPIView):
    serializer_class = RequisitionSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardPagination

    def get_queryset(self):
        user = self.request.user
        scope = self.request.query_params.get('scope', 'visible')
        if scope == 'mine':
            queryset = Requisition.objects.filter(requester=user)
        elif scope == 'inbox':
            queryset = approval_inbox(user)
        elif scope == 'store':
            if user.role not in STORE_ROLES:
                return Requisition.objects.none()
            queryset = Requisition.objects.filter(status__in=[RequisitionStatus.APPROVED, RequisitionStatus.ON_HOLD, RequisitionStatus.READY])
        elif scope == 'team':
            queryset = visible_requisitions(user).exclude(requester=user)
        else:
            queryset = visible_requisitions(user)
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status__in=status_param.split(','))
        req_type = self.request.query_params.get('req_type')
        if req_type:
            queryset = queryset.filter(req_type=req_type)
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(Q(request_no__icontains=search) | Q(requester__display_name__icontains=search) | Q(requester__employee_id__icontains=search))
        order = 'created_at' if scope in ('inbox', 'store') else '-created_at'
        return _with_relations(queryset.select_related('requester').distinct().order_by(order))

    def create(self, request, *args, **kwargs):
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        if not data.get('client_request_id') and request.headers.get('Idempotency-Key'):
            data['client_request_id'] = request.headers['Idempotency-Key']
        input_serializer = CreateRequisitionSerializer(data=data)
        input_serializer.is_valid(raise_exception=True)
        requisition = create_requisition(requester=request.user, **input_serializer.validated_data)
        requisition = _with_relations(Requisition.objects.filter(pk=requisition.pk)).get()
        return Response(RequisitionDetailSerializer(requisition, context={'request': request}).data, status=status.HTTP_201_CREATED)


def _get_visible(request, pk) -> Requisition:
    queryset = _with_relations(visible_requisitions(request.user)).prefetch_related('comments__author', 'stock_events__stock_lot__ppe_item',
                                                                                     'stock_events__issuer', 'stock_events__receiver')
    return get_object_or_404(queryset, pk=pk)


def _detail(request, pk):
    return Response(RequisitionDetailSerializer(_get_visible(request, pk), context={'request': request}).data)


class RequisitionDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        return _detail(request, pk)


class RequisitionCancelView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        cancel_requisition(requisition=_get_visible(request, pk), actor=request.user)
        return _detail(request, pk)


class ApprovalView(APIView):
    permission_classes = [IsSupervisorOrHigher]

    def post(self, request, pk):
        input_serializer = ApprovalInputSerializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)
        requisition = _get_visible(request, pk)
        decision = input_serializer.validated_data['decision']
        reason = input_serializer.validated_data['reason']
        if decision == 'REQUEST_INFO':
            add_comment(requisition=requisition, author=request.user, message=reason, info_request=True)
        else:
            approve_requisition(requisition=requisition, approver=request.user, decision=decision, reason=reason)
        return _detail(request, pk)


class RequisitionCommentView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        return Response(CommentSerializer(_get_visible(request, pk).comments.select_related('author'), many=True).data)

    def post(self, request, pk):
        serializer = CommentInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        add_comment(requisition=_get_visible(request, pk), author=request.user, message=serializer.validated_data['message'])
        return _detail(request, pk)


class RequisitionPickupQRView(APIView):
    """Requester generates a one-time pickup QR for a READY requisition; the store scans it."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        requisition = get_object_or_404(Requisition, pk=pk, requester=request.user)
        if requisition.status != RequisitionStatus.READY:
            raise BusinessRuleError('INVALID_STATUS', 'Pickup QR is only available when the requisition is ready.')
        token, challenge = create_qr_challenge(purpose='PICKUP', user=request.user, requisition=requisition)
        return Response({'token': token, 'expires_at': challenge.expires_at, 'request_no': requisition.request_no})


class InventoryPrepareView(APIView):
    permission_classes = [IsStoreOrHigher]

    def post(self, request, pk):
        reserve_and_prepare(requisition_id=_get_visible(request, pk).pk, actor=request.user)
        return _detail(request, pk)


class InventoryIssueView(APIView):
    permission_classes = [IsStoreOrHigher]

    def post(self, request, pk):
        serializer = IssueInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        requisition = _get_visible(request, pk)
        method = 'MANUAL'
        qr_token = serializer.validated_data['qr_token']
        if qr_token:
            challenge = resolve_qr(token=qr_token)
            if challenge.requisition_id != requisition.pk:
                raise BusinessRuleError('QR_MISMATCH', 'This QR code belongs to a different requisition.')
            method = 'QR'
        issue_requisition(requisition_id=requisition.pk, actor=request.user, serial_numbers=serializer.validated_data['serial_numbers'], method=method)
        return _detail(request, pk)


class InventoryReturnView(APIView):
    """Store receives a returned PPE line (GOOD back to stock, DAMAGED written off)."""
    permission_classes = [IsStoreOrHigher]

    def post(self, request, pk):
        serializer = ReturnInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        line = return_item(requisition_item=get_object_or_404(RequisitionItem, pk=pk), actor=request.user, **serializer.validated_data)
        return _detail(request, line.requisition_id)


# ---------------------------------------------------------------------------
# Inventory
# ---------------------------------------------------------------------------

class InventoryListView(generics.ListCreateAPIView):
    """GET: lots (filter by ppe_item, status, expired). POST: receive new stock."""
    permission_classes = [IsStoreOrHigher]
    serializer_class = StockLotSerializer
    pagination_class = StandardPagination

    def get_queryset(self):
        queryset = StockLot.objects.select_related('ppe_item').prefetch_related('ppe_item__translations').order_by('ppe_item__code', 'expiry_at', 'id')
        params = self.request.query_params
        if params.get('ppe_item'):
            queryset = queryset.filter(ppe_item_id=params['ppe_item'])
        if params.get('serial_status'):
            queryset = queryset.filter(serial_status=params['serial_status'])
        if params.get('in_stock') == '1':
            queryset = queryset.filter(quantity__gt=0)
        if params.get('search'):
            s = params['search']
            queryset = queryset.filter(Q(lot_number__icontains=s) | Q(serial_number__icontains=s) | Q(ppe_item__code__icontains=s))
        return queryset

    def create(self, request, *args, **kwargs):
        serializer = ReceiveStockSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = dict(serializer.validated_data)
        ppe_item = get_object_or_404(PpeItem, pk=data.pop('ppe_item_id'))
        purchase_request = None
        pr_id = data.pop('purchase_request_id', None)
        if pr_id:
            purchase_request = get_object_or_404(PpePurchaseRequest, pk=pr_id, ppe_item=ppe_item)
        lots = receive_stock(ppe_item=ppe_item, actor=request.user, purchase_request=purchase_request, **data)
        if purchase_request:
            purchase_request.status = PurchaseRequestStatus.RECEIVED
            purchase_request.save(update_fields=['status', 'updated_at'])
        _resume_on_hold(ppe_item, request.user)
        return Response(StockLotSerializer(lots, many=True, context={'request': request}).data, status=status.HTTP_201_CREATED)


def _resume_on_hold(ppe_item: PpeItem, actor: User) -> None:
    """After receiving stock, notify store about on-hold requests for that item."""
    waiting = Requisition.objects.filter(status=RequisitionStatus.ON_HOLD, items__ppe_item=ppe_item).distinct()
    if waiting.exists():
        from .models import NotificationType
        notify_users(users=User.objects.filter(role=Role.STORE_KEEPER, is_active=True), notification_type=NotificationType.ON_HOLD,
                     title=f'Stock received for {ppe_item.code}', message=f'{waiting.count()} on-hold requisition(s) can be prepared now.',
                     payload={'ppe_item_id': ppe_item.id, 'code': ppe_item.code})


class StockLotAdjustView(APIView):
    permission_classes = [IsStoreOrHigher]

    def post(self, request, pk):
        serializer = AdjustStockSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        lot = adjust_lot(lot=get_object_or_404(StockLot, pk=pk), actor=request.user, **serializer.validated_data)
        lot.refresh_from_db()
        return Response(StockLotSerializer(lot, context={'request': request}).data)


class InventorySummaryView(APIView):
    """Per-item stock overview: available, reserved, issued (30 days) and reorder flag."""
    permission_classes = [IsStoreOrHigher]

    def get(self, request):
        since = timezone.now() - timedelta(days=30)
        items = catalog_queryset()

        issued = dict(StockEvent.objects.filter(event_type='ISSUE', created_at__gte=since).values_list('stock_lot__ppe_item').annotate(total=Sum('quantity')))
        data = []
        for item in items:
            row = PpeItemSerializer(item, context={'request': request}).data
            row['issued_30d'] = issued.get(item.id, 0)
            row['expiring_lots'] = StockLot.objects.filter(ppe_item=item, quantity__gt=0, expiry_at__isnull=False,
                                                           expiry_at__lte=timezone.now() + timedelta(days=30)).count()
            row['needs_reorder'] = row['stock'] <= item.reorder_point
            data.append(row)
        return Response(data)


class StockEventListView(generics.ListAPIView):
    permission_classes = [IsStoreOrHigher]
    serializer_class = StockEventSerializer
    pagination_class = StandardPagination

    def get_queryset(self):
        queryset = StockEvent.objects.select_related('stock_lot__ppe_item', 'issuer', 'receiver', 'requisition').order_by('-created_at')
        if self.request.query_params.get('ppe_item'):
            queryset = queryset.filter(stock_lot__ppe_item_id=self.request.query_params['ppe_item'])
        if self.request.query_params.get('event_type'):
            queryset = queryset.filter(event_type=self.request.query_params['event_type'])
        return queryset


class QRChallengeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        requisition_id = request.data.get('requisition_id')
        requisition = None
        if requisition_id:
            requisition = get_object_or_404(visible_requisitions(request.user), pk=requisition_id)
            if requisition.requester_id != request.user.id and request.user.role not in STORE_ROLES:
                raise BusinessRuleError('FORBIDDEN', 'Not allowed to create a QR for this requisition.', 403)
        token, challenge = create_qr_challenge(purpose=request.data.get('purpose', 'ISSUE'), user=request.user, requisition=requisition)
        return Response({'token': token, 'expires_at': challenge.expires_at})


class QRResolveView(APIView):
    """Store scans a QR. Pickup QRs are only verified here (not consumed) unless consume=true."""
    permission_classes = [IsStoreOrHigher]

    def post(self, request):
        token = request.data.get('token', '')
        consume = bool(request.data.get('consume', False))
        from .services import QR_PREFIX, _hash
        from .models import QRChallenge
        if consume:
            challenge = resolve_qr(token=token)
        else:
            challenge = QRChallenge.objects.select_related('requisition__requester').filter(token_hash=_hash(token.strip().removeprefix(QR_PREFIX))).first()
            if not challenge or not challenge.is_usable:
                raise BusinessRuleError('QR_INVALID', 'QR token is invalid, expired, or already used.', 400)
        requisition = challenge.requisition
        return Response({
            'purpose': challenge.purpose,
            'requisition_id': requisition.id if requisition else None,
            'request_no': requisition.request_no if requisition else None,
            'status': requisition.status if requisition else None,
            'requester_name': requisition.requester.display_name if requisition else None,
            'expires_at': challenge.expires_at,
        })


# ---------------------------------------------------------------------------
# Purchase requests (EHS/Admin raise, Store processes)
# ---------------------------------------------------------------------------

class PurchaseRequestListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsStoreOrHigher]
    serializer_class = PurchaseRequestSerializer
    pagination_class = StandardPagination

    def get_queryset(self):
        queryset = PpePurchaseRequest.objects.select_related('ppe_item', 'requester').prefetch_related('ppe_item__translations').order_by('-created_at')
        if self.request.query_params.get('status'):
            queryset = queryset.filter(status__in=self.request.query_params['status'].split(','))
        return queryset

    def perform_create(self, serializer):
        pr = serializer.save(requester=self.request.user, request_no=f'PO-{timezone.now():%y%m%d%H%M%S%f}'[:24])
        audit(actor=self.request.user, action='CREATE', entity='PurchaseRequest', entity_id=pr.pk, after={'quantity': pr.requested_quantity})
        from .models import NotificationType
        notify_users(users=User.objects.filter(role__in=[Role.STORE_KEEPER, Role.ADMIN], is_active=True).exclude(pk=self.request.user.pk),
                     notification_type=NotificationType.REORDER_POINT, title=f'Purchase request {pr.request_no}',
                     message=f'{pr.requested_quantity} x {pr.ppe_item.code} requested.', payload={'purchase_request_id': pr.id, 'code': pr.ppe_item.code})


class PurchaseRequestStatusView(APIView):
    permission_classes = [IsStoreOrHigher]
    transitions = {
        PurchaseRequestStatus.PENDING: [PurchaseRequestStatus.APPROVED, PurchaseRequestStatus.REJECTED],
        PurchaseRequestStatus.APPROVED: [PurchaseRequestStatus.ORDERED, PurchaseRequestStatus.REJECTED],
        PurchaseRequestStatus.ORDERED: [PurchaseRequestStatus.RECEIVED],
    }

    def post(self, request, pk):
        pr = get_object_or_404(PpePurchaseRequest, pk=pk)
        new_status = request.data.get('status')
        if new_status not in self.transitions.get(pr.status, []):
            raise BusinessRuleError('INVALID_STATUS', f'Cannot move purchase request from {pr.status} to {new_status}.')
        before = pr.status
        pr.status = new_status
        pr.save(update_fields=['status', 'updated_at'])
        audit(actor=request.user, action='PURCHASE_' + new_status, entity='PurchaseRequest', entity_id=pr.pk, before={'status': before}, after={'status': new_status})
        return Response(PurchaseRequestSerializer(pr, context={'request': request}).data)


# ---------------------------------------------------------------------------
# Dashboard & audit
# ---------------------------------------------------------------------------

class DashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        data = dashboard_summary(request.user)
        recent = _with_relations(visible_requisitions(request.user).order_by('-created_at'))[:5]
        data['recent'] = RequisitionSerializer(recent, many=True, context={'request': request}).data
        return Response(data)


class AuditLogListView(generics.ListAPIView):
    permission_classes = [IsEhsOrAdmin]
    serializer_class = AuditLogSerializer
    pagination_class = StandardPagination

    def get_queryset(self):
        queryset = AuditLog.objects.select_related('actor').order_by('-created_at')
        params = self.request.query_params
        if params.get('entity'):
            queryset = queryset.filter(entity=params['entity'])
        if params.get('action'):
            queryset = queryset.filter(action=params['action'])
        if params.get('search'):
            s = params['search']
            queryset = queryset.filter(Q(actor__employee_id__icontains=s) | Q(actor__display_name__icontains=s) | Q(entity_id=s))
        return queryset
