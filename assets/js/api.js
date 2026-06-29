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

    // --- DOCUMENTS (HISTORY & PERSISTENCE) ---
    async saveDocument(docData, docId = null) {
        const user = auth.currentUser;
        if (!user) throw new Error("Non autorisé");

        try {
            const docsRef = collection(db, "users", user.uid, "documents");
            const dataToSave = {
                ...docData,
                updatedAt: new Date().toISOString()
            };
            
            if (docId) {
                await setDoc(doc(docsRef, docId), dataToSave, { merge: true });
                return docId;
            } else {
                dataToSave.createdAt = new Date().toISOString();
                const newDocRef = await addDoc(docsRef, dataToSave);
                return newDocRef.id;
            }
        } catch (error) {
            console.error("Save document error:", error);
            throw new Error("Impossible de sauvegarder le document.");
        }
    },

    async getDocuments() {
        const user = auth.currentUser;
        if (!user) return [];

        try {
            const docsRef = collection(db, "users", user.uid, "documents");
            const snapshot = await getDocs(docsRef);
            const docs = [];
            snapshot.forEach(doc => {
                docs.push({ id: doc.id, ...doc.data() });
            });
            // Sort by updatedAt descending
            return docs.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
        } catch (error) {
            console.error("Get documents error:", error);
            return [];
        }
    },

    async getDocument(docId) {
        const user = auth.currentUser;
        if (!user) return null;

        try {
            const docRef = doc(db, "users", user.uid, "documents", docId);
            const docSnap = await getDoc(docRef);
            if (docSnap.exists()) {
                return { id: docSnap.id, ...docSnap.data() };
            }
            return null;
        } catch (error) {
            console.error("Get document error:", error);
            return null;
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
