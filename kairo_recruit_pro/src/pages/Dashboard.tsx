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

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

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

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {/* Real Stats */}
        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center">
          <div className="p-3 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-lg mr-4">
            <Users className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Total Candidatures</p>
            <h3 className="text-2xl font-bold text-slate-900 dark:text-white">{totalApplications}</h3>
          </div>
        </div>
        
        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center">
          <div className="p-3 bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 rounded-lg mr-4">
            <Briefcase className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Offres Actives</p>
            <h3 className="text-2xl font-bold text-slate-900 dark:text-white">{activeJobsCount}</h3>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center">
          <div className="p-3 bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 rounded-lg mr-4">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Taux de réponse</p>
            <h3 className="text-2xl font-bold text-slate-900 dark:text-white">--%</h3>
          </div>
        </div>
      </div>

      <div className="flex-1 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-6 shadow-sm flex flex-col items-center justify-center text-slate-400">
        <BarChart3 className="w-16 h-16 mb-4 opacity-50" />
        <p>Le graphique des recrutements s'affichera ici dès que vous aurez suffisamment de données.</p>
      </div>
    </div>
  );
}
