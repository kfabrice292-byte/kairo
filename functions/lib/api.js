"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.onCandidateApplied = exports.kairoApi = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const app = (0, express_1.default)();
app.use((0, cors_1.default)({ origin: true }));
app.use(express_1.default.json());
const db = admin.firestore();
// Middleware: API Key Validation
// For KAIRO PRO API, companies use an API key to authenticate their requests.
const validateApiKey = async (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    if (!apiKey || typeof apiKey !== 'string') {
        return res.status(401).json({ error: 'Unauthorized: Missing x-api-key header' });
    }
    try {
        // In production, we'd query a dedicated `api_keys` collection or `agencies` where apiKey == provided
        // For this prototype, we assume the API key is exactly the Agency ID to keep it simple,
        // or we look up the agency document by API key if it's stored inside it.
        // For simplicity of Day 3 prototype: Let's assume x-api-key is the agency ID.
        // In Day 4 we can create a real key generation system.
        const agencyId = apiKey;
        const agencyDoc = await db.collection('agencies').doc(agencyId).get();
        if (!agencyDoc.exists) {
            return res.status(401).json({ error: 'Unauthorized: Invalid API Key' });
        }
        // Attach agency ID to request
        req.agencyId = agencyId;
        next();
    }
    catch (error) {
        console.error('API Key validation error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};
app.use(validateApiKey);
// ----------------------------------------------------------------------
// ENDPOINT: POST /api/v1/opportunities
// Create a new opportunity (job offer) on KAIRO
// ----------------------------------------------------------------------
app.post('/api/v1/opportunities', async (req, res) => {
    try {
        const agencyId = req.agencyId;
        const { title, description, location, type, salary, requirements } = req.body;
        if (!title || !description || !location) {
            return res.status(400).json({ error: 'Missing required fields: title, description, location' });
        }
        const newOpp = {
            title,
            description,
            location,
            type: type || 'CDI',
            salary: salary || 'Non spécifié',
            requirements: Array.isArray(requirements) ? requirements : [],
            companyId: agencyId, // Link to the agency!
            status: 'active',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        const docRef = await db.collection('opportunities').add(newOpp);
        res.status(201).json({
            message: 'Opportunity created successfully',
            id: docRef.id
        });
    }
    catch (error) {
        console.error('Error creating opportunity:', error);
        res.status(500).json({ error: 'Failed to create opportunity' });
    }
});
// ----------------------------------------------------------------------
// ENDPOINT: GET /api/v1/opportunities
// Retrieve all opportunities for the authenticated agency
// ----------------------------------------------------------------------
app.get('/api/v1/opportunities', async (req, res) => {
    try {
        const agencyId = req.agencyId;
        const snapshot = await db.collection('opportunities')
            .where('companyId', '==', agencyId)
            .orderBy('createdAt', 'desc')
            .get();
        const opportunities = [];
        snapshot.forEach(doc => {
            opportunities.push(Object.assign({ id: doc.id }, doc.data()));
        });
        res.status(200).json({ data: opportunities });
    }
    catch (error) {
        console.error('Error fetching opportunities:', error);
        res.status(500).json({ error: 'Failed to fetch opportunities' });
    }
});
// ----------------------------------------------------------------------
// ENDPOINT: GET /api/v1/opportunities/:opportunityId/candidates
// Retrieve all candidates for a specific opportunity
// ----------------------------------------------------------------------
app.get('/api/v1/opportunities/:opportunityId/candidates', async (req, res) => {
    var _a;
    try {
        const agencyId = req.agencyId;
        const { opportunityId } = req.params;
        // Verify opportunity belongs to agency
        const oppDoc = await db.collection('opportunities').doc(opportunityId).get();
        if (!oppDoc.exists || ((_a = oppDoc.data()) === null || _a === void 0 ? void 0 : _a.companyId) !== agencyId) {
            return res.status(403).json({ error: 'Forbidden: Opportunity not found or access denied' });
        }
        const snapshot = await db.collection('opportunities').doc(opportunityId).collection('applicants').get();
        const candidates = [];
        snapshot.forEach(doc => {
            candidates.push(Object.assign({ id: doc.id }, doc.data()));
        });
        res.status(200).json({ data: candidates });
    }
    catch (error) {
        console.error('Error fetching candidates:', error);
        res.status(500).json({ error: 'Failed to fetch candidates' });
    }
});
// ----------------------------------------------------------------------
// ENDPOINT: PATCH /api/v1/opportunities/:opportunityId/candidates/:candidateId/status
// Update a candidate's status in the KAIRO ATS pipeline
// ----------------------------------------------------------------------
app.patch('/api/v1/opportunities/:opportunityId/candidates/:candidateId/status', async (req, res) => {
    var _a;
    try {
        const agencyId = req.agencyId;
        const { opportunityId, candidateId } = req.params;
        const { status } = req.body;
        const validStatuses = ['new', 'evaluating', 'interview', 'hired', 'rejected'];
        if (!status || !validStatuses.includes(status)) {
            return res.status(400).json({ error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` });
        }
        // Verify opportunity belongs to agency
        const oppDoc = await db.collection('opportunities').doc(opportunityId).get();
        if (!oppDoc.exists || ((_a = oppDoc.data()) === null || _a === void 0 ? void 0 : _a.companyId) !== agencyId) {
            return res.status(403).json({ error: 'Forbidden: Opportunity not found or access denied' });
        }
        const applicantRef = db.collection('opportunities').doc(opportunityId).collection('applicants').doc(candidateId);
        const applicantDoc = await applicantRef.get();
        if (!applicantDoc.exists) {
            return res.status(404).json({ error: 'Candidate not found' });
        }
        await applicantRef.update({
            status,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        res.status(200).json({ message: 'Candidate status updated successfully' });
    }
    catch (error) {
        console.error('Error updating candidate status:', error);
        res.status(500).json({ error: 'Failed to update candidate status' });
    }
});
exports.kairoApi = functions.https.onRequest(app);
// ----------------------------------------------------------------------
// WEBHOOK TRIGGER: onCandidateApplied
// Triggered when a new document is created in the applicants subcollection.
// ----------------------------------------------------------------------
exports.onCandidateApplied = functions.firestore
    .document('opportunities/{opportunityId}/applicants/{candidateId}')
    .onCreate(async (snapshot, context) => {
    try {
        const { opportunityId, candidateId } = context.params;
        const applicantData = snapshot.data();
        // 1. Find the opportunity to get the agency ID
        const oppDoc = await db.collection('opportunities').doc(opportunityId).get();
        if (!oppDoc.exists)
            return;
        const oppData = oppDoc.data();
        const companyId = oppData === null || oppData === void 0 ? void 0 : oppData.companyId;
        if (!companyId)
            return;
        // 2. Find the agency to check for a webhook URL
        const agencyDoc = await db.collection('agencies').doc(companyId).get();
        if (!agencyDoc.exists)
            return;
        const agencyData = agencyDoc.data();
        const webhookUrl = agencyData === null || agencyData === void 0 ? void 0 : agencyData.webhookUrl;
        // If the agency hasn't configured a webhook, do nothing
        if (!webhookUrl)
            return;
        // 3. Send the payload to the agency's webhook URL
        const payload = {
            event: 'candidate.applied',
            opportunityId,
            opportunityTitle: oppData.title,
            candidateId,
            candidateDetails: applicantData,
            timestamp: new Date().toISOString()
        };
        // Native fetch is available in Node 18+
        const response = await fetch(webhookUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        console.log(`Webhook sent to ${webhookUrl} for candidate ${candidateId}. Status: ${response.status}`);
    }
    catch (error) {
        console.error('Error processing candidate webhook:', error);
    }
});
//# sourceMappingURL=api.js.map