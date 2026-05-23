export type BetaStatus = "draft" | "recruiting" | "outreach_sent" | "full" | "in_progress" | "closing" | "closed";
export type TesterStatus = "nominated" | "csm_pending" | "csm_approved" | "outreach_sent" | "confirmed" | "active" | "completed" | "dropped" | "cancelled";
export type ApprovalStatus = "pending" | "approved" | "rejected";
export type BatchStatus = "pending" | "ready" | "sent";
export type HealthStatus = "green" | "yellow" | "red";
export type UserRole = "pm" | "pmm" | "csm" | "admin";
export type CloseReason = "completed" | "cancelled" | "merged" | "paused";

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
}

export interface BetaFeature {
  id: string;
  name: string;
  ownerPmId: string;
  ownerPmmId: string;
  targetTesterCount: number;
  status: BetaStatus;
  startDate: string;
  closedAt: string | null;
  closeReason: CloseReason | null;
  closeNotes: string | null;
  idealClientCriteria: string | null;
  outreachDeadline: string;
  clonedFromId: string | null;
  createdAt: string;
  ownerPm?: User;
  ownerPmm?: User;
  enrollments?: BetaEnrollment[];
}

export interface Client {
  id: string;
  name: string;
  csmOwnerId: string;
  tier: number;
  accountHealth: HealthStatus;
  outreachLock: boolean;
  lastOutreachDate: string | null;
  notes: string | null;
  crmId: string | null;
  createdAt: string;
  csmOwner?: User;
  enrollments?: BetaEnrollment[];
}

export interface BetaEnrollment {
  id: string;
  clientId: string;
  featureId: string;
  assignedById: string;
  isOverflow: boolean;
  csmApprovalStatus: ApprovalStatus;
  csmApprovedById: string | null;
  csmApprovedAt: string | null;
  csmRejectionReason: string | null;
  testerStatus: TesterStatus;
  outreachSentAt: string | null;
  confirmedAt: string | null;
  completedAt: string | null;
  droppedAt: string | null;
  dropReason: string | null;
  createdAt: string;
  client?: Client & { csmOwner?: User };
  feature?: { id: string; name: string; status: BetaStatus };
  assignedBy?: User;
  csmApprovedBy?: User;
}

export interface OutreachBatch {
  id: string;
  clientId: string;
  batchStatus: BatchStatus;
  sentAt: string | null;
  sentById: string | null;
  createdAt: string;
  client?: Client;
  sentBy?: User | null;
  enrollments?: Array<{
    batchId: string;
    enrollmentId: string;
    enrollment?: BetaEnrollment & {
      feature?: { id: string; name: string };
      csmApprovedBy?: User | null;
    };
  }>;
}
