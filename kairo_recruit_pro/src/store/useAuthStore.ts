import { create } from 'zustand';
import { auth, db } from '../lib/firebase';
import { 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged
} from 'firebase/auth';
import type { User } from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';

interface UserProfile {
  uid: string;
  name: string;
  email: string;
  companyName?: string;
  role: 'recruiter' | 'student' | 'admin';
  createdAt: string;
}

interface AuthState {
  user: User | null;
  profile: UserProfile | null;
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;
  login: (email: string, pass: string) => Promise<void>;
  register: (email: string, pass: string, name: string, company: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>((set) => {
  // Initialize Auth Listener
  onAuthStateChanged(auth, async (firebaseUser) => {
    if (firebaseUser) {
      try {
        const docRef = doc(db, 'users', firebaseUser.uid);
        const docSnap = await getDoc(docRef);
        
        if (docSnap.exists()) {
          const profile = docSnap.data() as UserProfile;
          if (profile.role !== 'recruiter' && profile.role !== 'admin') {
            await signOut(auth);
            set({ user: null, profile: null, isLoading: false, isInitialized: true, error: "Accès refusé. Ce compte n'est pas un compte recruteur." });
            return;
          }
          set({ user: firebaseUser, profile, isLoading: false, isInitialized: true, error: null });
        } else {
          // Fallback if no doc
          set({ user: firebaseUser, profile: null, isLoading: false, isInitialized: true, error: null });
        }
      } catch (err) {
        set({ user: firebaseUser, profile: null, isLoading: false, isInitialized: true, error: null });
      }
    } else {
      set({ user: null, profile: null, isLoading: false, isInitialized: true, error: null });
    }
  });

  return {
    user: null,
    profile: null,
    isLoading: false,
    isInitialized: false,
    error: null,

    clearError: () => set({ error: null }),

    login: async (email, password) => {
      set({ isLoading: true, error: null });
      try {
        await signInWithEmailAndPassword(auth, email, password);
        // The onAuthStateChanged will handle the rest
      } catch (error: any) {
        let msg = "Erreur de connexion";
        if (error.code === 'auth/user-not-found' || error.code === 'auth/wrong-password' || error.code === 'auth/invalid-credential') {
          msg = "Email ou mot de passe incorrect";
        }
        set({ error: msg, isLoading: false });
        throw error;
      }
    },

    register: async (email, password, name, company) => {
      set({ isLoading: true, error: null });
      try {
        const userCreds = await createUserWithEmailAndPassword(auth, email, password);
        const user = userCreds.user;

        const newProfile: UserProfile = {
          uid: user.uid,
          name,
          email,
          companyName: company,
          role: 'recruiter',
          createdAt: new Date().toISOString()
        };

        await setDoc(doc(db, 'users', user.uid), newProfile);
        // onAuthStateChanged will pick it up
      } catch (error: any) {
        let msg = "Erreur d'inscription";
        if (error.code === 'auth/email-already-in-use') {
          msg = "Cet email est déjà utilisé";
        }
        set({ error: msg, isLoading: false });
        throw error;
      }
    },

    logout: async () => {
      set({ isLoading: true });
      try {
        await signOut(auth);
      } catch (error) {
        console.error(error);
      } finally {
        set({ isLoading: false });
      }
    }
  };
});
