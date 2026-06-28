class Chatbot {
    constructor(renderCallback) {
        this.renderCallback = renderCallback;
        this.messages = [];
        this.currentStep = 0;
        this.cvData = {
            name: '',
            email: '',
            phone: '',
            education: [],
            experience: [],
            skills: []
        };
        
        // Auto-fill from profile if available
        const profile = Storage.getProfile();
        const user = Storage.getUser();
        if (user) {
            this.cvData.name = user.name || '';
            this.cvData.email = user.email || '';
        }
        if (profile) {
            if (profile.school && profile.major) {
                this.cvData.education.push(`${profile.major} - ${profile.school}`);
            }
            if (profile.skills) {
                this.cvData.skills = profile.skills;
            }
        }

        this.questions = [
            { field: 'phone', text: `Salut ${this.cvData.name.split(' ')[0]} ! CommenÃ§ons par tes coordonnÃ©es. Quel est ton numÃ©ro de tÃ©lÃ©phone ?` },
            { field: 'education', text: "Super. Quelle est ta formation principale ? (Ex: Licence Informatique Ã  l'UJKZ)" },
            { field: 'experience', text: "As-tu une expÃ©rience professionnelle ou un projet marquant Ã  ajouter ? (Tape 'Non' si aucune)" },
            { field: 'skills', text: "Enfin, quelles sont tes 3 compÃ©tences principales ? (SÃ©parÃ©es par des virgules)" }
        ];

        this.initDOM();
        this.start();
    }

    initDOM() {
        this.chatBox = document.getElementById('chatMessages');
        this.input = document.getElementById('chatInput');
        this.sendBtn = document.getElementById('sendBtn');

        const sendMsg = () => {
            const text = this.input.value.trim();
            if (text) {
                this.handleUserReply(text);
                this.input.value = '';
            }
        };

        this.sendBtn.addEventListener('click', sendMsg);
        this.input.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') sendMsg();
        });
    }

    addMessage(text, sender) {
        const msgDiv = document.createElement('div');
        msgDiv.className = `message ${sender}`;
        msgDiv.textContent = text;
        this.chatBox.appendChild(msgDiv);
        this.chatBox.scrollTop = this.chatBox.scrollHeight;
    }

    start() {
        setTimeout(() => {
            // Check if some data is prefilled, we might skip or adjust, but for MVP we follow the flow.
            this.askQuestion();
        }, 500);
        this.renderCallback(this.cvData);
    }

    askQuestion() {
        if (this.currentStep < this.questions.length) {
            this.addMessage(this.questions[this.currentStep].text, 'bot');
        } else {
            this.addMessage("Parfait ! Ton CV est prÃªt. Tu peux le vÃ©rifier dans l'aperÃ§u Ã  droite et le tÃ©lÃ©charger en PDF.", 'bot');
            Storage.setCvData(this.cvData);
        }
    }

    handleUserReply(text) {
        this.addMessage(text, 'user');
        
        const currentQ = this.questions[this.currentStep];
        
        if (currentQ.field === 'education') {
            this.cvData.education.push(text);
        } else if (currentQ.field === 'experience') {
            if (text.toLowerCase() !== 'non') {
                this.cvData.experience.push(text);
            }
        } else if (currentQ.field === 'skills') {
            const newSkills = text.split(',').map(s => s.trim()).filter(s => s);
            this.cvData.skills = [...new Set([...this.cvData.skills, ...newSkills])];
        } else {
            this.cvData[currentQ.field] = text;
        }

        this.renderCallback(this.cvData);
        this.currentStep++;
        
        setTimeout(() => {
            this.askQuestion();
        }, 600);
    }
}

