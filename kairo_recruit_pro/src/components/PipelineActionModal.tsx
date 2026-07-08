import { X, Calendar, MapPin, Clock, FileText } from "lucide-react";
import { useState } from "react";
import type { PipelineItem } from "../store/usePipelineStore";
import { db } from "../lib/firebase";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";

interface PipelineActionModalProps {
  action: 'interview' | 'reject' | 'hire';
  item: PipelineItem;
  onClose: () => void;
}

export function PipelineActionModal({ action, item, onClose }: PipelineActionModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  // Interview Fields
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [location, setLocation] = useState("");
  
  // Reject/Hire Fields
  const [feedback, setFeedback] = useState("");

  const handleSubmit = async () => {
    setIsSubmitting(true);
    try {
      // For MVP: We simulate sending a notification by adding a doc to a 'notifications' collection for the candidate
      let message = "";
      let title = "";
      
      if (action === 'interview') {
        title = "Convocation à un entretien";
        message = `Félicitations, vous êtes convié à un entretien pour le poste.\nDate: ${date}\nHeure: ${time}\nLieu/Lien: ${location}`;
      } else if (action === 'reject') {
        title = "Mise à jour de votre candidature";
        message = `Votre candidature n'a pas été retenue.\nFeedback du recruteur: ${feedback}`;
      } else if (action === 'hire') {
        title = "Excellente nouvelle !";
        message = `Félicitations, vous êtes retenu pour le poste !\nMessage: ${feedback}`;
      }

      await addDoc(collection(db, 'notifications'), {
        userId: item.candidateId,
        title,
        message,
        type: 'application_update',
        jobId: item.jobId,
        read: false,
        createdAt: serverTimestamp()
      });

      setIsSubmitting(false);
      onClose();
    } catch (e) {
      console.error(e);
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center z-[60] p-4">
      <div className="bg-white dark:bg-slate-900 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl border border-slate-200 dark:border-slate-800">
        
        <div className="flex items-center justify-between p-6 border-b border-slate-200 dark:border-slate-800">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">
            {action === 'interview' && "Planifier un entretien"}
            {action === 'reject' && "Refuser la candidature"}
            {action === 'hire' && "Faire une offre"}
          </h2>
          <button onClick={onClose} className="p-2 text-slate-400 hover:text-slate-600 rounded-full hover:bg-slate-100 transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-4">
          <p className="text-slate-600 dark:text-slate-400">
            Candidat : <span className="font-semibold text-slate-900 dark:text-white">{item.candidate.name}</span>
          </p>

          {action === 'interview' && (
            <>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-1 dark:text-slate-300">Date</label>
                  <div className="relative">
                    <Calendar className="absolute left-3 top-2.5 w-5 h-5 text-slate-400" />
                    <input type="date" value={date} onChange={e => setDate(e.target.value)} className="w-full pl-10 pr-4 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg outline-none focus:border-primary" />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1 dark:text-slate-300">Heure</label>
                  <div className="relative">
                    <Clock className="absolute left-3 top-2.5 w-5 h-5 text-slate-400" />
                    <input type="time" value={time} onChange={e => setTime(e.target.value)} className="w-full pl-10 pr-4 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg outline-none focus:border-primary" />
                  </div>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1 dark:text-slate-300">Lieu ou Lien Visio</label>
                <div className="relative">
                  <MapPin className="absolute left-3 top-2.5 w-5 h-5 text-slate-400" />
                  <input type="text" value={location} onChange={e => setLocation(e.target.value)} placeholder="Ex: Google Meet, Bureaux Paris..." className="w-full pl-10 pr-4 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg outline-none focus:border-primary" />
                </div>
              </div>
            </>
          )}

          {(action === 'reject' || action === 'hire') && (
            <div>
              <label className="block text-sm font-medium mb-1 dark:text-slate-300">Feedback / Message au candidat</label>
              <div className="relative">
                <FileText className="absolute left-3 top-2.5 w-5 h-5 text-slate-400" />
                <textarea 
                  rows={4}
                  value={feedback} 
                  onChange={e => setFeedback(e.target.value)} 
                  placeholder={action === 'reject' ? "Ex: Malgré la qualité de votre profil..." : "Ex: Nous sommes ravis de vous proposer..."}
                  className="w-full pl-10 pr-4 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg outline-none focus:border-primary resize-none" 
                />
              </div>
            </div>
          )}
        </div>

        <div className="p-6 border-t border-slate-200 dark:border-slate-800 flex justify-end gap-3 bg-slate-50 dark:bg-slate-900/50">
          <button onClick={onClose} className="px-4 py-2 text-slate-600 dark:text-slate-400 font-medium hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
            Annuler
          </button>
          <button 
            onClick={handleSubmit}
            disabled={isSubmitting}
            className={`px-6 py-2 text-white font-medium rounded-lg transition-colors shadow-sm flex items-center ${action === 'reject' ? 'bg-red-500 hover:bg-red-600' : 'bg-primary hover:bg-primary-dark'}`}
          >
            {isSubmitting ? 'Envoi...' : 'Envoyer la notification'}
          </button>
        </div>

      </div>
    </div>
  );
}
