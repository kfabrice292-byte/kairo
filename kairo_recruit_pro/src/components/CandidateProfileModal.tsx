import { X, MapPin, GraduationCap, Mail, PlusCircle, CheckCircle2 } from "lucide-react";
import type { TalentProfile } from "../store/useTalentStore";
import { useJobStore } from "../store/useJobStore";
import { usePipelineStore } from "../store/usePipelineStore";
import { useState, useEffect } from "react";

interface CandidateProfileModalProps {
  talent: TalentProfile | null;
  application?: any; // To avoid circular dependency if we import PipelineItem, or we can just import it
  onClose: () => void;
}

export function CandidateProfileModal({ talent, application, onClose }: CandidateProfileModalProps) {
  const { jobs, fetchJobs } = useJobStore();
  const { addCandidateToPipeline } = usePipelineStore();
  
  const [showJobSelector, setShowJobSelector] = useState(false);
  const [addedToJobId, setAddedToJobId] = useState<string | null>(null);

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  if (!talent) return null;

  const handleAddToJob = (jobId: string) => {
    addCandidateToPipeline(jobId, talent);
    setAddedToJobId(jobId);
    setTimeout(() => {
      setShowJobSelector(false);
      setAddedToJobId(null);
    }, 2000);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        
        {/* Overlay */}
        <div className="fixed inset-0 bg-slate-900/75 dark:bg-slate-950/90 transition-opacity" onClick={onClose}></div>
        <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>

        {/* Modal Panel */}
        <div className="inline-block align-bottom bg-white dark:bg-slate-900 rounded-2xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full border border-slate-200 dark:border-slate-800">
          
          <div className="h-32 bg-gradient-to-r from-primary to-primary-light dark:from-primary-dark dark:to-primary relative">
            <button onClick={onClose} className="absolute top-4 right-4 p-2 bg-white/20 hover:bg-white/30 text-white rounded-full backdrop-blur-sm transition-colors">
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="px-6 pb-6">
            <div className="relative flex justify-between items-end -mt-12 mb-6">
              <div className="relative">
                {talent.photoUrl ? (
                  <img src={talent.photoUrl} alt={talent.name} className="w-24 h-24 rounded-2xl object-cover border-4 border-white dark:border-slate-900 shadow-sm" />
                ) : (
                  <div className="w-24 h-24 rounded-2xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-3xl font-bold text-slate-400 border-4 border-white dark:border-slate-900 shadow-sm">
                    {talent.name.charAt(0).toUpperCase()}
                  </div>
                )}
              </div>
              <div className="flex space-x-3 relative">
                <button className="px-4 py-2 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-sm font-medium hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors flex items-center">
                  <Mail className="w-4 h-4 mr-2" />
                  Contacter
                </button>
                
                {/* Sourcing Button */}
                <div className="relative">
                  <button 
                    onClick={() => setShowJobSelector(!showJobSelector)}
                    className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-dark transition-colors flex items-center shadow-sm"
                  >
                    <PlusCircle className="w-4 h-4 mr-2" />
                    Sourcing
                  </button>

                  {/* Dropdown Jobs */}
                  {showJobSelector && (
                    <div className="absolute right-0 mt-2 w-64 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg z-10 overflow-hidden">
                      <div className="p-3 border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50">
                        <p className="text-xs font-bold text-slate-500 uppercase tracking-wider">Ajouter à une offre</p>
                      </div>
                      <div className="max-h-48 overflow-y-auto">
                        {jobs.filter(j => j.status === 'ouvert').length === 0 ? (
                          <div className="p-4 text-center text-sm text-slate-500">Aucune offre active. Créez-en une d'abord.</div>
                        ) : (
                          jobs.filter(j => j.status === 'ouvert').map(job => (
                            <button
                              key={job.id}
                              onClick={() => handleAddToJob(job.id)}
                              className="w-full text-left px-4 py-3 hover:bg-slate-50 dark:hover:bg-slate-700/50 flex items-center justify-between group transition-colors"
                            >
                              <div className="truncate">
                                <p className="text-sm font-medium text-slate-900 dark:text-white truncate group-hover:text-primary transition-colors">{job.title}</p>
                              </div>
                              {addedToJobId === job.id && (
                                <CheckCircle2 className="w-4 h-4 text-green-500 flex-shrink-0 ml-2" />
                              )}
                            </button>
                          ))
                        )}
                      </div>
                    </div>
                  )}
                </div>

              </div>
            </div>

            <div className="mb-6">
              <h2 className="text-2xl font-bold text-slate-900 dark:text-white">{talent.name}</h2>
              <p className="text-lg font-medium text-slate-600 dark:text-slate-400 mt-1">{talent.professionalTitle}</p>
              <div className="flex flex-wrap gap-4 mt-3 text-sm text-slate-500 dark:text-slate-400">
                <div className="flex items-center"><MapPin className="w-4 h-4 mr-1.5" />{talent.country}</div>
                <div className="flex items-center"><GraduationCap className="w-4 h-4 mr-1.5" />{talent.university}</div>
              </div>
            </div>

            <div className="space-y-8">
              {talent.bio && (
                <section>
                  <h3 className="text-sm font-bold text-slate-900 dark:text-white uppercase tracking-wider mb-3">À propos</h3>
                  <div className="bg-slate-50 dark:bg-slate-950/50 p-4 rounded-xl border border-slate-100 dark:border-slate-800">
                    <p className="text-slate-600 dark:text-slate-400 leading-relaxed text-sm">{talent.bio}</p>
                  </div>
                </section>
              )}
              {talent.skills && talent.skills.length > 0 && (
                <section>
                  <h3 className="text-sm font-bold text-slate-900 dark:text-white uppercase tracking-wider mb-3">Compétences</h3>
                  <div className="flex flex-wrap gap-2">
                    {talent.skills.map((skill, index) => (
                      <span key={index} className="px-3 py-1 bg-primary/10 text-primary dark:bg-primary/20 dark:text-primary-light rounded-lg text-sm font-medium border border-primary/20">
                        {skill.name}
                      </span>
                    ))}
                  </div>
                </section>
              )}

              {application && application.answers && application.answers.length > 0 && (
                <section>
                  <h3 className="text-sm font-bold text-slate-900 dark:text-white uppercase tracking-wider mb-3">Réponses aux questions</h3>
                  <div className="space-y-4">
                    {application.answers.map((item: any, index: number) => (
                      <div key={index} className="bg-slate-50 dark:bg-slate-950/50 p-4 rounded-xl border border-slate-100 dark:border-slate-800">
                        <p className="text-sm font-bold text-slate-800 dark:text-slate-200 mb-2">{item.question}</p>
                        <p className="text-sm text-slate-600 dark:text-slate-400">{item.answer}</p>
                      </div>
                    ))}
                  </div>
                </section>
              )}
            </div>

          </div>
        </div>
      </div>
    </div>
  );
}
