import { useEffect, useState } from "react";
import { useJobStore } from "../store/useJobStore";
import { Briefcase, Plus, MapPin, Users, Calendar } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { NewJobModal } from "../components/NewJobModal";

export function Jobs() {
  const { jobs, fetchJobs, isLoading, updateJobStatus } = useJobStore();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  const openPipeline = (jobId: string) => {
    navigate(`/pipeline?jobId=${jobId}`);
  };

  return (
    <div className="h-full flex flex-col">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Gestion des offres</h1>
          <p className="text-slate-500 dark:text-slate-400">
            Créez et gérez vos offres d'emploi pour attirer les meilleurs talents Kaïro.
          </p>
        </div>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="flex items-center px-4 py-2 bg-primary text-white rounded-lg font-medium hover:bg-primary-dark transition-colors shadow-sm"
        >
          <Plus className="w-5 h-5 mr-2" />
          Nouvelle Offre
        </button>
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        </div>
      ) : jobs.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center bg-white dark:bg-slate-900 border border-dashed border-slate-300 dark:border-slate-800 rounded-xl">
          <Briefcase className="w-16 h-16 text-slate-300 dark:text-slate-700 mb-4" />
          <h3 className="text-lg font-medium text-slate-900 dark:text-white">Aucune offre active</h3>
          <p className="text-slate-500 mt-1 mb-6">Commencez par créer votre première offre d'emploi.</p>
          <button 
            onClick={() => setIsModalOpen(true)}
            className="px-4 py-2 bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-white rounded-lg font-medium hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
          >
            Créer une offre
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 relative z-10">
          {jobs.map((job) => (
            <div key={job.id} className="glass-card p-6 flex flex-col hover:-translate-y-1 transition-transform duration-200">
              <div className="flex justify-between items-start mb-4">
                <div className={`px-3 py-1 rounded-full text-xs font-bold ${
                  job.status === 'ouvert' || job.status === 'active' as any ? 'bg-green-100/80 text-green-700 dark:bg-green-900/30 dark:text-green-400' :
                  job.status === 'suspendu' ? 'bg-orange-100/80 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400' :
                  job.status === 'clôturé' ? 'bg-red-100/80 text-red-700 dark:bg-red-900/30 dark:text-red-400' :
                  'bg-slate-100/80 text-slate-700 dark:bg-slate-800/80 dark:text-slate-400'
                }`}>
                  {job.status}
                </div>
                
                {/* Status Actions Dropdown / Buttons */}
                <div className="flex space-x-2">
                  {(job.status === 'ouvert' || job.status === 'active' as any) && (
                    <button onClick={(e) => { e.stopPropagation(); updateJobStatus(job.id, 'suspendu'); }} className="text-xs text-orange-600 hover:bg-orange-50 px-2 py-1 rounded border border-orange-200">Suspendre</button>
                  )}
                  {job.status === 'suspendu' && (
                    <button onClick={(e) => { e.stopPropagation(); updateJobStatus(job.id, 'ouvert'); }} className="text-xs text-green-600 hover:bg-green-50 px-2 py-1 rounded border border-green-200">Rouvrir</button>
                  )}
                  {job.status !== 'clôturé' && (
                    <button onClick={(e) => { e.stopPropagation(); updateJobStatus(job.id, 'clôturé'); }} className="text-xs text-red-600 hover:bg-red-50 px-2 py-1 rounded border border-red-200">Clôturer</button>
                  )}
                </div>
              </div>
              
              <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-1 truncate">{job.title}</h3>
              <p className="text-sm font-medium text-slate-500 mb-4 truncate">{job.company}</p>
              
              <div className="space-y-2 mb-4">
                <div className="flex items-center text-sm text-slate-600 dark:text-slate-400">
                  <MapPin className="w-4 h-4 mr-2 opacity-70" />
                  {job.location} • {job.remoteWork}
                </div>
                <div className="flex items-center text-sm text-slate-600 dark:text-slate-400">
                  <Briefcase className="w-4 h-4 mr-2 opacity-70" />
                  {job.type} • {job.workTime} • {job.numberOfPositions} poste(s)
                </div>
                <div className="flex items-center text-sm text-slate-600 dark:text-slate-400">
                  <Users className="w-4 h-4 mr-2 opacity-70" />
                  {job.educationLevel} • {job.minExperience > 0 ? `${job.minExperience} an(s) min.` : 'Débutant accepté'}
                </div>
                {job.salaryRange && (
                  <div className="flex items-center text-sm text-slate-600 dark:text-slate-400">
                    <span className="w-4 h-4 mr-2 opacity-70 flex items-center justify-center font-bold">€</span>
                    {job.salaryRange}
                  </div>
                )}
                <div className="flex items-center text-sm text-slate-600 dark:text-slate-400">
                  <Calendar className="w-4 h-4 mr-2 opacity-70" />
                  Publié le {new Date(job.createdAt).toLocaleDateString()} 
                  {job.closeDate && ` • Clôture : ${new Date(job.closeDate).toLocaleDateString()}`}
                </div>
              </div>

              {/* Skills Tags */}
              {job.mandatorySkills && job.mandatorySkills.length > 0 && (
                <div className="flex flex-wrap gap-2 mb-6">
                  {job.mandatorySkills.slice(0, 3).map((skill, index) => (
                    <span key={index} className="px-2 py-1 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-medium rounded-md border border-slate-200 dark:border-slate-700">
                      {skill}
                    </span>
                  ))}
                  {job.mandatorySkills.length > 3 && (
                    <span className="px-2 py-1 bg-slate-50 dark:bg-slate-800/50 text-slate-500 text-xs font-medium rounded-md">
                      +{job.mandatorySkills.length - 3}
                    </span>
                  )}
                </div>
              )}
              
              <div className="mt-auto pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-between items-center">
                <div className="flex items-center text-sm font-medium text-slate-600 dark:text-slate-400">
                  <Users className="w-4 h-4 mr-1.5" />
                  0 Candidats
                </div>
                <button 
                  onClick={() => openPipeline(job.id)}
                  className="text-sm font-medium text-primary hover:text-primary-dark transition-colors"
                >
                  Voir Pipeline &rarr;
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Creation Modal */}
      <NewJobModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </div>
  );
}
