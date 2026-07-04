import { create } from 'zustand';
import { db } from '../lib/firebase';
import { collection, query, where, addDoc, updateDoc, doc, serverTimestamp, onSnapshot, getDoc } from 'firebase/firestore';
import type { TalentProfile } from './useTalentStore';
import type { Job } from './useJobStore';

export interface PipelineItem {
  id: string; 
  jobId: string;
  candidateId: string;
  candidate: TalentProfile; 
  status: 'new' | 'screening' | 'interview' | 'offer' | 'hired' | 'rejected';
  addedAt: Date;
  matchScore?: number;
}

interface PipelineColumns {
  [key: string]: {
    id: string;
    title: string;
    itemIds: string[];
  };
}

interface PipelineData {
  items: { [key: string]: PipelineItem };
  columns: PipelineColumns;
  columnOrder: string[];
}

const initialColumns: PipelineColumns = {
  'new': { id: 'new', title: 'À traiter', itemIds: [] },
  'screening': { id: 'screening', title: 'Pré-sélection', itemIds: [] },
  'interview': { id: 'interview', title: 'Entretien', itemIds: [] },
  'offer': { id: 'offer', title: 'Offre envoyée', itemIds: [] },
  'hired': { id: 'hired', title: 'Embauché', itemIds: [] },
  'rejected': { id: 'rejected', title: 'Refusé', itemIds: [] },
};

interface PipelineState {
  data: PipelineData;
  activeJobId: string | null;
  activeJob: Job | null;
  isLoading: boolean;
  totalApplications: number;
  setActiveJob: (jobId: string) => Promise<void>;
  moveItem: (itemId: string, sourceColId: string, destColId: string, sourceIndex: number, destIndex: number) => Promise<void>;
  addCandidateToPipeline: (jobId: string, candidate: TalentProfile) => Promise<void>;
  fetchAllPipelinesStats: (recruiterId: string) => Promise<number>;
}

// Matching Algorithm Helper
const calculateScore = (job: Job | null, candidate: TalentProfile): number => {
  if (!job) return 0;
  let score = 0;
  
  // 1. Compétences Techniques (40%)
  if (job.mandatorySkills && job.mandatorySkills.length > 0) {
    const candidateSkillsStr = (candidate.skills || []).join(' ').toLowerCase();
    let matches = 0;
    job.mandatorySkills.forEach(skill => {
      if (candidateSkillsStr.includes(skill.toLowerCase())) matches++;
    });
    score += (matches / job.mandatorySkills.length) * 40;
  } else {
    score += 40; // Free points if no skills required
  }

  // 2. Formation (15%)
  if (job.educationLevel) {
    // Basic string matching for MVP
    const candidateHeadline = (candidate.headline || '').toLowerCase();
    const candidateUni = (candidate.university || '').toLowerCase();
    if (candidateHeadline.includes(job.educationLevel.toLowerCase()) || candidateUni.includes(job.educationLevel.toLowerCase())) {
      score += 15;
    } else {
      score += 5; // Partial points
    }
  } else {
    score += 15;
  }

  // 3. Expérience (25%) - Not fully structured in candidate MVP yet, assume random or parse bio
  score += 15; // baseline

  // 4. Langues (5%)
  score += 5;

  // 5. Questions (10%) + Bonus (5%)
  score += 15;

  return Math.min(Math.round(score), 100);
};

