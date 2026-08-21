import { BarChart3, Users, Briefcase, TrendingUp } from "lucide-react";
import { useAuthStore } from "../store/useAuthStore";
import { useJobStore } from "../store/useJobStore";
import { useEffect, useState } from "react";
import { db } from "../lib/firebase";
import { collection, query, where, getDocs } from "firebase/firestore";

export function Dashboard() {
  const { profile } = useAuthStore();
  const { jobs, fetchJobs } = useJobStore();
  const [totalApplications, setTotalApplications] = useState(0);
  const [showOnboarding, setShowOnboarding] = useState(false);

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  useEffect(() => {
    // Si aucune offre et pas déjà onboardé
    if (jobs.length === 0 && !localStorage.getItem('kairo_onboarded')) {
      setShowOnboarding(true);
    }
  }, [jobs]);

  const closeOnboarding = () => {
    localStorage.setItem('kairo_onboarded', 'true');
    setShowOnboarding(false);
  };

  useEffect(() => {
    const fetchAppCount = async () => {
      // In a real optimized app, we'd use a Cloud Function to keep counts, 
      // or we query applications for all active jobs.
      // For MVP: Get applications for all jobs owned by recruiter.
      if (jobs.length > 0) {
        try {
          const jobIds = jobs.map(j => j.id);
          // Firestore 'in' query supports up to 10 items. We batch or just loop for MVP.
          let count = 0;
          // Simple loop for MVP scale
          for (const jobId of jobIds) {
            const q = query(collection(db, 'applications'), where('jobId', '==', jobId));
            const snapshot = await getDocs(q);
            count += snapshot.size;
          }
          setTotalApplications(count);
        } catch (e) {
          console.error("Erreur comptage apps:", e);
        }
      }
    };
    fetchAppCount();
  }, [jobs]);

  const activeJobsCount = jobs.filter(j => j.status === 'ouvert' || j.status === 'active' as any).length;

  return (
    <div className="h-full flex flex-col">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">
          Bonjour, {profile?.name || "Recruteur"} 👋
        </h1>
        <p className="text-slate-500 dark:text-slate-400">Voici un aperçu de vos recrutements aujourd'hui.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8 relative z-10">
        {/* Real Stats */}
        <div className="glass-card p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Total Candidatures</p>
            <div className="p-2 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-lg">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <h3 className="text-3xl font-bold text-slate-900 dark:text-white mt-4">{totalApplications}</h3>
        </div>
        
        <div className="glass-card p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Offres Actives</p>
            <div className="p-2 bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 rounded-lg">
              <Briefcase className="w-5 h-5" />
            </div>
          </div>
          <h3 className="text-3xl font-bold text-slate-900 dark:text-white mt-4">{activeJobsCount}</h3>
        </div>

        <div className="glass-card p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Taux de réponse</p>
            <div className="p-2 bg-orange-100 dark:bg-orange-900/30 text-orange-600 dark:text-orange-400 rounded-lg">
              <TrendingUp className="w-5 h-5" />
            </div>
          </div>
          <h3 className="text-3xl font-bold text-slate-900 dark:text-white mt-4">--%</h3>
        </div>
      </div>

      <div className="flex-1 glass-card p-8 flex flex-col items-center justify-center text-slate-400 relative z-10 overflow-hidden">
        {showOnboarding && (
          <div className="absolute inset-0 w-full h-full p-6 flex gap-4 overflow-hidden opacity-40 blur-[2px] select-none pointer-events-none">
            {/* Simulated Candidate Cards */}
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="min-w-[280px] bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200 dark:border-slate-700 shadow-sm flex flex-col gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-slate-200 dark:bg-slate-700 rounded-full"></div>
                  <div>
                    <div className="w-24 h-4 bg-slate-200 dark:bg-slate-700 rounded mb-2"></div>
                    <div className="w-16 h-3 bg-slate-100 dark:bg-slate-800 rounded"></div>
                  </div>
                </div>
                <div className="w-full h-2 bg-slate-100 dark:bg-slate-800 rounded"></div>
                <div className="w-3/4 h-2 bg-slate-100 dark:bg-slate-800 rounded"></div>
                <div className="flex gap-2 mt-auto">
                  <div className="w-16 h-6 bg-orange-100 dark:bg-orange-900/30 rounded-full"></div>
                  <div className="w-16 h-6 bg-purple-100 dark:bg-purple-900/30 rounded-full"></div>
                </div>
              </div>
            ))}
          </div>
        )}
        <BarChart3 className="w-16 h-16 mb-4 opacity-30 text-primary relative z-10" />
        <h3 className="text-xl font-semibold text-slate-700 dark:text-slate-300 mb-2 relative z-10">Analyse des recrutements</h3>
        <p className="text-center max-w-md relative z-10">Le graphique détaillé s'affichera ici dès que vous aurez enregistré suffisamment de candidatures pour générer des tendances.</p>
      </div>

      {/* Onboarding Wizard */}
      {showOnboarding && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-slate-900 rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl border border-slate-200 dark:border-slate-800 flex flex-col md:flex-row">
            <div className="bg-gradient-to-br from-orange-400 to-primary p-8 md:w-1/3 flex flex-col justify-center text-white">
              <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center mb-6">
                <Briefcase className="w-6 h-6 text-white" />
              </div>
              <h2 className="text-2xl font-bold mb-2">Bienvenue sur Kaïro Pro !</h2>
              <p className="text-white/80 text-sm">Le hub central pour recruter les meilleurs talents, rapidement et efficacement.</p>
            </div>
            <div className="p-8 md:w-2/3">
              <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-4">Vos premiers pas</h3>
              <ul className="space-y-4 mb-8">
                <li className="flex items-start">
                  <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center font-bold mr-3 shrink-0">1</div>
                  <div>
                    <h4 className="font-semibold text-slate-900 dark:text-white">Complétez votre profil</h4>
                    <p className="text-sm text-slate-500">Ajoutez votre logo pour rassurer les candidats.</p>
                  </div>
                </li>
                <li className="flex items-start">
                  <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center font-bold mr-3 shrink-0">2</div>
                  <div>
                    <h4 className="font-semibold text-slate-900 dark:text-white">Publiez une offre</h4>
                    <p className="text-sm text-slate-500">Diffusez instantanément votre offre d'emploi.</p>
                  </div>
                </li>
                <li className="flex items-start">
                  <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center font-bold mr-3 shrink-0">3</div>
                  <div>
                    <h4 className="font-semibold text-slate-900 dark:text-white">Match automatique</h4>
                    <p className="text-sm text-slate-500">L'IA Kaïro triera les meilleurs profils pour vous.</p>
                  </div>
                </li>
              </ul>
              <div className="flex justify-end space-x-3">
                <button onClick={closeOnboarding} className="px-4 py-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors font-medium">Plus tard</button>
                <button onClick={closeOnboarding} className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors font-medium shadow-sm">C'est parti !</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
