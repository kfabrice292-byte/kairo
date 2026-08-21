const calculateMatchScore = (opportunity, user) => {
    let score = 0;

    // Normalize User
    const userField = (user.fieldOfStudy || "").toLowerCase();
    const userTitle = (user.professionalTitle || "").toLowerCase();
    let userSkills = [];
    if (Array.isArray(user.skills)) {
        userSkills = user.skills.map(s => (s.name || s).toLowerCase());
    }
    const userTags = (user.tags || []).map(t => t.toLowerCase());
    const userCity = (user.city || "").toLowerCase();
    const userCountry = (user.country || "").toLowerCase();

    // Normalize Opportunity
    const oppTitle = (opportunity.title || "").toLowerCase();
    const oppDept = (opportunity.department || "").toLowerCase();
    const oppDesc = (opportunity.description || "").toLowerCase();
    const oppMandatorySkills = (opportunity.mandatorySkills || []).map(s => s.toLowerCase());
    const oppNiceToHaveSkills = (opportunity.niceToHaveSkills || []).map(s => s.toLowerCase());
    const oppTags = (opportunity.tags || []).map(t => t.toLowerCase());
    const oppLocation = (opportunity.location || "").toLowerCase();

    // 1. Domain / Title Match (30 points max)
    let domainScore = 0;
    if (userField && (oppDept.includes(userField) || oppTitle.includes(userField))) {
        domainScore = 30;
    } else if (userTitle && (oppDept.includes(userTitle) || oppTitle.includes(userTitle))) {
        domainScore = 20;
    } else if (userField && oppDesc.includes(userField)) {
        domainScore = 15;
    } else if (userTitle && oppDesc.includes(userTitle)) {
        domainScore = 10;
    }
    score += domainScore;

    // 2. Skills Match (35 points max)
    // Mandatory (20 points)
    if (oppMandatorySkills.length > 0) {
        let reqMatches = 0;
        oppMandatorySkills.forEach(skill => {
            if (userSkills.includes(skill) || userTags.includes(skill)) reqMatches++;
        });
        score += Math.round((reqMatches / oppMandatorySkills.length) * 20);
    } else {
        score += 20; // Default if no strict requirements
    }

    // Preferred (15 points)
    if (oppNiceToHaveSkills.length > 0) {
        let prefMatches = 0;
        oppNiceToHaveSkills.forEach(skill => {
            if (userSkills.includes(skill) || userTags.includes(skill)) prefMatches++;
        });
        score += Math.round((prefMatches / oppNiceToHaveSkills.length) * 15);
    } else {
        score += 5; // Slight default bonus
    }

    // 3. Location (15 points)
    if (oppLocation.includes("remote") || oppLocation.includes("télétravail")) {
        score += 15;
    } else if (userCity && oppLocation.includes(userCity)) {
        score += 15;
    } else if (userCountry && oppLocation.includes(userCountry)) {
        score += 10;
    } else {
        score += 5; // Default if unknown
    }

    // 4. Tags / Interests (20 points max)
    if (oppTags.length > 0 && userTags.length > 0) {
        let tagMatches = 0;
        oppTags.forEach(tag => {
            if (userTags.includes(tag)) tagMatches++;
        });
        score += Math.round((tagMatches / oppTags.length) * 20);
    } else {
        score += 5; 
    }

    // Cap at 100
    if (score > 100) score = 100;

    let relevance = "DISCOVERY";
    if (score >= 70) relevance = "PRIMARY";
    else if (score >= 35) relevance = "RELATED";

    return { score, relevance };
};

