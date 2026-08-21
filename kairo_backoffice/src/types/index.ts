// KAIRO PRO - Core TypeScript Interfaces

export interface User {
  uid: string;
  email: string | null;
  displayName?: string | null;
  photoURL?: string | null;
  role?: 'admin' | 'agency' | 'candidate';
  companyId?: string; // Reference to their agency/company
  createdAt?: Date;
}

export interface Agency {
  id: string;
  name: string;
  email: string;
  phone?: string;
  specialty?: string;
  location?: string;
  website?: string;
  description?: string;
  logoUrl?: string;
  status: 'active' | 'inactive' | 'pending';
  createdAt?: Date;
}

export interface Opportunity {
  id: string;
  title: string;
  company: string; // Agency name
  companyId: string; // Agency ID
  location: string;
  type: string; // 'CDI', 'CDD', 'Stage', etc.
  salary: string;
  description: string;
  requirements: string[];
  status: 'active' | 'closed' | 'draft';
  createdAt?: Date;
  updatedAt?: Date;
}

export type CandidateStatus = 'new' | 'evaluating' | 'interview' | 'hired' | 'rejected';

export interface Candidate {
  id: string;
  name: string;
  role?: string;
  email?: string;
  phone?: string;
  score?: number; // AI match score (if reintroduced later)
  status: CandidateStatus;
  opportunityId: string;
  createdAt?: Date;
  updatedAt?: Date;
}
