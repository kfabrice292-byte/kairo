document.addEventListener('DOMContentLoaded', () => {
    const user = Storage.getUser();
    if (!user) {
        window.location.href = 'login.html';
        return;
    }

    const selectedDocs = Storage.get('kairo_selected_docs') || ['cv'];

    // Flat data collection from chat
    const chatData = {
        name: user.name || '',
        phone: '',
        email: user.email || '',
        city: '',
        education: '',
        school: '',
        level: '',
        skills: '',
        experience: '',
        jobOffer: '',
        specialty: '',
        certifications: '',
        tools: '',
        languages: '',
        engagements: '',
        hobbies: '',
        references: ''
    };

    const questions = [
        { field: 'phone', text: `Parfait ! On commence par ton profil. Quel est ton numéro de téléphone ?` },
        { field: 'city', text: "Dans quelle ville résides-tu ?" },
        { field: 'specialty', text: "Quelle est ta spécialité ou ton titre professionnel ? (Ex: Informatique, Communication...)" },
        { field: 'education', text: "Quelle est ta formation actuelle ou ton dernier diplôme ?" },
        { field: 'school', text: "Dans quel établissement ?" },
        { field: 'skills', text: "Quelles sont tes compétences principales ? (Sépare-les par des virgules)" },
        { field: 'experience', text: "Raconte-moi brièvement ta meilleure expérience professionnelle ou un projet marquant." },
        { field: 'jobOffer', text: "Super ! Enfin, peux-tu coller ici l'offre de stage/emploi que tu vises ? (Cela aidera pour la lettre de motivation)" }
    ];

    let currentStep = 0;

    // DOM Elements
    const chatBox = document.getElementById('chatMessages');
    const input = document.getElementById('chatInput');
    const sendBtn = document.getElementById('sendBtn');
    
    // Views
    const chatView = document.getElementById('chatView');
    const loadingView = document.getElementById('loadingView');
    const previewView = document.getElementById('previewView');

    const addMessage = (text, sender) => {
        const msgDiv = document.createElement('div');
        msgDiv.className = `message ${sender}`;
        msgDiv.innerText = text;
        chatBox.appendChild(msgDiv);
        chatBox.scrollTop = chatBox.scrollHeight;
    };

    const askQuestion = () => {
        if (currentStep < questions.length) {
            addMessage(questions[currentStep].text, 'bot');
        } else {
            startLoadingPhase();
        }
    };

    const handleReply = () => {
        const text = input.value.trim();
        if (!text) return;

        addMessage(text, 'user');
        input.value = '';

        const currentQ = questions[currentStep];
        chatData[currentQ.field] = text;

        currentStep++;
        
        setTimeout(() => {
            askQuestion();
        }, 600);
    };

    sendBtn.addEventListener('click', handleReply);
    input.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') handleReply();
    });

    setTimeout(() => { askQuestion(); }, 500);

    // --- LOADING PHASE ---
    const startLoadingPhase = () => {
        chatView.style.display = 'none';
        loadingView.style.display = 'flex';

        const steps = ['step1', 'step2', 'step3', 'step4'];
        let currentStatus = 0;

        const interval = setInterval(() => {
            if (currentStatus > 0) {
                document.getElementById(steps[currentStatus - 1]).classList.add('done');
                document.getElementById(steps[currentStatus - 1]).classList.remove('active');
            }
            if (currentStatus < steps.length) {
                document.getElementById(steps[currentStatus]).classList.add('active');
                currentStatus++;
            } else {
                clearInterval(interval);
                setTimeout(() => {
                    loadingView.style.display = 'none';
                    showPreviewPhase();
                }, 1000);
            }
        }, 1200);
    };

    // --- PREVIEW PHASE (ATS COMPLIANT) ---
    const showPreviewPhase = () => {
        previewView.style.display = 'flex';
        
        const tabsContainer = document.getElementById('tabsContainer');
        tabsContainer.innerHTML = '';

        // Formater les données selon la norme ATS 3.3 avec les nouvelles sections
        const atsData = {
            personal_info: {
                name: chatData.name,
                title: chatData.specialty || "Étudiant(e)",
                email: chatData.email,
                phone: chatData.phone,
                location: chatData.city
            },
            summary: "Candidat rigoureux et motivé, avec de solides bases théoriques acquises lors de ma formation. Capable d'adaptation rapide et désireux d'apporter une valeur ajoutée au sein de votre équipe. Fort d'un engagement personnel, je souhaite contribuer activement aux objectifs de l'entreprise.",
            experience: [
                { title: "Expérience pertinente", date: "Année en cours", description: chatData.experience }
            ],
            skills: chatData.skills.split(',').map(s => s.trim()),
            tools: chatData.tools ? chatData.tools.split(',').map(s => s.trim()) : ["Microsoft Office", "Outils collaboratifs"],
            languages: chatData.languages ? chatData.languages.split(',').map(s => s.trim()) : ["Français (Courant)", "Anglais (Intermédiaire)"],
            education: [
                { degree: chatData.education, school: chatData.school, date: "Actuellement" }
            ],
            certifications: chatData.certifications ? [
                { title: chatData.certifications, date: "Récemment" }
            ] : [
                { title: "Formation en art oratoire et leadership", date: "2023" }
            ],
            engagements: chatData.engagements ? chatData.engagements : "Membre actif de l'association des étudiants de mon université.",
            hobbies: chatData.hobbies ? chatData.hobbies : "Actualité, Débats intellectuels, Bénévolat.",
            references: chatData.references ? chatData.references : "Références disponibles sur demande."
        };

        const tabConfigs = {
            'cv': { id: 'cv', label: '📄 CV', render: () => renderCV(atsData) },
            'motivation': { id: 'motivation', label: '✉️ Lettre', render: () => renderMotivation(atsData) },
            'stage': { id: 'stage', label: '🎓 Demande de stage', render: () => renderStageRequest(atsData) }
        };

        selectedDocs.forEach((doc, index) => {
            const config = tabConfigs[doc];
            if (config) {
                const btn = document.createElement('button');
                btn.className = `tab-btn ${index === 0 ? 'active' : ''}`;
                btn.innerText = config.label;
                btn.onclick = () => switchTab(config.id, btn);
                tabsContainer.appendChild(btn);

                config.render();
            }
        });

        if (selectedDocs.length > 0) {
            document.getElementById(`tab-${selectedDocs[0]}`).classList.add('active');
        }

        // --- Template Switcher Logic ---
        const templateBtns = document.querySelectorAll('.template-btn');
        templateBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const newTemplate = e.target.getAttribute('data-template');
                const cvDocument = document.querySelector('#tab-cv .a4-document');
                if (cvDocument) {
                    cvDocument.classList.remove('template-tech', 'template-clean', 'template-corporate');
                    cvDocument.classList.add(newTemplate);
                }
                
                // Update active button state
                templateBtns.forEach(b => {
                    b.classList.remove('btn-primary');
                    b.classList.add('btn-outline');
                });
                e.target.classList.remove('btn-outline');
                e.target.classList.add('btn-primary');
            });
        });

        // Set default template active
        const defaultBtn = document.querySelector('.template-btn[data-template="template-tech"]');
        if (defaultBtn) {
            defaultBtn.classList.remove('btn-outline');
            defaultBtn.classList.add('btn-primary');
        }

        // --- Edit Mode Logic ---
        const editBtn = document.getElementById('editCVBtn');
        let isEditing = false;
        
        editBtn.addEventListener('click', () => {
            const documents = document.querySelectorAll('.a4-document');
            isEditing = !isEditing;
            
            documents.forEach(doc => {
                if (isEditing) {
                    doc.setAttribute('contenteditable', 'true');
                    doc.style.outline = '3px dashed var(--primary)';
                    doc.style.outlineOffset = '4px';
                } else {
                    doc.removeAttribute('contenteditable');
                    doc.style.outline = 'none';
                }
            });
            
            if (isEditing) {
                editBtn.innerHTML = '<i class="ph ph-check" style="margin-right: 0.5rem;"></i> Terminer l\'édition';
                editBtn.classList.remove('btn-outline');
                editBtn.classList.add('btn-primary');
                editBtn.style.background = '#22c55e'; // Green when saving
                editBtn.style.borderColor = '#22c55e';
            } else {
                editBtn.innerHTML = '<i class="ph ph-pencil-simple" style="margin-right: 0.5rem;"></i> Modifier le contenu';
                editBtn.classList.remove('btn-primary');
                editBtn.classList.add('btn-outline');
                editBtn.style.background = '';
                editBtn.style.borderColor = '';
            }
        });
    };

    const switchTab = (tabId, btnElement) => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        btnElement.classList.add('active');
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        document.getElementById(`tab-${tabId}`).classList.add('active');
    };

    // --- RENDER FUNCTIONS (Semantic HTML for ATS) ---
    const renderCV = (data) => {
        const target = document.getElementById('tab-cv');
        const skillsHtml = data.skills.map(s => `<span class="skill-badge">${s}</span>`).join('');
        const toolsHtml = data.tools ? data.tools.map(s => `<span class="skill-badge" style="background:#F3F4F6;color:#111827;">${s}</span>`).join('') : '';
        const langsHtml = data.languages ? data.languages.map(s => `<div style="font-size: 10pt; font-weight: 600; margin-bottom: 4px;">• ${s}</div>`).join('') : '';
        
        target.innerHTML = `
            <div class="a4-document template-tech">
                <header class="doc-header">
                    <h1 class="doc-name">${data.personal_info.name}</h1>
                    <div class="doc-subtitle" style="font-size: 14pt; font-weight: 600; margin-bottom: 1rem; color: #F97316;">${data.personal_info.title}</div>
                    <div class="doc-contact">
                        <span><i class="ph ph-envelope-simple"></i> ${data.personal_info.email}</span>
                        <span><i class="ph ph-phone"></i> ${data.personal_info.phone}</span>
                        <span><i class="ph ph-map-pin"></i> ${data.personal_info.location}</span>
                    </div>
                </header>
                
                <div class="sidebar">
                    <section>
                        <h2 class="section-title"><i class="ph ph-user"></i> Profil</h2>
                        <p style="font-size: 10pt;">${data.summary}</p>
                    </section>

                    <section style="margin-top: 2rem;">
                        <h2 class="section-title"><i class="ph ph-code"></i> Compétences</h2>
                        <div class="skills-container">
                            ${skillsHtml}
                        </div>
                    </section>
                    
                    <section style="margin-top: 2rem;">
                        <h2 class="section-title"><i class="ph ph-wrench"></i> Outils</h2>
                        <div class="skills-container">
                            ${toolsHtml}
                        </div>
                    </section>

                    <section style="margin-top: 2rem;">
                        <h2 class="section-title"><i class="ph ph-translate"></i> Langues</h2>
                        <div>
                            ${langsHtml}
                        </div>
                    </section>
                </div>

                <div class="main-content">
                    <section>
                        <h2 class="section-title"><i class="ph ph-briefcase"></i> Expérience</h2>
                        ${data.experience.map(exp => `
                            <div class="item">
                                <h3 class="item-title">${exp.title}</h3>
                                <div class="item-subtitle">${exp.date}</div>
                                <p style="font-size: 10pt;">${exp.description}</p>
                            </div>
                        `).join('')}
                    </section>

                    <section>
                        <h2 class="section-title"><i class="ph ph-graduation-cap"></i> Formation</h2>
                        ${data.education.map(edu => `
                            <div class="item">
                                <h3 class="item-title">${edu.degree}</h3>
                                <div class="item-subtitle">${edu.date}</div>
                                <p style="font-size: 10pt;">${edu.school}</p>
                            </div>
                        `).join('')}
                    </section>
                    
                    ${data.certifications && data.certifications.length > 0 ? `
                    <section>
                        <h2 class="section-title"><i class="ph ph-certificate"></i> Certifications</h2>
                        ${data.certifications.map(cert => `
                            <div class="item" style="margin-bottom: 0.5rem;">
                                <div style="display: flex; justify-content: space-between; align-items: center;">
                                    <h3 class="item-title" style="font-size: 11pt;">${cert.title}</h3>
                                    <span style="font-size: 9pt; color: #6B7280;">${cert.date}</span>
                                </div>
                            </div>
                        `).join('')}
                    </section>
                    ` : ''}

                    <section>
                        <h2 class="section-title"><i class="ph ph-users"></i> Vie Sociale</h2>
                        <div class="item">
                            <h3 class="item-title" style="font-size: 11pt;">Engagements & Distinctions</h3>
                            <p style="font-size: 10pt;">${data.engagements}</p>
                        </div>
                        <div class="item" style="margin-top: 0.5rem;">
                            <h3 class="item-title" style="font-size: 11pt;">Centres d'intérêt</h3>
                            <p style="font-size: 10pt;">${data.hobbies}</p>
                        </div>
                    </section>
                </div>
            </div>
        `;
    };

    const renderMotivation = (data) => {
        const target = document.getElementById('tab-motivation');
        target.innerHTML = `
            <div class="a4-document letter-document">
                <div class="letter-header">
                    <div class="letter-sender">
                        <strong>${data.personal_info.name}</strong><br>
                        ${data.personal_info.location}<br>
                        ${data.personal_info.phone}<br>
                        ${data.personal_info.email}
                    </div>
                    <div class="letter-recipient">
                        <strong>À l'attention du Responsable Recrutement</strong><br>
                        Entreprise destinataire<br>
                        (Ville)<br><br>
                        Fait à ${data.personal_info.location}, le ${new Date().toLocaleDateString('fr-FR')}
                    </div>
                </div>

                <div class="letter-subject">Objet : Candidature au poste mentionné dans l'offre</div>

                <div class="letter-body">
                    <p>Madame, Monsieur,</p>
                    <p>C'est avec un vif intérêt que j'ai pris connaissance de votre offre d'emploi. Actuellement en ${data.education[0].degree} à ${data.education[0].school}, je suis particulièrement attiré par l'opportunité de rejoindre votre entreprise reconnue pour son expertise.</p>
                    <p>Au cours de mon parcours, j'ai eu l'opportunité de développer de solides compétences, notamment en ${data.skills.slice(0,2).join(' et ')}. Mes expériences précédentes, telles que "${data.experience[0].description}", m'ont appris à être autonome et proactif face aux défis.</p>
                    <p>Intégrer votre équipe me permettrait de mettre en pratique mon dynamisme et ma volonté d'apprendre, tout en contribuant efficacement à l'atteinte de vos objectifs.</p>
                    <p>Je me tiens à votre entière disposition pour convenir d'un entretien et vous démontrer de vive voix ma motivation. Je vous prie d'agréer, Madame, Monsieur, l'expression de mes salutations distinguées.</p>
                </div>

                <div class="letter-signature">
                    ${data.personal_info.name}
                </div>
            </div>
        `;
    };

    const renderStageRequest = (data) => {
        const target = document.getElementById('tab-stage');
        target.innerHTML = `
            <div class="a4-document letter-document">
                <div class="letter-header">
                    <div class="letter-sender">
                        <strong>${data.personal_info.name}</strong><br>
                        ${data.personal_info.location}<br>
                        ${data.personal_info.phone}<br>
                        ${data.personal_info.email}
                    </div>
                    <div class="letter-recipient">
                        <strong>À l'attention de la Direction</strong><br>
                        Entreprise destinataire<br><br>
                        Fait à ${data.personal_info.location}, le ${new Date().toLocaleDateString('fr-FR')}
                    </div>
                </div>

                <div class="letter-subject" style="text-decoration: underline;">Objet : Demande de stage académique</div>

                <div class="letter-body">
                    <p>Madame, Monsieur,</p>
                    <p>Je soussigné(e) <strong>${data.personal_info.name}</strong>, actuellement étudiant(e) en <strong>${data.education[0].degree}</strong> à l'établissement <strong>${data.education[0].school}</strong>, sollicite par la présente votre bienveillance pour l'obtention d'un stage au sein de votre structure.</p>
                    <p>Ce stage s'inscrit dans le cadre de ma formation et me permettra de mettre en pratique les connaissances théoriques acquises. Rigoureux(se) et motivé(e), je suis prêt(e) à m'investir pleinement dans les missions qui me seront confiées.</p>
                    <p>Dans l'attente d'une suite favorable à ma demande, je vous prie de recevoir, Madame, Monsieur, l'expression de mon profond respect.</p>
                </div>

                <div class="letter-signature">
                    Signature de l'étudiant<br><br>
                    <strong>${data.personal_info.name}</strong>
                </div>
            </div>
        `;
    };
});
