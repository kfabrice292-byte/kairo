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
        <div class="cv-profile-pic"></div>
        <h1 class="cv-name">${userProfile.name || 'Nom'}</h1>
        <p class="cv-title">${formData.objectif || userProfile.specialty || 'Titre Professionnel'}</p>
        
        <div class="cv-contact">
            <p><i class="ph-fill ph-phone"></i> ${userProfile.phone || 'Non renseigné'}</p>
            <p><i class="ph-fill ph-envelope"></i> ${userProfile.email || 'Non renseigné'}</p>
            <p><i class="ph-fill ph-map-pin"></i> ${userProfile.city || 'Non renseigné'}</p>
            <p><i class="ph-fill ph-linkedin-logo"></i> ${userProfile.linkedin || 'LinkedIn'}</p>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Compétences Techniques</h2>
            <div class="cv-skills">
                <div class="cv-skill-item">
                    <span class="cv-skill-name">Nom Compétence</span>
                    <div class="cv-skill-bar"><div class="cv-skill-level" style="width: 80%"></div></div>
                </div>
                <!-- Ajoute jusqu'à 6 compétences avec pourcentages -->
            </div>
        </div>
        
        <div class="cv-section">
            <h2 class="cv-section-title">Soft Skills</h2>
            <div class="cv-badges">
                <!-- 3 à 4 Soft Skills (ex: Leadership) -->
                <span class="cv-badge">Exemple 1</span>
            </div>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Langues</h2>
            <div class="cv-skills">
                <div class="cv-skill-item">
                    <span class="cv-skill-name">Anglais (Courant)</span>
                    <div class="cv-skill-bar"><div class="cv-skill-level" style="width: 85%"></div></div>
                </div>
            </div>
        </div>
    </div>

    <div class="cv-main">
        <div class="cv-section">
            <h2 class="cv-section-title">Profil Professionnel</h2>
            <p class="cv-text"><!-- Rédige un profil percutant (3-4 phrases). --></p>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Expériences Professionnelles</h2>
            <!-- TRÈS IMPORTANT : Utilise la méthode STAR (Situation, Tâche, Action, Résultat). Inclus des metrics concrets. -->
            <div class="cv-item">
                <div class="cv-item-header">
                    <h3 class="cv-item-title">Titre du Poste | Entreprise</h3>
                    <span class="cv-item-date">Dates</span>
                </div>
                <ul class="cv-item-desc">
                    <li><strong>Action et Résultat :</strong> Description détaillée de ce qui a été accompli et comment.</li>
                    <li><strong>Responsabilité clé :</strong> Géré X personnes ou Y budget.</li>
                </ul>
            </div>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Formations & Diplômes</h2>
            <div class="cv-item">
                <div class="cv-item-header">
                    <h3 class="cv-item-title">Nom du Diplôme | École/Université</h3>
                    <span class="cv-item-date">Année d'obtention</span>
                </div>
                <p class="cv-text-small">Mention ou spécialité (si pertinent).</p>
            </div>
        </div>

        <div class="cv-section">
            <h2 class="cv-section-title">Centres d'intérêt</h2>
            <p class="cv-text"><!-- Hobbies, engagements... --></p>
        </div>
    </div>
</div>

REGLE D'OR ABSOLUE : N'invente AUCUNE expérience totalement fausse. Utilise UNIQUEMENT les informations fournies ci-dessous, mais SUBLIME-LES (reformule de manière très professionnelle).

--- RÉPONSES AU QUESTIONNAIRE ---
Objectif visé : ${formData.objectif}
Formations : ${formData.formations}
Expériences : ${formData.experiences}
Compétences : ${formData.competences}
Engagements : ${formData.engagements}
Langues : ${formData.langues}
Références : ${formData.references}
`;
        } else if (type === "Lettre") {
            prompt = `
Tu es un expert en recrutement.
Génère une Lettre de Motivation percutante en code HTML strict.
N'utilise AUCUN style CSS inline. N'utilise AUCUNE classe Tailwind.
Tu DOIS utiliser la structure argumentaire "Vous, Moi, Nous".

<div class="letter-container">
    <div class="letter-header">
        <div class="letter-sender">
            <h1 class="letter-name">${userProfile.name || 'Nom'}</h1>
            <p><i class="ph-fill ph-phone"></i> ${userProfile.phone || 'Téléphone'}</p>
            <p><i class="ph-fill ph-envelope"></i> ${userProfile.email || 'Email'}</p>
        </div>
        <div class="letter-recipient">
            <p><strong>À l'attention du Responsable Recrutement</strong></p>
            <p>Date : ${new Date().toLocaleDateString('fr-FR')}</p>
        </div>
    </div>
    
    <div class="letter-subject">
        <p><strong>Objet : </strong>Candidature au poste de ${formData.objectif || 'Poste visé'}</p>
    </div>

    <div class="letter-body">
        <p class="letter-salutation">Madame, Monsieur,</p>
        
        <!-- PARAGRAPHE 1 : VOUS -->
        <p class="letter-paragraph"><!-- Rédige le paragraphe VOUS. --></p>

        <!-- PARAGRAPHE 2 : MOI -->
        <p class="letter-paragraph"><!-- Rédige le paragraphe MOI. --></p>

        <!-- PARAGRAPHE 3 : NOUS -->
        <p class="letter-paragraph"><!-- Rédige le paragraphe NOUS. --></p>
        
        <p class="letter-paragraph">Je me tiens à votre entière disposition pour un entretien afin de vous détailler de vive voix ma motivation.</p>
        
        <p class="letter-signature-text">Je vous prie d'agréer, Madame, Monsieur, l'expression de mes salutations distinguées.</p>
        <p class="letter-signature-name">${userProfile.name || 'Candidat'}</p>
    </div>
</div>

--- INFORMATIONS CANDIDAT ---
Objectif visé : ${formData.objectif}
Formations : ${formData.formations}
Expériences : ${formData.experiences}
Compétences : ${formData.competences}
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
