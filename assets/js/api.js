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
                    cvCredits: 0,
                    documents: [],
                    role: 'user',
                    isPremium: false,
                    subscriptionStatus: 'FREE',
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
            if (error.code === 'auth/invalid-credential' || error.code === 'auth/wrong-password') {
                throw new Error("Email ou mot de passe incorrect.");
            } else if (error.code === 'auth/user-not-found') {
                throw new Error("Aucun compte trouvé avec cet email.");
            } else if (error.code === 'auth/too-many-requests') {
                throw new Error("Compte temporairement bloqué suite à plusieurs échecs. Réessayez plus tard.");
            }
            throw new Error("Erreur de connexion. Veuillez réessayer.");
        }
    },

    async register(name, email, password) {
        try {
            const userCredential = await createUserWithEmailAndPassword(auth, email, password);
            const uid = userCredential.user.uid;
            
            const newUser = {
                name,
                email,
                cvCredits: 0,
                documents: [],
                role: 'user',
                isPremium: false,
                subscriptionStatus: 'FREE',
                createdAt: new Date().toISOString()
            };

            // Save user profile to Firestore
            await setDoc(doc(db, "users", uid), newUser);
            return { uid, ...newUser };
        } catch (error) {
            console.error("Register error:", error);
            if (error.code === 'auth/email-already-in-use') {
                throw new Error("Cet email est déjà utilisé par un autre compte.");
            } else if (error.code === 'auth/weak-password') {
                throw new Error("Le mot de passe est trop faible (6 caractères minimum).");
            } else if (error.code === 'auth/invalid-email') {
                throw new Error("L'adresse email n'est pas valide.");
            }
            throw new Error("Erreur lors de l'inscription. Veuillez réessayer.");
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
    async unlockPremium() {
        try {
            return await this.updateProfile({ hasPaid: true });
        } catch (error) {
            console.error("Unlock error:", error);
            throw new Error("Impossible de valider le paiement.");
        }
    },

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
            const formData = new FormData();
            formData.append("image", file);
            // Kairo ImgBB API Key
            const apiKey = "42583eab8962481f83526a0882f3d384";
            
            const response = await fetch(`https://api.imgbb.com/1/upload?key=${apiKey}`, {
                method: "POST",
                body: formData
            });
            
            const data = await response.json();
            if (!data.success) {
                throw new Error("ImgBB upload failed");
            }
            
            const downloadURL = data.data.url;
            
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
            
            if (docId && !docId.startsWith('local_')) {
                await setDoc(doc(docsRef, docId), dataToSave, { merge: true });
                return docId;
            } else if (!docId || !docId.startsWith('local_')) {
                dataToSave.createdAt = new Date().toISOString();
                const newDocRef = await addDoc(docsRef, dataToSave);
                return newDocRef.id;
            }
        } catch (error) {
            console.warn("Firestore write blocked (permissions), falling back to localStorage", error);
        }
        
        // Fallback to localStorage if Firestore failed or if doc is already local
        const localId = docId || 'local_' + Date.now();
        const localDocs = JSON.parse(localStorage.getItem('kairo_local_docs') || '{}');
        localDocs[localId] = { ...docData, updatedAt: new Date().toISOString(), id: localId };
        localStorage.setItem('kairo_local_docs', JSON.stringify(localDocs));
        return localId;
    },

    async getDocuments() {
        const user = auth.currentUser;
        if (!user) return [];

        let docs = [];
        try {
            const docsRef = collection(db, "users", user.uid, "documents");
            const snapshot = await getDocs(docsRef);
            snapshot.forEach(doc => {
                docs.push({ id: doc.id, ...doc.data() });
            });
        } catch (error) {
            console.warn("Firestore read blocked, using local storage fallback", error);
        }
        
        // Merge with local storage
        const localDocs = JSON.parse(localStorage.getItem('kairo_local_docs') || '{}');
        Object.values(localDocs).forEach(ld => {
            if (!docs.find(d => d.id === ld.id)) docs.push(ld);
        });

        return docs.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    },

    async getDocument(docId) {
        const user = auth.currentUser;
        if (!user) return null;

        if (docId.startsWith('local_')) {
            const localDocs = JSON.parse(localStorage.getItem('kairo_local_docs') || '{}');
            return localDocs[docId] || null;
        }

        try {
            const docRef = doc(db, "users", user.uid, "documents", docId);
            const docSnap = await getDoc(docRef);
            if (docSnap.exists()) {
                return { id: docSnap.id, ...docSnap.data() };
            }
        } catch (error) {
            console.warn("Get document error:", error);
        }
        
        // Fallback check
        const localDocs = JSON.parse(localStorage.getItem('kairo_local_docs') || '{}');
        return localDocs[docId] || null;
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

    async getPublicUserProfile(uid) {
        try {
            const userDoc = await getDoc(doc(db, "users", uid));
            if (userDoc.exists()) {
                return { uid: userDoc.id, ...userDoc.data() };
            }
            return null;
        } catch (error) {
            console.error("Error fetching public profile:", error);
            return null;
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
            const fullOpportunity = {
                ...opportunity,
                description: opportunity.description || '',
                status: 'ouvert',
                createdAt: new Date(),
                applicants: [],
                mandatorySkills: [],
                postedBy: auth.currentUser ? auth.currentUser.uid : 'Admin'
            };
            const docRef = await addDoc(collection(db, "opportunities"), fullOpportunity);
            return { id: docRef.id, ...fullOpportunity };
        } catch (error) {
            console.error("Publish opportunity error:", error);
            throw new Error("Erreur lors de la publication.");
        }
    },

    // --- PROMO CODES ---
    async getPromoCodes() {
        try {
            const querySnapshot = await getDocs(collection(db, "promo_codes"));
            const codes = [];
            querySnapshot.forEach((doc) => {
                codes.push({ id: doc.id, ...doc.data() });
            });
            return codes;
        } catch (error) {
            console.error("Get promo codes error:", error);
            return [];
        }
    },

    async createPromoCode(promoData) {
        try {
            const fullPromo = {
                code: promoData.code.toUpperCase().trim(),
                type: promoData.type || 'SINGLE', // 'SINGLE', 'UNLIMITED'
                currentUses: 0,
                maxUses: parseInt(promoData.maxUses) || 1,
                durationDays: parseInt(promoData.durationDays) || 30,
                expiresAt: promoData.expiresAt ? new Date(promoData.expiresAt) : null,
                createdAt: new Date(),
                createdBy: auth.currentUser ? auth.currentUser.uid : 'Admin'
            };
            const docRef = await addDoc(collection(db, "promo_codes"), fullPromo);
            return { id: docRef.id, ...fullPromo };
        } catch (error) {
            console.error("Create promo code error:", error);
            throw new Error("Erreur lors de la création du code promo.");
        }
    },

    async applyPromoCode(code) {
        try {
            if (!auth.currentUser) throw new Error("Non connecté.");
            const uid = auth.currentUser.uid;
            
            // Chercher le code
            const q = query(collection(db, "promo_codes"), where("code", "==", code.toUpperCase().trim()));
            const querySnapshot = await getDocs(q);
            
            if (querySnapshot.empty) {
                throw new Error("Code promo invalide ou introuvable.");
            }
            
            const promoDoc = querySnapshot.docs[0];
            const promoData = promoDoc.data();
            
            // Vérifier validité
            if (promoData.currentUses >= promoData.maxUses) {
                throw new Error("Ce code promo a atteint sa limite d'utilisation.");
            }
            
            if (promoData.expiresAt && promoData.expiresAt.toDate() < new Date()) {
                throw new Error("Ce code promo a expiré.");
            }

            // Vérifier si l'utilisateur ne l'a pas déjà utilisé (On pourrait ajouter une sous-collection 'usages', on fait simple ici)
            
            // Appliquer le Premium à l'utilisateur
            const userRef = doc(db, "users", uid);
            const userSnap = await getDoc(userRef);
            if(userSnap.exists() && userSnap.data().isPremium) {
                throw new Error("Vous êtes déjà Premium !");
            }

            const now = new Date();
            const premiumUntil = new Date(now.getTime() + (promoData.durationDays || 30) * 24 * 60 * 60 * 1000);

            // Transaction / Batch
            const batch = writeBatch(db);
            
            // 1. Maj utilisateur
            batch.update(userRef, {
                isPremium: true,
                premiumUntil: premiumUntil,
                subscriptionStatus: 'PREMIUM_PROMO',
                usedPromoCode: promoData.code
            });

            // 2. Incrémenter le compteur du code
            batch.update(promoDoc.ref, {
                currentUses: promoData.currentUses + 1
            });

            await batch.commit();
            return { success: true, message: "Code activé avec succès ! Vous êtes Premium." };

        } catch (error) {
            console.error("Apply promo error:", error);
            throw new Error(error.message || "Erreur lors de l'application du code.");
        }
    }
};

// Expose API globally so standard scripts (like auth.js) can use it easily,
// but it's recommended to import it instead.
window.API = API;
export default API;
