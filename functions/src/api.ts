import * as functions from 'firebase-functions';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';
import express from 'express';
import cors from 'cors';

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

const db = admin.firestore();

// Middleware: API Key Validation
// For KAIRO PRO API, companies use an API key to authenticate their requests.
const validateApiKey = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
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
    (req as any).agencyId = agencyId;
    next();
  } catch (error) {
    logger.error('API Key validation error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

app.use(validateApiKey);

// ----------------------------------------------------------------------
// ENDPOINT: POST /api/v1/opportunities
// Create a new opportunity (job offer) on KAIRO
// ----------------------------------------------------------------------
app.post('/api/v1/opportunities', async (req: express.Request, res: express.Response) => {
  try {
    const agencyId = (req as any).agencyId;
    const { title, description, location, type, salary, requirements } = req.body;

    if (!title || !description || !location) {
      return res.status(400).json({ error: 'Missing required fields: title, description, location' });
    }

    // BUSINESS RULE: Freemium B2B = 1 active opportunity limit. Premium = 50 limit.
    const agencyDoc = await db.collection('agencies').doc(agencyId).get();
    const isPremium = agencyDoc.data()?.isPremium === true;
    const limit = isPremium ? 50 : 1;

    const activeOpsSnapshot = await db.collection('opportunities')
      .where('companyId', '==', agencyId)
      .where('status', '==', 'open')
      .count()
      .get();
      
    if (activeOpsSnapshot.data().count >= limit) {
      return res.status(403).json({ 
        error: `Quota reached. Freemium limit is 1, Premium limit is 50. You currently have ${activeOpsSnapshot.data().count} active opportunities.` 
      });
    }

    const newOpp = {
      title,
      description,
      location,
      type: type || 'CDI',
      salary: salary || 'Non spécifié',
      requirements: Array.isArray(requirements) ? requirements : [],
      companyId: agencyId, 
      status: 'open', // STANDARD: 'open', 'closed', 'draft'
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('opportunities').add(newOpp);

    res.status(201).json({
      message: 'Opportunity created successfully',
      id: docRef.id
    });
  } catch (error) {
    logger.error('Error creating opportunity:', error);
    res.status(500).json({ error: 'Failed to create opportunity' });
  }
});

// ----------------------------------------------------------------------
// ENDPOINT: GET /api/v1/opportunities
// Retrieve all opportunities for the authenticated agency
// ----------------------------------------------------------------------
app.get('/api/v1/opportunities', async (req: express.Request, res: express.Response) => {
  try {
    const agencyId = (req as any).agencyId;
    
    const snapshot = await db.collection('opportunities')
      .where('companyId', '==', agencyId)
      .orderBy('createdAt', 'desc')
      .get();

    const opportunities: any[] = [];
    snapshot.forEach(doc => {
      opportunities.push({
        id: doc.id,
        ...doc.data()
      });
    });

    res.status(200).json({ data: opportunities });
  } catch (error) {
    logger.error('Error fetching opportunities:', error);
    res.status(500).json({ error: 'Failed to fetch opportunities' });
  }
});

// ----------------------------------------------------------------------
// ENDPOINT: GET /api/v1/opportunities/:opportunityId/candidates
// Retrieve all candidates for a specific opportunity
// ----------------------------------------------------------------------
app.get('/api/v1/opportunities/:opportunityId/candidates', async (req: express.Request, res: express.Response) => {
  try {
    const agencyId = (req as any).agencyId;
    const opportunityId = req.params.opportunityId as string;

    // Verify opportunity belongs to agency
    const oppDoc = await db.collection('opportunities').doc(opportunityId).get();
    if (!oppDoc.exists || oppDoc.data()?.companyId !== agencyId) {
      return res.status(403).json({ error: 'Forbidden: Opportunity not found or access denied' });
    }

    const snapshot = await db.collection('opportunities').doc(opportunityId).collection('applicants').get();
    
    const candidates: any[] = [];
    snapshot.forEach(doc => {
      candidates.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({ data: candidates });
  } catch (error) {
    logger.error('Error fetching candidates:', error);
    res.status(500).json({ error: 'Failed to fetch candidates' });
  }
});

// ----------------------------------------------------------------------
// ENDPOINT: PATCH /api/v1/opportunities/:opportunityId/candidates/:candidateId/status
// Update a candidate's status in the KAIRO ATS pipeline
// ----------------------------------------------------------------------
app.patch('/api/v1/opportunities/:opportunityId/candidates/:candidateId/status', async (req: express.Request, res: express.Response) => {
  try {
    const agencyId = (req as any).agencyId;
    const opportunityId = req.params.opportunityId as string;
    const candidateId = req.params.candidateId as string;
    const { status } = req.body;

    const validStatuses = ['new', 'evaluating', 'interview', 'hired', 'rejected'];
    if (!status || !validStatuses.includes(status)) {
      return res.status(400).json({ error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` });
    }

    // Verify opportunity belongs to agency
    const oppDoc = await db.collection('opportunities').doc(opportunityId).get();
    if (!oppDoc.exists || oppDoc.data()?.companyId !== agencyId) {
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
  } catch (error) {
    logger.error('Error updating candidate status:', error);
    res.status(500).json({ error: 'Failed to update candidate status' });
  }
});

export const kairoApi = functions.https.onRequest(app);

// ----------------------------------------------------------------------
// WEBHOOK TRIGGER: onCandidateApplied
// Triggered when a new document is created in the applicants subcollection.
// ----------------------------------------------------------------------
export const onCandidateApplied = functions.firestore
  .document('opportunities/{opportunityId}/applicants/{candidateId}')
  .onCreate(async (snapshot, context) => {
    try {
      const { opportunityId, candidateId } = context.params;
      const applicantData = snapshot.data();

      // 1. Find the opportunity to get the agency ID
      const oppDoc = await db.collection('opportunities').doc(opportunityId).get();
      if (!oppDoc.exists) return;

      const oppData = oppDoc.data();
      const companyId = oppData?.companyId;
      if (!companyId) return;

      // 2. Find the agency to check for a webhook URL
      const agencyDoc = await db.collection('agencies').doc(companyId).get();
      if (!agencyDoc.exists) return;

      const agencyData = agencyDoc.data();
      const webhookUrl = agencyData?.webhookUrl;
      
      // If the agency hasn't configured a webhook, do nothing
      if (!webhookUrl) return;

      // 3. Send the payload to the agency's webhook URL
      const payload = {
        event: 'candidate.applied',
        opportunityId,
        opportunityTitle: oppData.title,
        candidateId,
        candidateDetails: applicantData,
        timestamp: new Date().toISOString()
      };

      // Configuration du timeout
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 secondes timeout

      try {
        const response = await fetch(webhookUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
          signal: controller.signal
        });

        if (!response.ok) {
          logger.error(`Webhook échoué pour ${webhookUrl} (Status: ${response.status})`);
        } else {
          logger.info(`Webhook envoyé à ${webhookUrl} pour candidat ${candidateId}. Status: ${response.status}`);
        }
      } catch (fetchError: any) {
        if (fetchError.name === 'AbortError') {
          logger.error(`Webhook timeout après 10s pour ${webhookUrl}`);
        } else {
          logger.error(`Erreur réseau Webhook vers ${webhookUrl}:`, fetchError);
        }
        // Throwing error allows Firebase Functions to retry if "Retry on failure" is enabled in Google Cloud Console
        throw fetchError; 
      } finally {
        clearTimeout(timeoutId);
      }
    } catch (error) {
      logger.error('Error processing candidate webhook:', error);
      // Let it fail gracefully or throw if we want global retry
    }
  });

