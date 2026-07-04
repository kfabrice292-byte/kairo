import { useEffect, useState } from "react";
import { useTalentStore } from "../store/useTalentStore";
import type { TalentProfile } from "../store/useTalentStore";
import { CandidateCard } from "../components/CandidateCard";
import { CandidateProfileModal } from "../components/CandidateProfileModal";
import { Search as SearchIcon, Filter, Loader2 } from "lucide-react";

export function Search() {
  const { filteredTalents, isLoading, fetchTalents, searchTalents } = useTalentStore();
  const [query, setQuery] = useState("");
  const [skillFilter, setSkillFilter] = useState("");
  const [selectedTalent, setSelectedTalent] = useState<TalentProfile | null>(null);

  useEffect(() => {
    fetchTalents();
  }, [fetchTalents]);

  useEffect(() => {
    searchTalents(query, skillFilter);
  }, [query, skillFilter, searchTalents]);

  return (
    <div className="h-full flex flex-col">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Recherche de Talents</h1>
        <p className="text-slate-500 dark:text-slate-400">
          Explorez la base de profils numériques Kaïro. Trouvez les meilleurs candidats par compétences, université ou mots-clés.
        </p>
      </div>

      {/* Search Bar & Filters */}
      <div className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm mb-6 flex flex-col sm:flex-row gap-4">
        <div className="flex-1 relative">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <SearchIcon className="h-5 w-5 text-slate-400" />
          </div>
          <input
            type="text"
            className="block w-full pl-10 pr-3 py-2 border border-slate-300 dark:border-slate-700 rounded-lg leading-5 bg-white dark:bg-slate-950 text-slate-900 dark:text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary sm:text-sm transition-colors"
            placeholder="Rechercher par nom, titre ou mot-clé dans la bio..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
        
        <div className="sm:w-64 relative">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Filter className="h-5 w-5 text-slate-400" />
          </div>
          <input
            type="text"
            className="block w-full pl-10 pr-3 py-2 border border-slate-300 dark:border-slate-700 rounded-lg leading-5 bg-white dark:bg-slate-950 text-slate-900 dark:text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary sm:text-sm transition-colors"
            placeholder="Filtrer par compétence..."
            value={skillFilter}
            onChange={(e) => setSkillFilter(e.target.value)}
          />
        </div>
      </div>

      {/* Results */}
      <div className="flex-1 overflow-y-auto pb-6">
        {isLoading ? (
          <div className="h-64 flex flex-col items-center justify-center text-slate-400">
            <Loader2 className="w-8 h-8 animate-spin text-primary mb-4" />
            <p>Chargement de la base de talents...</p>
          </div>
        ) : filteredTalents.length === 0 ? (
          <div className="h-64 flex flex-col items-center justify-center bg-slate-50 dark:bg-slate-900/50 rounded-xl border border-dashed border-slate-300 dark:border-slate-700 text-slate-500">
            <SearchIcon className="w-12 h-12 mb-3 text-slate-400" />
            <h3 className="text-lg font-medium text-slate-900 dark:text-white">Aucun talent trouvé</h3>
            <p className="mt-1 text-sm">Essayez de modifier vos critères de recherche.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredTalents.map((talent) => (
              <CandidateCard 
                key={talent.id} 
                talent={talent} 
                onClick={() => setSelectedTalent(talent)} 
              />
            ))}
          </div>
        )}
      </div>

      {/* Modal */}
      {selectedTalent && (
        <CandidateProfileModal 
          talent={selectedTalent} 
          onClose={() => setSelectedTalent(null)} 
        />
      )}
    </div>
  );
}
