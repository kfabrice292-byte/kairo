const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const crypto = require("crypto");
const { calculateRecommendationsForOpportunity } = require('./matchingEngine');

admin.initializeApp();
const db = admin.firestore();

// Utilisation d'une variable d'environnement pour la clé secrète au lieu de la hardcoder
const ASHTECH_API_KEY = process.env.ASHTECH_API_KEY || "VOTRE_CLE_ASHTECH_ICI"; 
// Secret partagé pour vérifier l'authenticité du webhook (idéalement dans Secret Manager)
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET || "SUPER_SECRET_WEBHOOK_KEY_REPLACE_ME";

/**
 * 1. Endpoint pour initialiser le paiement (appelé depuis le front-end)
 */
exports.initiatePayment = onRequest({ cors: true }, async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

    const { uid, phone, operator, country_code } = req.body;
    if (!uid || !phone || !operator || !country_code) {
        return res.status(400).json({ error: "Paramètres manquants" });
    }

    try {
        const amount = 1000;
        // Rendre la référence imprévisible pour éviter le spoofing
        const randomStr = crypto.randomBytes(8).toString('hex');
        const reference = `ORD-${Date.now()}-${randomStr}-${uid}`;
        // Ajouter un token dans l'URL pour valider le retour du webhook
        const notify_url = `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/ashtechWebhook?token=${WEBHOOK_SECRET}`;

        const response = await fetch("https://ashtechpay.top/v1/collect", {
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

        await db.collection("transactions").doc(reference).set({
            uid: uid,
            amount: amount,
            status: "pending",
            providerRef: data.transaction_id || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        res.status(response.status).json(data);

    } catch (error) {
        logger.error("Erreur API Ashtech:", error);
        res.status(500).json({ error: "Erreur interne" });
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

    res.status(200).json({ received: true });

    const { event, reference, status } = req.body;
    if (!reference) return;

    try {
        const txRef = db.collection("transactions").doc(reference);
        const txDoc = await txRef.get();
        if (!txDoc.exists) return;

        const txData = txDoc.data();

        await txRef.update({
            status: status || event,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        if (event === "payment.completed" || status === "completed" || status === "success") {
            const userRef = db.collection("users").doc(txData.uid);
            await userRef.update({
                hasPaid: true,
                paymentDate: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    } catch (error) {
        logger.error("Erreur Webhook:", error);
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
