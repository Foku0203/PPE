import { Prisma, PrismaClient, RequisitionStatus } from '@prisma/client';

const prisma = new PrismaClient();

export type RequisitionLine = {
  ppeItemId: string;
  quantity: number;
  size?: string;
  reason: string;
};

export type Eligibility = {
  ppeItemId: string;
  allowed: boolean;
  specialApprovalRequired: boolean;
  eligibleAt?: Date;
  reason?: string;
};

const activeStatuses: RequisitionStatus[] = [
  'PENDING_APPROVAL',
  'SPECIAL_APPROVAL_REQUIRED',
  'APPROVED',
  'READY_FOR_PICKUP',
];

/** ตรวจ quota/lifespan และรายการที่ยังค้างอยู่ ก่อนสร้างคำขอ */
export async function evaluateEligibility(
  db: PrismaClient | Prisma.TransactionClient,
  requesterId: string,
  lines: RequisitionLine[],
  now = new Date(),
): Promise<Eligibility[]> {
  const results: Eligibility[] = [];

  for (const line of lines) {
    const [ppe, lastIssue, duplicateRequest] = await Promise.all([
      db.ppeItem.findUniqueOrThrow({ where: { id: line.ppeItemId } }),
      db.stockEvent.findFirst({
        where: {
          receiverId: requesterId,
          type: 'ISSUE',
          stockLot: { ppeItemId: line.ppeItemId },
        },
        orderBy: { createdAt: 'desc' },
      }),
      db.requisition.findFirst({
        where: {
          requesterId,
          status: { in: activeStatuses },
          items: { some: { ppeItemId: line.ppeItemId } },
        },
        select: { id: true },
      }),
    ]);

    if (duplicateRequest) {
      results.push({ ppeItemId: line.ppeItemId, allowed: false, specialApprovalRequired: false, reason: 'ACTIVE_REQUEST_EXISTS' });
      continue;
    }

    const eligibleAt = lastIssue && ppe.lifespanDays
      ? new Date(lastIssue.createdAt.getTime() + ppe.lifespanDays * 86_400_000)
      : undefined;
    const lifespanBlocked = eligibleAt !== undefined && eligibleAt > now;
    const quotaBlocked = ppe.quota !== null && line.quantity > ppe.quota;

    results.push({
      ppeItemId: line.ppeItemId,
      allowed: !lifespanBlocked && !quotaBlocked,
      specialApprovalRequired: lifespanBlocked || quotaBlocked,
      eligibleAt,
      reason: lifespanBlocked ? 'LIFESPAN_NOT_EXPIRED' : quotaBlocked ? 'QUOTA_EXCEEDED' : undefined,
    });
  }

  return results;
}

/** สร้างคำขอแบบ atomic: ตรวจซ้ำและ insert ใน transaction เดียว */
export async function createRequisition(
  requesterId: string,
  clientRequestId: string,
  lines: RequisitionLine[],
) {
  return prisma.$transaction(async (tx) => {
    const existing = await tx.requisition.findUnique({
      where: { requesterId_clientRequestId: { requesterId, clientRequestId } },
    });
    if (existing) return existing; // idempotent retry จาก mobile

    const eligibility = await evaluateEligibility(tx, requesterId, lines);
    const hardBlocked = eligibility.find((item) => item.reason === 'ACTIVE_REQUEST_EXISTS');
    if (hardBlocked) throw new Error(`Duplicate active request for ${hardBlocked.ppeItemId}`);

    const requiresSpecialApproval = eligibility.some((item) => item.specialApprovalRequired);
    return tx.requisition.create({
      data: {
        requestNo: `PR-${Date.now()}`,
        requesterId,
        clientRequestId,
        specialApprovalNeeded: requiresSpecialApproval,
        status: requiresSpecialApproval ? 'SPECIAL_APPROVAL_REQUIRED' : 'PENDING_APPROVAL',
        items: { create: lines.map((line) => ({ ...line })) },
      },
      include: { items: true },
    });
  });
}
