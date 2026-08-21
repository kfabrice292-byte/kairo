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
exports.kairoApi = void 0;
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
exports.kairoApi = functions.https.onRequest(app);
//# sourceMappingURL=api.js.map