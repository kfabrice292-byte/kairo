import { auth, db, storage } from './firebase-config.js';
import { 
    signInWithEmailAndPassword, 
    createUserWithEmailAndPassword, 
    signOut, 
    onAuthStateChanged,
    GoogleAuthProvider,
    signInWithPopup
} from "firebase/auth";
import { 
    doc, 
    setDoc, 
    getDoc, 
    updateDoc, 
    collection, 
    getDocs, 
    addDoc 
} from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";

const API = {
    // --- AUTHENTICATION ---
    async loginWithGoogle() {
        try {
            const provider = new GoogleAuthProvider();
            const result = await signInWithPopup(auth, provider);
            const user = result.user;

            const userRef = doc(db, "users", user.uid);
            const userDoc = await getDoc(userRef);

            if (!userDoc.exists()) {
                const newUser = {
                    name: user.displayName || 'Utilisateur',
                    email: user.email,
                    photoURL: user.photoURL || null,
                    points: 1000,
                    history: [],
                    createdAt: new Date().toISOString()
                };
                await setDoc(userRef, newUser);
                return { uid: user.uid, ...newUser };
            }
            return { uid: user.uid, ...userDoc.data() };
        } catch (error) {
            console.error("Google login error:", error);
            throw new Error("Erreur lors de la connexion avec Google.");
        }
    },

    async login(email, password) {
        try {
            const userCredential = await signInWithEmailAndPassword(auth, email, password);
            // Fetch user profile from Firestore
            const userDoc = await getDoc(doc(db, "users", userCredential.user.uid));
            if (userDoc.exists()) {
                return { uid: userCredential.user.uid, ...userDoc.data() };
            }
            return { uid: userCredential.user.uid, email };
        } catch (error) {
            console.error("Login error:", error);
            throw new Error("Email ou mot de passe incorrect.");
        }
    },

    async register(name, email, password) {
        try {
            const userCredential = await createUserWithEmailAndPassword(auth, email, password);
            const uid = userCredential.user.uid;
            
            const newUser = {
                name,
                email,
                points: 1000,
                history: [],
                createdAt: new Date().toISOString()
            };

            // Save user profile to Firestore
            await setDoc(doc(db, "users", uid), newUser);
            return { uid, ...newUser };
        } catch (error) {
            console.error("Register error:", error);
            if (error.code === 'auth/email-already-in-use') {
                throw new Error("Cet email est déjà utilisé.");
            }
            throw new Error("Erreur lors de l'inscription.");
        }
    },

    getCurrentUser() {
        return new Promise((resolve, reject) => {
            const unsubscribe = onAuthStateChanged(auth, async (user) => {
                unsubscribe();
                if (user) {
                    try {
                        const userDoc = await getDoc(doc(db, "users", user.uid));
                        if (userDoc.exists()) {
                            resolve({ uid: user.uid, ...userDoc.data() });
                        } else {
                            resolve({ uid: user.uid, email: user.email });
                        }
                    } catch (error) {
                        resolve(null);
                    }
                } else {
                    resolve(null);
                }
            }, reject);
        });
    },

    async logout() {
        try {
            await signOut(auth);
            // Optional: clear any local preferences if necessary
            localStorage.removeItem('kairo_user_session'); // Assuming any legacy usage
        } catch (error) {
            console.error("Logout error:", error);
        }
    },

    // --- USERS & PROFILE ---
    async updateProfile(updates) {
        const user = auth.currentUser;
        if (!user) throw new Error("Non autorisé");

        try {
            const userRef = doc(db, "users", user.uid);
            await updateDoc(userRef, updates);
            
            // Return updated user
            const updatedDoc = await getDoc(userRef);
            return { uid: user.uid, ...updatedDoc.data() };
        } catch (error) {
            console.error("Profile update error:", error);
            throw new Error("Impossible de mettre à jour le profil.");
        }
    },

    async uploadAvatar(file) {
        const user = auth.currentUser;
        if (!user) throw new Error("Non autorisé");

        try {
            const storageRef = ref(storage, `avatars/${user.uid}_${Date.now()}_${file.name}`);
            await uploadBytes(storageRef, file);
            const downloadURL = await getDownloadURL(storageRef);
            
            // Update the user's profile with the new photo URL
            return await this.updateProfile({ photoURL: downloadURL });
        } catch (error) {
            console.error("Avatar upload error:", error);
            throw new Error("Erreur lors du téléversement de l'image.");
        }
    },

    async addHistoryItem(documentType, title) {
        const user = auth.currentUser;
        if (!user) return;

        try {
            const userRef = doc(db, "users", user.uid);
            const userDoc = await getDoc(userRef);
            
            if (userDoc.exists()) {
                const userData = userDoc.data();
                const history = userData.history || [];
                let points = userData.points || 0;
                
                history.unshift({
                    type: documentType,
                    title: title,
                    date: new Date().toLocaleDateString('fr-FR')
                });
                
                if (points >= 100) points -= 100;
                
                await updateDoc(userRef, { history, points });
                return { uid: user.uid, ...userData, history, points };
            }
        } catch (error) {
            console.error("History update error:", error);
        }
    },

    async getAllUsers() {
        try {
            const querySnapshot = await getDocs(collection(db, "users"));
            const users = [];
            querySnapshot.forEach((doc) => {
                users.push({ uid: doc.id, ...doc.data() });
            });
            return users;
        } catch (error) {
            console.error("Get all users error:", error);
            return [];
        }
    },

    // --- OPPORTUNITIES ---
    async getOpportunities() {
        try {
            const querySnapshot = await getDocs(collection(db, "opportunities"));
            const opps = [];
            querySnapshot.forEach((doc) => {
                opps.push({ id: doc.id, ...doc.data() });
            });
            return opps;
        } catch (error) {
            console.error("Get opportunities error:", error);
            return [];
        }
    },

    async publishOpportunity(opportunity) {
        try {
            const docRef = await addDoc(collection(db, "opportunities"), opportunity);
            return { id: docRef.id, ...opportunity };
        } catch (error) {
            console.error("Publish opportunity error:", error);
            throw new Error("Erreur lors de la publication.");
        }
    }
};

// Expose API globally so standard scripts (like auth.js) can use it easily,
// but it's recommended to import it instead.
window.API = API;
export default API;
