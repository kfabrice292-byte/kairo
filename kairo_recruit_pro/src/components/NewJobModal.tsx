import { useState } from 'react';
import { useJobStore } from '../store/useJobStore';
import { useAuthStore } from '../store/useAuthStore';
import { X, ChevronRight, ChevronLeft, CheckCircle2 } from 'lucide-react';

interface NewJobModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function NewJobModal({ isOpen, onClose }: NewJobModalProps) {
  const { profile } = useAuthStore();
  const { createJob } = useJobStore();
  const [step, setStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form State
  const [title, setTitle] = useState("");
  const [department, setDepartment] = useState("");
  const [numberOfPositions, setNumberOfPositions] = useState(1);
  const [type, setType] = useState("CDI"); // CDI, CDD, Stage, Alternance
  const [workTime, setWorkTime] = useState("Temps plein");
  const [seniorityLevel, setSeniorityLevel] = useState("Junior");
  const [country, setCountry] = useState("France");
  const [city, setCity] = useState("");
  const [remoteWork, setRemoteWork] = useState("Hybride");
  const [description, setDescription] = useState("");
  const [salaryRange, setSalaryRange] = useState("");
  const [expectedStartDate, setExpectedStartDate] = useState("");
  const [openDate, setOpenDate] = useState("");
  const [closeDate, setCloseDate] = useState("");
  const [clientName, setClientName] = useState("");

  const [educationLevel, setEducationLevel] = useState("Bac+3");
  const [minExperience, setMinExperience] = useState(0);
  const [mandatorySkillsInput, setMandatorySkillsInput] = useState("");
  const [niceToHaveSkillsInput, setNiceToHaveSkillsInput] = useState("");
  const [languagesInput, setLanguagesInput] = useState("Français, Anglais");

  const [requiredDocuments, setRequiredDocuments] = useState<string[]>(['CV']);
  const availableDocs = ['CV', 'Lettre de motivation', 'Portfolio', 'Copie du Diplôme', 'Casier Judiciaire'];

  const [questions, setQuestions] = useState<string[]>([]);
  const [newQuestion, setNewQuestion] = useState("");

  if (!isOpen) return null;

  const handleNext = () => setStep(s => Math.min(4, s + 1));
  const handlePrev = () => setStep(s => Math.max(1, s - 1));

  const toggleDocument = (doc: string) => {
    setRequiredDocuments(prev => 
      prev.includes(doc) ? prev.filter(d => d !== doc) : [...prev, doc]
    );
  };

  const addQuestion = () => {
    if (newQuestion.trim()) {
      setQuestions([...questions, newQuestion.trim()]);
      setNewQuestion("");
    }
  };

  const removeQuestion = (idx: number) => {
    setQuestions(questions.filter((_, i) => i !== idx));
  };

  const handleSubmit = async () => {
    setIsSubmitting(true);
    
    // Vérification Monétisation B2B
    const confirmPayment = window.confirm("Monétisation B2B :\nVous n'avez pas d'abonnement 'Cabinet' actif (3000 FCFA/mois).\nLa publication de cette offre coûte 1000 FCFA (Paiement Unique).\n\nVoulez-vous procéder au paiement sécurisé ?");
    if (!confirmPayment) {
        setIsSubmitting(false);
        return; // Annulation du paiement et de la publication
    }

    try {
        const response = await fetch('https://us-central1-kairo-522c2.cloudfunctions.net/initiateAshtechPayment', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                uid: profile?.uid || 'b2b-user',
                type: 'b2b_job_post',
                name: profile?.name || 'Entreprise',
                phone: (profile as any)?.phone || '0000000000'
            })
        });

