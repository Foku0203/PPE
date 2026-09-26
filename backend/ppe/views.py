import hashlib
from django.db.models import F, Q, Sum
from django.db.models.functions import Coalesce
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .auth import EmployeeIdTokenSerializer
from .models import (
    ApprovalDecision,
    DeviceToken,
    Notification,
    PpeItem,
    PpePurchaseRequest,
    QRChallenge,
    Requisition,
    RequisitionItem,
    RequisitionStatus,
    RequisitionType,
    Role,
    StockEvent,
    StockEventType,
    StockLot,
    User,
)
from .permissions import IsStoreOrHigher, IsSupervisorOrHigher
from .serializers import (
    ApprovalInputSerializer,
    CreateRequisitionSerializer,
    DeviceTokenSerializer,
    NotificationSerializer,
    PpeItemSerializer,
    RegisterSerializer,
    RequisitionSerializer,
    StockLotSerializer,
    UserSerializer,
)
from .services import (
    approve_requisition,
    create_qr_challenge,
    create_requisition,
    issue_requisition,
    reserve_and_prepare,
)


class EmployeeIdTokenView(APIView):
    """View สำหรับเข้าสู่ระบบด้วย Employee ID + Password"""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = EmployeeIdTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data, status=status.HTTP_200_OK)


class RegisterView(generics.CreateAPIView):
    """View สำหรับลงทะเบียนพนักงานใหม่จาก Flutter App"""
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }, status=status.HTTP_201_CREATED)


class UserMeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)


class DeviceTokenView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = serializer.validated_data['token']
        device, _ = DeviceToken.objects.update_or_create(
            token=token,
            defaults={
                'user': request.user,
                'platform': serializer.validated_data['platform'],
                'active': True,
                'last_seen_at': timezone.now(),
            },
        )
        return Response(DeviceTokenSerializer(device).data, status=status.HTTP_201_CREATED)


class NotificationListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user).order_by('-created_at')


class NotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        notification = get_object_or_404(Notification, pk=pk, recipient=request.user)
        notification.read_at = timezone.now()
        notification.save(update_fields=['read_at'])
        return Response(NotificationSerializer(notification).data)


class PpeCatalogView(generics.ListAPIView):
    serializer_class = PpeItemSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = PpeItem.objects.filter(active=True).prefetch_related('translations').annotate(
            stock=Coalesce(Sum(F('stock_lots__quantity') - F('stock_lots__reserved_quantity')), 0)
        )
        search_query = self.request.query_params.get('search', None)
        if search_query:
            queryset = queryset.filter(
                Q(code__icontains=search_query) | 
                Q(translations__name__icontains=search_query)
            ).distinct()
        return queryset


class RequisitionListCreateView(generics.ListCreateAPIView):
    serializer_class = RequisitionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = Requisition.objects.select_related('requester').prefetch_related('items__ppe_item', 'approvals').order_by('-created_at')
        
        # Filter ตามสิทธิ์ผู้ใช้งาน
        if user.role not in [Role.SUPERVISOR, Role.STORE_KEEPER, Role.EHS, Role.ADMIN]:
            queryset = queryset.filter(Q(requester=user) | Q(requester__supervisor=user))
        
        # Filter ตาม Parameter สำหรับ UI Tab ใน Mobile App
        status_param = self.request.query_params.get('status')
        req_type_param = self.request.query_params.get('req_type')
        
        if status_param:
            queryset = queryset.filter(status=status_param)
        if req_type_param:
            queryset = queryset.filter(req_type=req_type_param)
            
        return queryset

    def create(self, request, *args, **kwargs):
        input_serializer = CreateRequisitionSerializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)
        requisition = create_requisition(requester=request.user, **input_serializer.validated_data)
        return Response(RequisitionSerializer(requisition).data, status=status.HTTP_201_CREATED)


class RequisitionDetailView(generics.RetrieveAPIView):
    serializer_class = RequisitionSerializer
    permission_classes = [IsAuthenticated]
    queryset = Requisition.objects.select_related('requester').prefetch_related('items__ppe_item', 'approvals')


class RequisitionCancelView(APIView):
    """View สำหรับยกเลิกใบคำขอเบิก (เฉพาะรายการที่ยังไม่จบกระบวนการ)"""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        requisition = get_object_or_404(Requisition, pk=pk, requester=request.user)
        if requisition.status in [RequisitionStatus.COMPLETED, RequisitionStatus.CANCELLED, RequisitionStatus.REJECTED]:
            raise ValidationError({'status': 'Cannot cancel requisition in current status.'})
        
        requisition.status = RequisitionStatus.CANCELLED
        requisition.save(update_fields=['status', 'updated_at'])
        return Response(RequisitionSerializer(requisition).data)


class ApprovalView(APIView):
    permission_classes = [IsSupervisorOrHigher]

    def post(self, request, pk):
        input_serializer = ApprovalInputSerializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)
        requisition = get_object_or_404(Requisition, pk=pk)
        result = approve_requisition(requisition=requisition, approver=request.user, **input_serializer.validated_data)
        return Response(RequisitionSerializer(result).data)


class InventoryPrepareView(APIView):
    permission_classes = [IsStoreOrHigher]

    def post(self, request, pk):
        result = reserve_and_prepare(requisition_id=pk, actor=request.user)
        return Response(RequisitionSerializer(result).data)