const calculateRecommendationsForUser = async (db, userId, userModel) => {
    console.log(`Calculating recommendations for user ${userId}`);
    // 1. Candidate Retrieval: Fetch active opportunities
    const opportunitiesSnap = await db.collection('opportunities')
        .where('status', '==', 'ouvert')
        .orderBy('createdAt', 'desc')
        .limit(200)
        .get();

    const userRecsRef = db.collection('users').doc(userId).collection('recommendations');
    
    // Clear old recommendations first
    const oldRecs = await userRecsRef.get();
    
    let batches = [];
    let currentBatch = db.batch();
    let opCount = 0;

    oldRecs.forEach(doc => {
        currentBatch.delete(doc.ref);
        opCount++;
        if(opCount >= 400) {
            batches.push(currentBatch);
            currentBatch = db.batch();
            opCount = 0;
        }
    });

    opportunitiesSnap.forEach(doc => {
        const oppData = doc.data();
        
        // Hard filter: e.g. closeDate passed
        if (oppData.closeDate && oppData.closeDate.toDate() < new Date()) {
            return; 
        }

        const match = calculateMatchScore(oppData, userModel);
        
        // Save to recommendations
        const recRef = userRecsRef.doc(doc.id);
        currentBatch.set(recRef, {
            opportunityId: doc.id,
            score: match.score,
            relevance: match.relevance,
            updatedAt: new Date()
        });
        opCount++;
        
        if(opCount >= 400) {
            batches.push(currentBatch);
            currentBatch = db.batch();
            opCount = 0;
        }
    });

    if (opCount > 0) {
        batches.push(currentBatch);
    }

    for (let b of batches) {
        await b.commit();
    }
    console.log(`Updated recommendations for user ${userId}`);
};

const calculateRecommendationsForOpportunity = async (db, oppId, oppData) => {
    console.log(`Calculating recommendations for opportunity ${oppId}`);
    // Hard filter
    if (oppData.status !== 'ouvert' || (oppData.closeDate && oppData.closeDate.toDate() < new Date())) {
        return;
    }

    // Fetch active users. In a huge system, we'd query by tags/domain.
    // For now, fetch recent users or limit to 500.
    const usersSnap = await db.collection('users')
        .limit(500)
        .get();

    let batches = [];
    let currentBatch = db.batch();
    let opCount = 0;

    usersSnap.forEach(doc => {
        const userData = doc.data();
        const match = calculateMatchScore(oppData, userData);

        const recRef = db.collection('users').doc(doc.id).collection('recommendations').doc(oppId);
        currentBatch.set(recRef, {
            opportunityId: oppId,
            score: match.score,
            relevance: match.relevance,
            updatedAt: new Date()
        });
        opCount++;

        // For Kaïro Pro: we can also save to opportunities/{oppId}/top_candidates
        if (match.relevance === "PRIMARY" || match.relevance === "RELATED") {
            const candidateRef = db.collection('opportunities').doc(oppId).collection('top_candidates').doc(doc.id);
            currentBatch.set(candidateRef, {
                userId: doc.id,
                score: match.score,
                relevance: match.relevance,
                updatedAt: new Date()
            });
            opCount++;
        }

        // Push Notification for PRIMARY match
        if (match.relevance === "PRIMARY") {
            const notifRef = db.collection('notifications').doc();
            currentBatch.set(notifRef, {
                userId: doc.id,
                title: "Offre Parfaite Pour Vous 🎯",
                body: `Une nouvelle opportunité (${oppData.title || 'Nouvelle offre'}) correspond parfaitement à votre profil.`,
                type: "opportunity_match",
                relatedId: oppId,
                isRead: false,
                createdAt: new Date()
            });
            opCount++;

            // Email Notification for PRIMARY match (Score très élevé)
            // On s'assure de ne pas spammer.
            if (user.email && match.score > 80 && !user['emailSentForOpp_' + oppId]) {
                const userName = user.firstName || user.name || 'Candidat';
                const agencyName = oppData.companyName || 'Une entreprise';
                
                // Fire and forget (ne pas bloquer le batch)
                EmailService.sendEmail({
                    to: user.email,
                    subject: 'Une opportunité pourrait vous intéresser',
                    html: Templates.opportunityMatch(userName, oppData.title || 'Nouvelle offre', agencyName, match.score)
                }).then(success => {
                    if (success) {
                        // Idempotence : On note dans le profil de l'utilisateur qu'on lui a envoyé un mail pour cette opp
                        db.collection('users').doc(doc.id).set({
                            [`emailSentForOpp_${oppId}`]: true
                        }, { merge: true }).catch(err => logger.error('Failed to update emailSent flag', err));
                    }
                });
            }
        }

        if (opCount >= 400) {
            batches.push(currentBatch);
            currentBatch = db.batch();
            opCount = 0;
        }
    });

    if (opCount > 0) {
        batches.push(currentBatch);
    }

    for (let b of batches) {
        await b.commit();
    }
    console.log(`Updated recommendations for opportunity ${oppId}`);
};

module.exports = {
    calculateMatchScore,
    calculateRecommendationsForUser,
    calculateRecommendationsForOpportunity
};
