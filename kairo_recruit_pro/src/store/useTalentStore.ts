import { create } from 'zustand';
import { db } from '../lib/firebase';
import { collection, getDocs } from 'firebase/firestore';

export interface TalentProfile {
  id: string;
  name: string;
  email: string;
  photoUrl?: string;
  headline?: string;
  bio?: string;
  skills?: string[];
  university?: string;
  country?: string;
  role?: string;
  // Based on kairo_mobile structure
}

interface TalentState {
  talents: TalentProfile[];
  filteredTalents: TalentProfile[];
  isLoading: boolean;
  error: string | null;
  fetchTalents: () => Promise<void>;
  searchTalents: (queryText: string, filterSkill?: string) => void;
}

export const useTalentStore = create<TalentState>((set, get) => ({
  talents: [],
  filteredTalents: [],
  isLoading: false,
  error: null,

  fetchTalents: async () => {
    set({ isLoading: true, error: null });
    try {
      // In a real app, you might want to paginate. Here we fetch all non-recruiters.
      const usersRef = collection(db, 'users');
      // For now, we fetch all and filter in memory, because some users might not have a role field.
      const snapshot = await getDocs(usersRef);
      
      const fetchedTalents: TalentProfile[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        // Exclude recruiters and admins
        if (data.role !== 'recruiter' && data.role !== 'admin') {
          fetchedTalents.push({
            id: doc.id,
            name: data.name || data.fullName || 'Talent Anonyme',
            email: data.email,
            photoUrl: data.photoUrl || data.avatarUrl || null,
            headline: data.headline || data.jobTitle || 'Étudiant',
            bio: data.bio || '',
            skills: data.skills || [],
            university: data.university || data.school || 'Université',
            country: data.country || data.location || 'Localisation inconnue',
            role: data.role
          });
        }
      });

      set({ talents: fetchedTalents, filteredTalents: fetchedTalents, isLoading: false });
    } catch (error: any) {
      console.error("Erreur lors de la récupération des talents:", error);
      set({ error: "Impossible de charger les talents.", isLoading: false });
    }
  },

  searchTalents: (queryText: string, filterSkill?: string) => {
    const { talents } = get();
    const lowerQuery = queryText.toLowerCase();

    const filtered = talents.filter(t => {
      const matchName = t.name.toLowerCase().includes(lowerQuery);
      const matchHeadline = t.headline?.toLowerCase().includes(lowerQuery);
      const matchBio = t.bio?.toLowerCase().includes(lowerQuery);
      
      const matchesSearch = matchName || matchHeadline || matchBio;
      
      let matchesSkill = true;
      if (filterSkill && filterSkill.trim() !== '') {
        const lowerFilter = filterSkill.toLowerCase();
        matchesSkill = t.skills?.some(s => s.toLowerCase().includes(lowerFilter)) || false;
      }

      return matchesSearch && matchesSkill;
    });

    set({ filteredTalents: filtered });
  }
}));