class InventoryIssueView(APIView):
    permission_classes = [IsStoreOrHigher]

    def post(self, request, pk):
        serial_numbers = request.data.get('serial_numbers', [])
        if not isinstance(serial_numbers, list):
            raise ValidationError({'serial_numbers': 'Must be a list.'})
        result = issue_requisition(requisition_id=pk, actor=request.user, serial_numbers=serial_numbers)
        return Response(RequisitionSerializer(result).data)


class InventoryReturnView(APIView):
    """View สำหรับคลังรับคืนอุปกรณ์ PPE จากพนักงาน"""
    permission_classes = [IsStoreOrHigher]

    def post(self, request, pk):
        requisition_item = get_object_or_404(RequisitionItem, pk=pk)
        if requisition_item.is_returned:
            raise ValidationError({'item': 'This item has already been returned.'})

        now = timezone.now()
        requisition_item.is_returned = True
        requisition_item.returned_at = now
        requisition_item.save(update_fields=['is_returned', 'returned_at'])

        # คืนจำนวนเข้า StockLot
        lot = StockLot.objects.filter(ppe_item=requisition_item.ppe_item).first()
        if lot:
            lot.quantity = F('quantity') + requisition_item.quantity
            lot.save(update_fields=['quantity'])
            
            StockEvent.objects.create(
                requisition=requisition_item.requisition,
                stock_lot=lot,
                event_type=StockEventType.RETURN,
                quantity=requisition_item.quantity,
                issuer=request.user,
                receiver=requisition_item.requisition.requester,
            )

        return Response({'message': 'Item return processed successfully.', 'returned_at': now})


class InventoryListView(generics.ListAPIView):
    permission_classes = [IsStoreOrHigher]
    serializer_class = StockLotSerializer
    queryset = StockLot.objects.select_related('ppe_item').order_by('ppe_item__code', 'expiry_at', 'id')


class QRChallengeView(APIView):
    permission_classes = [IsStoreOrHigher]

    def post(self, request):
        requisition_id = request.data.get('requisition_id')
        requisition = get_object_or_404(Requisition, pk=requisition_id) if requisition_id else None
        raw_token, challenge = create_qr_challenge(
            purpose=request.data.get('purpose', 'ISSUE'),
            user=request.user,
            requisition=requisition
        )
        return Response({'token': raw_token, 'expires_at': challenge.expires_at})


class QRResolveView(APIView):
    permission_classes = [IsStoreOrHigher]

    def post(self, request):
        raw_token = request.data.get('token', '')
        challenge = QRChallenge.objects.select_related('requisition').filter(
            token_hash=hashlib.sha256(raw_token.encode()).hexdigest()
        ).first()
        
        if not challenge or not challenge.is_usable:
            raise ValidationError({'token': 'QR token is invalid, expired, or already used.'})
            
        challenge.used_at = timezone.now()
        challenge.save(update_fields=['used_at'])
        requisition = challenge.requisition
        return Response({
            'requisition_id': requisition.id if requisition else None,
            'request_no': requisition.request_no if requisition else None,
            'status': requisition.status if requisition else None,
        })


class PurchaseRequestListCreateView(APIView):
    """View สำหรับ จป. (EHS) ยื่นคำร้องขอสั่งซื้อ/เพิ่มอุปกรณ์เข้าคลัง"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        requests = PpePurchaseRequest.objects.select_related('ppe_item', 'requester').order_by('-created_at')
        data = [{
            'id': req.id,
            'request_no': req.request_no,
            'ppe_item_code': req.ppe_item.code,
            'requested_quantity': req.requested_quantity,
            'reason': req.reason,
            'status': req.status,
            'created_at': req.created_at,
        } for req in requests]
        return Response(data)

    def post(self, request):
        if request.user.role not in [Role.EHS, Role.ADMIN]:
            raise ValidationError({'permission': 'Only EHS or Admin can create purchase requests.'})
            
        ppe_item_id = request.data.get('ppe_item_id')
        quantity = request.data.get('requested_quantity')
        reason = request.data.get('reason', '')
        
        ppe_item = get_object_or_404(PpeItem, pk=ppe_item_id)
        pr = PpePurchaseRequest.objects.create(
            request_no=f'PR-PO-{timezone.now():%y%m%d%H%M%S}',
            requester=request.user,
            ppe_item=ppe_item,
            requested_quantity=quantity,
            reason=reason,
        )
        return Response({'id': pr.id, 'request_no': pr.request_no, 'status': pr.status}, status=status.HTTP_201_CREATED)


class DashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({
            'pending_approval': Requisition.objects.filter(status__in=[RequisitionStatus.PENDING, RequisitionStatus.SPECIAL]).count(),
            'ready_for_pickup': Requisition.objects.filter(status=RequisitionStatus.READY).count(),
            'completed_today': Requisition.objects.filter(status=RequisitionStatus.COMPLETED, updated_at__date=timezone.localdate()).count(),
            'low_stock_items': PpeItem.objects.filter(active=True)
            .annotate(total_avail=Coalesce(Sum(F('stock_lots__quantity') - F('stock_lots__reserved_quantity')), 0))
            .filter(total_avail__lte=F('reorder_point'))
            .count(),
        })