import { GoogleGenerativeAI } from '@google/generative-ai';

const apiKey = import.meta.env.VITE_GEMINI_API_KEY;

if (!apiKey || apiKey === "votre_api_key_gemini") {
    console.error("Clé API Gemini manquante ou invalide. Vérifiez votre fichier .env");
}

const genAI = new GoogleGenerativeAI(apiKey);

// Modèle pour la génération du document
const generationModel = genAI.getGenerativeModel({
    model: "gemini-2.5-flash",
});

const AI = {
    /**
     * Génère le HTML d'un document (CV ou Lettre) à partir du profil et d'un formulaire rempli
     * @param {string} type - "CV" ou "Lettre"
     * @param {Object} userProfile - Données de Firebase (nom, email, tel, etc.)
     * @param {Object} formData - Les réponses du questionnaire
     */
    async generateFromForm(type, userProfile, formData) {
        let prompt = "";

        if (type === "CV") {
            prompt = `
Tu es un expert en recrutement et un designer de CV de renommée mondiale.
Génère un CV ultra-professionnel en code HTML strict.
N'utilise AUCUN style CSS inline. N'utilise AUCUNE classe Tailwind.
Tu DOIS IMPÉRATIVEMENT utiliser EXACTEMENT cette structure sémantique :

<div class="cv-container">
    <div class="cv-sidebar">
        <div class="cv-profile-pic">${userProfile.name ? userProfile.name.charAt(0).toUpperCase() : 'CV'}</div>
        <h1 class="cv-name">${userProfile.name || 'Nom'}</h1>
        <p class="cv-title">${formData.objectif || userProfile.specialty || 'Professionnel'}</p>
        
        <div class="cv-contact">
            <p>📞 ${userProfile.phone || 'Non renseigné'}</p>
            <p>✉️ ${userProfile.email || 'Non renseigné'}</p>
            <p>📍 ${userProfile.city || 'Non renseigné'}</p>
            <p>🔗 ${userProfile.linkedin || ''}</p>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Compétences</h2>
            <div class="cv-badges">
                <span class="cv-badge">Exemple 1</span>
            </div>
        </div>
        
        <div class="cv-section">
            <h2 class="cv-section-title">Langues & Hobbies</h2>
            <p class="cv-text"><!-- Langues parlées, hobbies, etc. --></p>
        </div>
    </div>

    <div class="cv-main">
        <div class="cv-section">
            <h2 class="cv-section-title">Profil & Objectif</h2>
            <p class="cv-text"><!-- Rédige un profil percutant --></p>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Expériences Professionnelles</h2>
            <div class="cv-item">
                <div class="cv-item-header">
                    <h3 class="cv-item-title">Titre | Entreprise</h3>
                    <span class="cv-item-date">Dates</span>
                </div>
                <ul class="cv-item-desc">
                    <li>Détail</li>
                </ul>
            </div>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Formations & Certifications</h2>
            <div class="cv-item">
                <div class="cv-item-header">
                    <h3 class="cv-item-title">Diplôme | École</h3>
                    <span class="cv-item-date">Année</span>
                </div>
            </div>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Engagements & Distinctions</h2>
            <p class="cv-text"><!-- Engagements associatifs, etc. --></p>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Références</h2>
            <p class="cv-text"><!-- Références --></p>
        </div>
    </div>
</div>

REGLE D'OR ABSOLUE : N'invente AUCUNE information. Utilise UNIQUEMENT les informations fournies ci-dessous. Remplis la structure intelligemment. Ne mets pas de sections vides.

Le HTML généré doit être un bloc <div> complet. N'inclus AUCUN marqueur Markdown.

--- RÉPONSES AU QUESTIONNAIRE (À UTILISER STRICTEMENT) ---
Objectif visé : ${formData.objectif}
Formations et Diplômes : ${formData.formations}
Expériences et accomplissements : ${formData.experiences}
Compétences clés : ${formData.competences}
Engagements & Distinctions : ${formData.engagements}
Langues & Centres d'intérêt : ${formData.langues}
Références : ${formData.references}
`;
        } else if (type === "Lettre") {
            prompt = `
Tu es un expert en recrutement et en rédaction de lettre de motivation.
Génère une Lettre de Motivation complète et convaincante en code HTML strict.
N'utilise AUCUN style CSS inline. N'utilise AUCUNE classe Tailwind.

Tu DOIS IMPÉRATIVEMENT utiliser EXACTEMENT cette structure sémantique :
<div class="letter-container">
    <div class="letter-header">
        <div class="letter-sender">
            <h1 class="letter-name">${userProfile.name || 'Nom'}</h1>
            <p>${userProfile.phone || 'Téléphone'}</p>
            <p>${userProfile.email || 'Email'}</p>
        </div>
        <div class="letter-recipient">
            <p><strong>À l'attention du Responsable Recrutement</strong></p>
            <p>Date : Aujoud'hui</p>
        </div>
    </div>
    
    <div class="letter-subject">
        <p><strong>Objet : </strong>Candidature pour le poste de ${formData.objectif || 'Professionnel'}</p>
    </div>

    <div class="letter-body">
        <p class="letter-salutation">Madame, Monsieur,</p>
        <!-- Paragraphe 1 : L'accroche (Vous) -->
        <p class="letter-paragraph">...</p>
        <!-- Paragraphe 2 : L'expérience (Moi) -->
        <p class="letter-paragraph">...</p>
        <!-- Paragraphe 3 : La collaboration (Nous) -->
        <p class="letter-paragraph">...</p>
        
        <p class="letter-signoff">Dans l'attente de vous rencontrer, je vous prie d'agréer, Madame, Monsieur, mes salutations distinguées.</p>
    </div>

    <div class="letter-signature">
        <p class="letter-name">${userProfile.name || 'Nom'}</p>
    </div>
</div>

REGLE D'OR ABSOLUE : N'invente AUCUNE information. Utilise UNIQUEMENT les informations fournies. Le HTML généré doit être un bloc <div> complet. N'inclus AUCUN marqueur Markdown.

--- RÉPONSES AU QUESTIONNAIRE ---
Objectif visé : ${formData.objectif}
Formations : ${formData.formations}
Expériences : ${formData.experiences}
Compétences : ${formData.competences}
Engagements/Motivation : ${formData.engagements}
Détails : ${formData.langues}
`;
        }


        try {
            const result = await generationModel.generateContent(prompt);
            const response = await result.response;
            let htmlContent = response.text();
            
            // Nettoyer les marqueurs markdown au cas où l'IA les ajoute quand même
            htmlContent = htmlContent.replace(/```html/gi, '').replace(/```/g, '').trim();
            
            return htmlContent;
        } catch (error) {
            console.error("Erreur de génération :", error);
            throw new Error("Erreur de l'IA : " + error.message);
        }
    },

    generateFromUploadAndChat: async (cvText, chatUpdates, type, userProfile) => {
        if (!generationModel) throw new Error("L'IA n'est pas initialisée.");

        let prompt = "";
        if (type === "CV") {
            prompt = `
Tu es un expert en recrutement.
L'utilisateur a fourni le texte brut de son ancien CV. Il t'a également donné des informations récentes à ajouter ou modifier.
Ton rôle est de fusionner ces informations pour générer un tout nouveau CV en code HTML strict.

N'utilise AUCUN style CSS inline. N'utilise AUCUNE classe Tailwind.
Tu DOIS IMPÉRATIVEMENT utiliser EXACTEMENT cette structure sémantique pour le CV :
<div class="cv-container">
    <div class="cv-sidebar">
        <div class="cv-profile-pic">${userProfile.name ? userProfile.name.charAt(0).toUpperCase() : 'A'}</div>
        <h1 class="cv-name">${userProfile.name || 'Nom du candidat'}</h1>
        <h2 class="cv-title">[TITRE OU PROFESSION ICI]</h2>
        <div class="cv-contact">
            <p>${userProfile.phone || 'Téléphone'}</p>
            <p>${userProfile.email || 'Email'}</p>
        </div>
        <div class="cv-section">
            <h3 class="cv-section-title">Compétences</h3>
            <div class="cv-badges">
                <span class="cv-badge">Compétence 1</span>
            </div>
        </div>
        <div class="cv-section">
            <h3 class="cv-section-title">Langues & Hobbies</h3>
            <ul><li>...</li></ul>
        </div>
    </div>
    <div class="cv-main">
        <div class="cv-section">
            <h3 class="cv-section-title">Profil</h3>
            <p>[RÉSUMÉ DU PROFIL ICI]</p>
        </div>
        <div class="cv-section">
            <h3 class="cv-section-title">Expériences Professionnelles</h3>
            <div class="cv-item">
                <div class="cv-item-header">
                    <h4 class="cv-item-title">[POSTE] - [ENTREPRISE]</h4>
                    <span class="cv-item-date">[DATES]</span>
                </div>
                <ul><li>[RÉALISATIONS]</li></ul>
            </div>
        </div>
        <div class="cv-section">
            <h3 class="cv-section-title">Formations</h3>
            <div class="cv-item">
                <div class="cv-item-header">
                    <h4 class="cv-item-title">[DIPLÔME] - [ÉCOLE]</h4>
                    <span class="cv-item-date">[DATES]</span>
                </div>
            </div>
        </div>
    </div>
</div>

REGLE D'OR ABSOLUE : Utilise les informations de l'ancien CV, corrige-les si besoin, et ajoute IMPÉRATIVEMENT les nouveautés discutées dans le chat.
Le HTML généré doit être un bloc <div> complet. N'inclus AUCUN marqueur Markdown.

--- ANCIEN CV (TEXTE EXTRAIT) ---
${cvText}

--- NOUVEAUTÉS À INTÉGRER (ISSUES DU CHAT) ---
${chatUpdates}
`;
        } else {
             // Fallback for letter if needed
             prompt = `Génère une lettre de motivation à partir de ce CV : ${cvText} et ces updates : ${chatUpdates}`;
        }

        try {
            const result = await generationModel.generateContent(prompt);
            const response = await result.response;
            let htmlContent = response.text();
            htmlContent = htmlContent.replace(/```html/gi, '').replace(/```/g, '').trim();
            return htmlContent;
        } catch (error) {
            console.error("Erreur de génération :", error);
            throw new Error("Erreur de l'IA : " + error.message);
        }
    }
};


export default AI;
