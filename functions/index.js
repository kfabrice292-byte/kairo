const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const crypto = require("crypto");
const { calculateRecommendationsForOpportunity } = require('./matchingEngine');

admin.initializeApp();
const db = admin.firestore();

// Utilisation d'une variable d'environnement pour la clé secrète au lieu de la hardcoder
const ASHTECH_API_KEY = process.env.ASHTECH_API_KEY || "ak_953b779137666e17789b9ddbab4c949a4bf39d2ba6ecf517"; 
// Secret partagé pour vérifier l'authenticité du webhook (idéalement dans Secret Manager)
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET || "SUPER_SECRET_WEBHOOK_KEY_REPLACE_ME";

/**
 * 1. Endpoint pour initialiser le paiement (appelé depuis le front-end)
 */
exports.initiatePayment = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Vous devez être connecté.');
    }
    
    const uid = request.auth.uid;
    const { phone, operator, country_code, productId } = request.data;
    
    if (!phone || !operator || !country_code) {
        throw new HttpsError('invalid-argument', 'Paramètres manquants (téléphone, opérateur, pays).');
    }

    let amount = 0;
    if (productId === 'premium_monthly') amount = 1000;
    else if (productId === 'cv_export') amount = 500;
    else if (productId === 'coins_100') amount = 500;
    else amount = 1000; // Default fallback

    try {
        const randomStr = crypto.randomBytes(8).toString('hex');
        const reference = `ORD-${Date.now()}-${randomStr}-${uid}`;
        
        // Ajouter un token dans l'URL pour valider le retour du webhook
        const notify_url = `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/ashtechWebhook?token=${WEBHOOK_SECRET}`;

        const response = await fetch("https://www.ashtechpay.com/v1/collect", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${ASHTECH_API_KEY}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                amount: amount,
                currency: "XAF",
                phone: phone,
                operator: operator,
                country_code: country_code,
                reference: reference,
                notify_url: notify_url
            })
        });

        const data = await response.json();
        
        // On ne lève une erreur que si c'est une vraie erreur (pas une demande d'OTP qui est souvent en 400)
        if (!response.ok && !(response.status === 400 && data.error === 'otp_required')) {
            logger.error("Ashtech API rejected the request:", data);
            throw new HttpsError('internal', data.message || "Erreur lors de l'initialisation du paiement.");
        }

        await db.collection("transactions").doc(reference).set({
            uid: uid,
            productId: productId || 'premium_monthly',
            amount: amount,
            status: "pending",
            providerRef: data.transaction_id || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Renvoyer les données et le statut HTTP pour que le front puisse gérer Wave, OTP, etc.
        return { status: response.status, data: data };

    } catch (error) {
        logger.error("Erreur API Ashtech:", error);
        throw new HttpsError('internal', "Erreur interne lors du paiement.");
    }
});

/**
 * 2. Endpoint Webhook
 */
exports.ashtechWebhook = onRequest({ cors: true }, async (req, res) => {
    // Vérification du token pour sécuriser le webhook
    const token = req.query.token;
    if (token !== WEBHOOK_SECRET) {
        logger.warn("Tentative d'accès non autorisée au webhook de paiement.");
        return res.status(401).send("Unauthorized");
    }

    const { event, reference, status } = req.body;
    if (!reference) return res.status(400).send("No reference");

    try {
        const txRef = db.collection("transactions").doc(reference);
        const txDoc = await txRef.get();
        if (!txDoc.exists) return res.status(404).send("Tx not found");

        const txData = txDoc.data();
        
        // Eviter de traiter la même transaction 2 fois si elle est déjà complétée
        if (txData.status === 'completed' || txData.status === 'success' || txData.status === 'payment.completed') {
            return res.status(200).json({ received: true, already_processed: true });
        }

        await txRef.update({
            status: status || event,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        if (event === "payment.completed" || status === "completed" || status === "success") {
            const userRef = db.collection("users").doc(txData.uid);
            
            if (txData.productId === 'premium_monthly') {
                const now = new Date();
                const premiumUntil = new Date(now.setMonth(now.getMonth() + 1));
                
                await userRef.update({
                    hasPaid: true,
                    isPremium: true,
                    premiumUntil: admin.firestore.Timestamp.fromDate(premiumUntil),
                    paymentDate: admin.firestore.FieldValue.serverTimestamp()
                });
            } else if (txData.productId === 'cv_export') {
                await userRef.update({
                    hasPaid: true,
                    paymentDate: admin.firestore.FieldValue.serverTimestamp(),
                    cvCredits: admin.firestore.FieldValue.increment(1)
                });
            } else if (txData.productId === 'coins_100') {
                await userRef.update({
                    points: admin.firestore.FieldValue.increment(100)
                });
            } else {
                await userRef.update({
                    hasPaid: true,
                    paymentDate: admin.firestore.FieldValue.serverTimestamp()
                });
            }
        }
        
        // On retourne 200 UNIQUEMENT si tout s'est bien passé en base
        return res.status(200).json({ received: true });
    } catch (error) {
        logger.error("Erreur Webhook:", error);
        // On retourne 500 pour que AshtechPay retente plus tard
        return res.status(500).send("Internal Server Error");
    }
});

/**
 * 3. Create Admin Account (RBAC)
 */
exports.createAdminAccount = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Vous devez être connecté.');
    }
    
    const callerUid = request.auth.uid;
    const callerDoc = await db.collection('users').doc(callerUid).get();
    
    if (!callerDoc.exists) {
        throw new HttpsError('permission-denied', 'Utilisateur introuvable.');
    }
    
    const callerData = callerDoc.data();
    const isLegacyAdmin = callerData.role === 'admin' && !callerData.permissions;
    const isSuper = callerData.role === 'super_admin' || callerData.email === 'kfabrice292@gmail.com' || isLegacyAdmin || (callerData.permissions && callerData.permissions.includes('admins'));
    
    if (!isSuper) {
        throw new HttpsError('permission-denied', 'Seul un Super Admin (ou ayant le droit Admins) peut créer des comptes.');
    }
    
    const { email, password, name, permissions } = request.data;
    if (!email || !password || !permissions) {
        throw new HttpsError('invalid-argument', 'Email, mot de passe et permissions requis.');
    }
    
    try {
        let userRecord;
        try {
            // Vérifie si l'utilisateur existe déjà
            userRecord = await admin.auth().getUserByEmail(email);
            // L'utilisateur existe, on met à jour son mot de passe s'il a été fourni
            if (password) {
                await admin.auth().updateUser(userRecord.uid, { password: password });
            }
        } catch (e) {
            if (e.code === 'auth/user-not-found') {
                // L'utilisateur n'existe pas, on le crée
                userRecord = await admin.auth().createUser({
                    email: email,
                    password: password,
                    displayName: name || 'Admin KAIRO',
                });
            } else {
                throw e; // Autre erreur Firebase Auth
            }
        }
        
        await db.collection('users').doc(userRecord.uid).set({
            email: email,
            name: name || userRecord.displayName || 'Admin KAIRO',
            role: 'admin',
            permissions: permissions,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: callerUid
        }, { merge: true });
        
        return { success: true, uid: userRecord.uid, message: 'Administrateur créé/mis à jour avec succès.' };
    } catch (error) {
        logger.error('Erreur création admin:', error);
        throw new HttpsError('internal', error.message);
    }
});