export const usePipelineStore = create<PipelineState>((set, get) => ({
  data: {
    items: {},
    columns: initialColumns,
    columnOrder: ['new', 'screening', 'interview', 'offer', 'hired', 'rejected']
  },
  activeJobId: null,
  activeJob: null,
  isLoading: false,
  totalApplications: 0,

  setActiveJob: async (jobId: string) => {
    set({ activeJobId: jobId, isLoading: true });
    
    try {
      // 1. Fetch Job for matching algorithm
      const jobDoc = await getDoc(doc(db, 'opportunities', jobId));
      const jobData = jobDoc.exists() ? jobDoc.data() as Job : null;
      set({ activeJob: jobData });

      const q = query(
        collection(db, 'applications'), 
        where('jobId', '==', jobId)
      );

      // We use onSnapshot instead of getDocs to get real-time updates!
      onSnapshot(q, (snapshot) => {
        const newItems: { [key: string]: PipelineItem } = {};
        const newColumns: PipelineColumns = JSON.parse(JSON.stringify(initialColumns));

        const applications: PipelineItem[] = [];
        snapshot.forEach(docSnap => {
          const data = docSnap.data();
          applications.push({
            id: docSnap.id,
            jobId: data.jobId,
            candidateId: data.candidateId,
            candidate: data.candidate,
            status: data.status,
            addedAt: data.addedAt?.toDate() || new Date(),
            matchScore: calculateScore(jobData, data.candidate)
          });
        });

        // Tri par score de matching (décroissant) puis par date
        applications.sort((a, b) => {
          if (b.matchScore !== a.matchScore) {
            return (b.matchScore || 0) - (a.matchScore || 0);
          }
          return b.addedAt.getTime() - a.addedAt.getTime();
        });

        applications.forEach(app => {
          newItems[app.id] = app;
          if (newColumns[app.status]) {
            newColumns[app.status].itemIds.push(app.id);
          } else {
             newColumns['new'].itemIds.push(app.id);
          }
        });

        set({
          data: {
            items: newItems,
            columns: newColumns,
            columnOrder: ['new', 'screening', 'interview', 'offer', 'hired', 'rejected']
          },
          isLoading: false
        });
      }, (error) => {
        console.error("Erreur de snapshot :", error);
        set({ isLoading: false });
      });

    } catch (error) {
      console.error("Erreur lors de la récupération du pipeline :", error);
      set({ isLoading: false });
    }
  },

  moveItem: async (itemId, sourceColId, destColId, sourceIndex, destIndex) => {
    const { data } = get();
    const sourceCol = data.columns[sourceColId];
    const destCol = data.columns[destColId];

    // Optimistic UI Update
    if (sourceColId === destColId) {
      const newItemIds = Array.from(sourceCol.itemIds);
      newItemIds.splice(sourceIndex, 1);
      newItemIds.splice(destIndex, 0, itemId);

      set({
        data: {
          ...data,
          columns: {
            ...data.columns,
            [sourceColId]: { ...sourceCol, itemIds: newItemIds }
          }
        }
      });
      // In-column ordering is not saved to Firestore in this simple MVP unless we add an `order` field.
    } else {
      const sourceItemIds = Array.from(sourceCol.itemIds);
      sourceItemIds.splice(sourceIndex, 1);

      const destItemIds = Array.from(destCol.itemIds);
      destItemIds.splice(destIndex, 0, itemId);

      const item = data.items[itemId];
      const updatedItem = { ...item, status: destColId as any };

      set({
        data: {
          ...data,
          items: {
            ...data.items,
            [itemId]: updatedItem
          },
          columns: {
            ...data.columns,
            [sourceColId]: { ...sourceCol, itemIds: sourceItemIds },
            [destColId]: { ...destCol, itemIds: destItemIds }
          }
        }
      });

      // Firebase Update
      try {
        const appRef = doc(db, 'applications', itemId);
        await updateDoc(appRef, { status: destColId });
      } catch (error) {
        console.error("Erreur lors du déplacement :", error);
        // We could revert the state here in a real production app
      }
    }
  },

  addCandidateToPipeline: async (jobId, candidate) => {
    try {
      // Create in Firestore first
      const docRef = await addDoc(collection(db, 'applications'), {
        jobId,
        candidateId: candidate.id,
        candidate,
        status: 'new',
        addedAt: serverTimestamp()
      });

      const { data, activeJobId } = get();
      
      // If we are currently viewing this job's pipeline, update the UI
      if (activeJobId === jobId) {
        const newItem: PipelineItem = {
          id: docRef.id,
          jobId,
          candidateId: candidate.id,
          candidate,
          status: 'new',
          addedAt: new Date()
        };

        set({
          data: {
            ...data,
            items: { ...data.items, [newItem.id]: newItem },
            columns: {
              ...data.columns,
              'new': {
                ...data.columns['new'],
                itemIds: [newItem.id, ...data.columns['new'].itemIds]
              }
            }
          }
        });
      }
    } catch (error) {
      console.error("Erreur d'ajout au pipeline :", error);
    }
  },

  fetchAllPipelinesStats: async (_recruiterId: string) => {
    // Basic implementation: Since we only have jobId in 'applications', 
    // it's tricky to query by recruiterId without a backend function or joining.
    // For MVP, we will rely on Jobs to count applications if needed, 
    // or just return a dummy if too complex. Let's return 0 here and handle it in Dashboard properly.
    return 0;
  }
}));
