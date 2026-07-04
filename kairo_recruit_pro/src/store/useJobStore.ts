import { create } from 'zustand';
import { db } from '../lib/firebase';
import { collection, getDocs, addDoc, query, where, serverTimestamp, doc, updateDoc } from 'firebase/firestore';
import { useAuthStore } from './useAuthStore';

export interface Job {
  id: string;
  postedBy: string;
  title: string;
  company: string;
  location: string;
  type: string; // Full-time, Internship, etc.
  description: string;
  department?: string;
  numberOfPositions: number;
  workTime: string; // Temps plein, Temps partiel
  seniorityLevel: string;
  
  // Localisation
  country?: string;
  city?: string;
  remoteWork: string; // Télétravail, Hybride, Présentiel
  
  // Advanced ATS Fields
  educationLevel: string; // e.g. "Bac+3", "Master"
  minExperience: number; // e.g. 2 (years)
  mandatorySkills: string[];
  niceToHaveSkills: string[];
  languages: string[];
  requiredDocuments: string[]; // e.g. ["CV", "Lettre de motivation", "Portfolio"]
  preSelectionQuestions: string[];
  salaryRange?: string;
  
  status: 'brouillon' | 'programmé' | 'ouvert' | 'suspendu' | 'clôturé' | 'archivé';
  createdAt: Date;
  openDate?: Date;
  closeDate?: Date;
  expectedStartDate?: Date;
}

interface JobState {
  jobs: Job[];
  isLoading: boolean;
  error: string | null;
  fetchJobs: () => Promise<void>;
  createJob: (jobData: Omit<Job, 'id' | 'postedBy' | 'status' | 'createdAt' | 'company'>) => Promise<void>;
  updateJobStatus: (jobId: string, newStatus: Job['status']) => Promise<void>;
}

export const useJobStore = create<JobState>((set, get) => ({
  jobs: [],
  isLoading: false,
  error: null,

  fetchJobs: async () => {
    const user = useAuthStore.getState().user;
    if (!user) return;

    set({ isLoading: true, error: null });
    try {
      const q = query(collection(db, 'opportunities'), where('postedBy', '==', user.uid));
      const snapshot = await getDocs(q);
      
      const fetchedJobs: Job[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        fetchedJobs.push({
          id: doc.id,
          postedBy: data.postedBy || data.recruiterId,
          title: data.title,
          company: data.company || data.companyName,
          location: data.location,
          type: data.type,
          description: data.description,
          
          department: data.department || '',
          numberOfPositions: data.numberOfPositions || 1,
          workTime: data.workTime || 'Temps plein',
          seniorityLevel: data.seniorityLevel || '',
          country: data.country || '',
          city: data.city || '',
          remoteWork: data.remoteWork || 'Présentiel',
          
          educationLevel: data.educationLevel || '',
          minExperience: data.minExperience || 0,
          mandatorySkills: data.mandatorySkills || [],
          niceToHaveSkills: data.niceToHaveSkills || [],
          languages: data.languages || [],
          requiredDocuments: data.requiredDocuments || ['CV'],
          preSelectionQuestions: data.preSelectionQuestions || [],
          salaryRange: data.salaryRange || '',

          status: data.status || 'ouvert',
          createdAt: data.createdAt?.toDate() || new Date(),
          openDate: data.openDate?.toDate(),
          closeDate: data.closeDate?.toDate(),
          expectedStartDate: data.expectedStartDate?.toDate(),
        });
      });

      // Sort by newest first
      fetchedJobs.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

      set({ jobs: fetchedJobs, isLoading: false });
    } catch (error: any) {
      console.error("Error fetching jobs:", error);
      set({ error: "Impossible de charger les offres.", isLoading: false });
    }
  },

  createJob: async (jobData) => {
    const { user, profile } = useAuthStore.getState();
    if (!user || !profile) return;

    set({ isLoading: true, error: null });
    try {
      const newJobRef = await addDoc(collection(db, 'opportunities'), {
        ...jobData,
        postedBy: user.uid,
        company: profile.companyName || 'Entreprise Inconnue',
        status: 'ouvert',
        createdAt: serverTimestamp(),
      });

      const newJob: Job = {
        id: newJobRef.id,
        ...jobData,
        postedBy: user.uid,
        company: profile.companyName || 'Entreprise Inconnue',
        status: 'ouvert',
        createdAt: new Date(),
      };

      set({ jobs: [newJob, ...get().jobs], isLoading: false });
    } catch (error) {
      console.error("Erreur lors de la création du poste :", error);
      set({ error: "Impossible de créer l'offre.", isLoading: false });
    }
  },

  updateJobStatus: async (jobId, newStatus) => {
    try {
      const docRef = doc(db, 'opportunities', jobId);
      await updateDoc(docRef, { status: newStatus });
      set((state) => ({
        jobs: state.jobs.map(j => j.id === jobId ? { ...j, status: newStatus } : j)
      }));
    } catch (error) {
      console.error("Erreur mise à jour statut:", error);
    }
  }
}));