        if (response.ok) {
            const data = await response.json();
            if (data.checkout_url) {
                window.open(data.checkout_url, '_blank');
            }
        }
    } catch (e) {
        console.error("Échec API de paiement", e);
    }
    
    const mandatorySkills = mandatorySkillsInput.split(',').map(s => s.trim()).filter(s => s);
    const niceToHaveSkills = niceToHaveSkillsInput.split(',').map(s => s.trim()).filter(s => s);
    const languages = languagesInput.split(',').map(s => s.trim()).filter(s => s);

    await createJob({
      title,
      department,
      numberOfPositions,
      type,
      workTime,
      seniorityLevel,
      country,
      city,
      location: `${city}, ${country}`,
      remoteWork,
      clientName,
      description,
      salaryRange,
      expectedStartDate: expectedStartDate ? new Date(expectedStartDate) : undefined,
      openDate: openDate ? new Date(openDate) : new Date(),
      closeDate: closeDate ? new Date(closeDate) : undefined,
      educationLevel,
      minExperience,
      mandatorySkills,
      niceToHaveSkills,
      languages,
      requiredDocuments,
      preSelectionQuestions: questions
    });

    setIsSubmitting(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-md flex items-center justify-center z-50 p-4">
      <div className="glass-card rounded-2xl w-full max-w-3xl flex flex-col max-h-[90vh] overflow-hidden shadow-2xl relative">
        <div className="absolute top-[-20%] right-[-10%] w-[300px] h-[300px] bg-primary/20 rounded-full mix-blend-overlay filter blur-[80px] opacity-50 pointer-events-none"></div>
        
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-slate-200 dark:border-slate-800">
          <div>
            <h2 className="text-xl font-bold text-slate-900 dark:text-white">Créer une offre d'emploi</h2>
            <p className="text-sm text-slate-500 mt-1">Étape {step} sur 4</p>
          </div>
          <button onClick={onClose} className="p-2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6 custom-scrollbar">
          
          {/* STEP 1: Infos Générales */}
          {step === 1 && (
            <div className="space-y-6 animate-fade-in">
              <h3 className="text-lg font-semibold text-slate-800 dark:text-slate-200 mb-4">Informations Générales</h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Intitulé du poste *</label>
                  <input type="text" value={title} onChange={e => setTitle(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: Développeur Full-Stack" required />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Nom du Client (Si Cabinet / Agence)</label>
                  <input type="text" value={clientName} onChange={e => setClientName(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: TechCorp (Masqué aux candidats)" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Département / Service</label>
                  <input type="text" value={department} onChange={e => setDepartment(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: R&D, Marketing..." />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Nbr de postes</label>
                  <input type="number" min="1" value={numberOfPositions} onChange={e => setNumberOfPositions(parseInt(e.target.value))} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Type de contrat</label>
                  <select value={type} onChange={e => setType(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none">
                    <option>CDI</option><option>CDD</option><option>Stage</option><option>Alternance</option><option>Freelance</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Temps de travail</label>
                  <select value={workTime} onChange={e => setWorkTime(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none">
                    <option>Temps plein</option><option>Temps partiel</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Niveau hiérarchique</label>
                  <select value={seniorityLevel} onChange={e => setSeniorityLevel(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none">
                    <option>Stagiaire</option><option>Junior</option><option>Intermédiaire</option><option>Senior</option><option>Manager</option><option>Directeur</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Pays</label>
                  <input type="text" value={country} onChange={e => setCountry(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: France" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Ville</label>
                  <input type="text" value={city} onChange={e => setCity(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: Paris" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Télétravail</label>
                  <select value={remoteWork} onChange={e => setRemoteWork(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none">
                    <option>Hybride</option><option>100% Télétravail</option><option>Présentiel</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Salaire (Optionnel)</label>
                  <input type="text" value={salaryRange} onChange={e => setSalaryRange(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: 40k€ - 50k€" />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Description complète de l'offre *</label>
                <textarea rows={5} value={description} onChange={e => setDescription(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none resize-none" placeholder="Décrivez les missions, le contexte..." required />
              </div>
            </div>
          )}

          {/* STEP 2: Critères de matching */}
          {step === 2 && (
            <div className="space-y-6 animate-fade-in">
              <h3 className="text-lg font-semibold text-slate-800 dark:text-slate-200 mb-4">Profil recherché (Critères de Matching)</h3>
              <p className="text-sm text-slate-500 mb-6">Ces critères seront utilisés par notre algorithme pour calculer le score de compatibilité des candidats.</p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Niveau d'études minimum</label>
                  <select value={educationLevel} onChange={e => setEducationLevel(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none">
                    <option>Sans diplôme</option><option>Bac</option><option>Bac+2</option><option>Bac+3</option><option>Bac+5</option><option>Doctorat</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Années d'expérience minimum</label>
                  <input type="number" min="0" value={minExperience} onChange={e => setMinExperience(parseInt(e.target.value))} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Compétences OBLIGATOIRES (séparées par des virgules)</label>
                <input type="text" value={mandatorySkillsInput} onChange={e => setMandatorySkillsInput(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: React, TypeScript, Node.js" />
                <p className="text-xs text-slate-500 mt-1">Impact fort sur le score de matching.</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Compétences SOUHAITÉES (Bonus, séparées par des virgules)</label>
                <input type="text" value={niceToHaveSkillsInput} onChange={e => setNiceToHaveSkillsInput(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: Docker, AWS, GraphQL" />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Langues requises</label>
                <input type="text" value={languagesInput} onChange={e => setLanguagesInput(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" placeholder="Ex: Français, Anglais courant" />
              </div>
            </div>
          )}

          {/* STEP 3: Documents et Périodes */}
          {step === 3 && (
            <div className="space-y-6 animate-fade-in">
              <h3 className="text-lg font-semibold text-slate-800 dark:text-slate-200 mb-4">Dates et Documents Requis</h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Date d'ouverture des candidatures</label>
                  <input type="date" value={openDate} onChange={e => setOpenDate(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Date de clôture (Optionnel)</label>
                  <input type="date" value={closeDate} onChange={e => setCloseDate(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" />
                </div>
                <div className="col-span-1 md:col-span-2">
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Date prévisionnelle de prise de poste</label>
                  <input type="date" value={expectedStartDate} onChange={e => setExpectedStartDate(e.target.value)} className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" />
                </div>
              </div>

              <div className="mt-8">
                <h4 className="text-md font-medium text-slate-800 dark:text-slate-200 mb-3">Documents obligatoires à fournir par le candidat</h4>
                <div className="flex flex-wrap gap-3">
                  {availableDocs.map(doc => {
                    const isSelected = requiredDocuments.includes(doc);
                    return (
                      <button
                        key={doc}
                        onClick={() => toggleDocument(doc)}
                        className={`px-4 py-2 rounded-full text-sm font-medium border transition-colors flex items-center ${isSelected ? 'bg-primary/10 border-primary text-primary' : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400 hover:border-slate-300'}`}
                      >
                        {isSelected && <CheckCircle2 className="w-4 h-4 mr-2" />}
                        {doc}
                      </button>
                    )
                  })}
                </div>
              </div>
            </div>
          )}

          {/* STEP 4: Questions */}
          {step === 4 && (
            <div className="space-y-6 animate-fade-in">
              <h3 className="text-lg font-semibold text-slate-800 dark:text-slate-200 mb-4">Questions de pré-sélection (Optionnel)</h3>
              <p className="text-sm text-slate-500 mb-6">Ajoutez des questions spécifiques auxquelles le candidat devra répondre lors de sa candidature.</p>

              <div className="space-y-3">
                {questions.map((q, idx) => (
                  <div key={idx} className="flex items-start bg-slate-50 dark:bg-slate-800 p-4 rounded-xl border border-slate-100 dark:border-slate-700">
                    <span className="flex-shrink-0 w-6 h-6 rounded-full bg-primary/20 text-primary flex items-center justify-center text-sm font-bold mr-3 mt-0.5">{idx + 1}</span>
                    <p className="flex-1 text-slate-800 dark:text-slate-200 mt-1">{q}</p>
                    <button onClick={() => removeQuestion(idx)} className="text-slate-400 hover:text-red-500 transition-colors ml-4 p-1">
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>

              <div className="flex gap-2 mt-4">
                <input 
                  type="text" 
                  value={newQuestion} 
                  onChange={e => setNewQuestion(e.target.value)} 
                  onKeyDown={e => e.key === 'Enter' && addQuestion()}
                  className="flex-1 bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg px-4 py-2.5 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none" 
                  placeholder="Ex: Pourquoi souhaitez-vous rejoindre notre entreprise ?" 
                />
                <button onClick={addQuestion} className="px-4 py-2 bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-white rounded-lg font-medium hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors whitespace-nowrap">
                  Ajouter
                </button>
              </div>
            </div>
          )}

        </div>

        {/* Footer / Controls */}
        <div className="p-6 border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 flex justify-between items-center">
          <button 
            onClick={handlePrev}
            disabled={step === 1}
            className={`flex items-center px-4 py-2 rounded-lg font-medium transition-colors ${step === 1 ? 'opacity-0 pointer-events-none' : 'text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-800'}`}
          >
            <ChevronLeft className="w-5 h-5 mr-1" /> Retour
          </button>
          
          {step < 4 ? (
            <button 
              onClick={handleNext}
              disabled={!title && step === 1} // Require title to advance
              className="flex items-center px-6 py-2.5 bg-primary text-white rounded-lg font-medium hover:bg-primary-dark transition-colors shadow-sm disabled:opacity-50"
            >
              Suivant <ChevronRight className="w-5 h-5 ml-1" />
            </button>
          ) : (
            <button 
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="flex items-center px-6 py-2.5 bg-green-500 text-white rounded-lg font-medium hover:bg-green-600 transition-colors shadow-sm disabled:opacity-50"
            >
              {isSubmitting ? 'Publication en cours...' : 'Publier l\'offre'} <CheckCircle2 className="w-5 h-5 ml-2" />
            </button>
          )}
        </div>

      </div>
    </div>
  );
}
