export type BetaStatus = "draft" | "in_progress" | "complete";
export type TesterStatus = "nominated" | "csm_pending" | "csm_approved" | "outreach_sent" | "confirmed" | "active" | "completed" | "dropped" | "cancelled";
export type ApprovalStatus = "pending" | "approved" | "rejected";
export type BatchStatus = "pending" | "ready" | "sent";
export type HealthStatus = "green" | "yellow" | "red";
export type Segment = "Strategic" | "Enterprise" | "Commercial" | "Professional" | "Channel";
export type UserRole = "pm" | "pmm" | "csm" | "admin" | "ae";
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
  betaGoal: string | null;
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
  aeOwnerId: string | null;
  tier: number;
  accountHealth: HealthStatus;
  segment: Segment | null;
  vertical: string | null;
  primaryContactName: string | null;
  primaryContactEmail: string | null;
  outreachLock: boolean;
  lastOutreachDate: string | null;
  notes: string | null;
  crmId: string | null;
  createdAt: string;
  csmOwner?: User;
  aeOwner?: User | null;
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

export interface BatchFeature {
  id: string;
  name: string;
  slug?: string | null;
  status?: BetaStatus;
  idealClientCriteria?: string | null;
  betaGoal?: string | null;
  targetTesterCount?: number;
  ownerPmId?: string | null;
  ownerPmmId?: string | null;
  ownerPm?: User | null;
  ownerPmm?: User | null;
}

export interface OutreachBatch {
  id: string;
  clientId: string;
  batchStatus: BatchStatus;
  sentAt: string | null;
  sentById: string | null;
  senderId: string | null;
  ccIds: string[];
  createdAt: string;
  client?: Client;
  sentBy?: User | null;
  sender?: User | null;
  ccUsers?: User[];
  enrollments?: Array<{
    batchId: string;
    enrollmentId: string;
    enrollment?: BetaEnrollment & {
      feature?: BatchFeature;
      csmApprovedBy?: User | null;
    };
  }>;
}
