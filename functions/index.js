const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

// Remplacez par votre vraie clé en production (utilisez firebase config ou Google Cloud Secret Manager)
const ASHTECH_API_KEY = "VOTRE_CLE_ASHTECH_ICI"; 

/**
 * 1. Endpoint pour initialiser le paiement (appelé depuis le front-end)
 * Reçoit: uid, amount, phone, operator, country_code
 */
exports.initiatePayment = onRequest({ cors: true }, async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

    const { uid, phone, operator, country_code } = req.body;
    if (!uid || !phone || !operator || !country_code) {
        return res.status(400).json({ error: "Paramètres manquants" });
    }

    try {
        const amount = 1000; // 1000 FCFA
        const reference = `ORD-${Date.now()}-${uid}`;
        // L'URL publique de la fonction webhook une fois déployée.
        // Remplacez 'us-central1-VOTRE-PROJET.cloudfunctions.net' par votre vraie URL
        const notify_url = `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/ashtechWebhook`;

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

        // Enregistrer la transaction dans la BDD pour la traçabilité
        await db.collection("transactions").doc(reference).set({
            uid: uid,
            amount: amount,
            status: "pending",
            providerRef: data.transaction_id || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        res.status(response.status).json(data);

    } catch (error) {
        console.error("Erreur API Ashtech:", error);
        res.status(500).json({ error: "Erreur interne" });
    }
});

/**
 * 2. Endpoint Webhook appelé par AshtechPay quand le paiement est fini (succès ou échec)
 */
exports.ashtechWebhook = onRequest({ cors: true }, async (req, res) => {
    // Il faut toujours répondre 200 immédiatement (voir la doc Ashtech)
    res.status(200).json({ received: true });

    const { event, reference, status } = req.body;

    if (!reference) return;

    try {
        const txRef = db.collection("transactions").doc(reference);
        const txDoc = await txRef.get();
        if (!txDoc.exists) return; // Transaction inconnue

        const txData = txDoc.data();

        // Mise à jour de la transaction
        await txRef.update({
            status: status || event,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Si le paiement est un succès complet
        if (event === "payment.completed" || status === "completed" || status === "success") {
            const userRef = db.collection("users").doc(txData.uid);
            await userRef.update({
                hasPaid: true,
                paymentDate: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log(`Utilisateur ${txData.uid} débloqué avec succès.`);
        }
    } catch (error) {
        console.error("Erreur Webhook:", error);
    }
});