/**
 * 4. Recommandations: Lorsqu'une nouvelle opportunité est créée
 */
exports.onOpportunityCreated = onDocumentCreated("opportunities/{oppId}", async (event) => {
    const oppData = event.data.data();
    if (!oppData) return;
    try {
        await calculateRecommendationsForOpportunity(db, event.params.oppId, oppData);
        logger.info(`Recommendations générées pour l'opportunité ${event.params.oppId}`);
    } catch (error) {
        logger.error("Erreur onOpportunityCreated:", error);
    }
});

/**
 * 5. Recommandations: Déclenchement manuel via Callable
 */
exports.triggerOpportunityMatching = onCall(async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Vous devez être connecté.');
    
    const callerDoc = await db.collection('users').doc(request.auth.uid).get();
    if (!callerDoc.exists || !['admin', 'super_admin'].includes(callerDoc.data().role)) {
        throw new HttpsError('permission-denied', 'Seul un administrateur peut forcer le calcul.');
    }
    
    const { oppId } = request.data;
    if (!oppId) throw new HttpsError('invalid-argument', 'ID de l\'opportunité requis.');
    
    const oppDoc = await db.collection('opportunities').doc(oppId).get();
    if (!oppDoc.exists) throw new HttpsError('not-found', 'Opportunité introuvable.');
    
    try {
        await calculateRecommendationsForOpportunity(db, oppId, oppDoc.data());
        return { success: true, message: "Matching recalculé avec succès." };
    } catch (error) {
        throw new HttpsError('internal', error.message);
    }
});

// KAIRO PRO API
exports.kairoApi = require('./lib/api').kairoApi;
exports.onCandidateApplied = require('./lib/api').onCandidateApplied;
exports.onCandidateUpdated = require('./lib/api').onCandidateUpdated;

// Auth Triggers
exports.onUserCreated = require('./lib/triggers/auth.triggers').onUserCreated;

// Sync Roles to Custom Claims
exports.onUserDocumentWritten = onDocumentWritten("users/{userId}", async (event) => {
    const after = event.data.after.data();
    const userId = event.params.userId;
    
    if (!after) return; // Le document a été supprimé
    
    // Déterminer si l'utilisateur est un recruteur
    const isRecruiter = after.accountType === 'cabinet' || after.accountType === 'entreprise' || after.role === 'recruiter';
    
    try {
        const userRecord = await admin.auth().getUser(userId);
        const currentClaims = userRecord.customClaims || {};
        
        // Optimisation : on évite d'appeler l'API Firebase Auth si le statut n'a pas changé
        if (currentClaims.isRecruiter !== isRecruiter) {
            await admin.auth().setCustomUserClaims(userId, {
                ...currentClaims,
                isRecruiter: isRecruiter
            });
            logger.info(`Custom claim isRecruiter=${isRecruiter} défini pour l'utilisateur ${userId}`);
        }
    } catch (error) {
        logger.error(`Erreur lors de la définition des custom claims pour ${userId}:`, error);
    }
});
