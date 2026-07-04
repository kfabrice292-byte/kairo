import { MapPin, GraduationCap, ChevronRight } from "lucide-react";
import type { TalentProfile } from "../store/useTalentStore";

interface CandidateCardProps {
  talent: TalentProfile;
  onClick: () => void;
  matchScore?: number;
}

export function CandidateCard({ talent, onClick, matchScore }: CandidateCardProps) {
  return (
    <div 
      onClick={onClick}
      className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md hover:border-primary/50 transition-all cursor-pointer overflow-hidden group"
    >
      <div className="p-5 flex items-start space-x-4">
        {talent.photoUrl ? (
          <img 
            src={talent.photoUrl} 
            alt={talent.name} 
            className="w-16 h-16 rounded-full object-cover border-2 border-slate-100 dark:border-slate-800"
          />
        ) : (
          <div className="w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-xl font-bold text-slate-400">
            {talent.name.charAt(0).toUpperCase()}
          </div>
        )}
        
        <div className="flex-1 min-w-0">
          <div className="flex justify-between items-start">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white truncate group-hover:text-primary transition-colors">
              {talent.name}
            </h3>
            {matchScore !== undefined && (
              <div className={`ml-2 px-2 py-0.5 rounded-full text-[10px] font-bold border flex items-center ${
                matchScore >= 80 ? 'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/30 dark:text-green-400 dark:border-green-800' :
                matchScore >= 60 ? 'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/30 dark:text-yellow-400 dark:border-yellow-800' :
                'bg-red-50 text-red-700 border-red-200 dark:bg-red-900/30 dark:text-red-400 dark:border-red-800'
              }`}>
                {matchScore}%
              </div>
            )}
          </div>
          <p className="text-sm font-medium text-slate-600 dark:text-slate-400 truncate">
            {talent.headline}
          </p>
          
          <div className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
            <div className="flex items-center text-xs text-slate-500 dark:text-slate-500">
              <MapPin className="w-3.5 h-3.5 mr-1.5 flex-shrink-0" />
              <span className="truncate">{talent.country}</span>
            </div>
            <div className="flex items-center text-xs text-slate-500 dark:text-slate-500">
              <GraduationCap className="w-3.5 h-3.5 mr-1.5 flex-shrink-0" />
              <span className="truncate">{talent.university}</span>
            </div>
          </div>
        </div>
      </div>
      
      {talent.skills && talent.skills.length > 0 && (
        <div className="px-5 pb-5 pt-0">
          <div className="flex flex-wrap gap-1.5">
            {talent.skills.slice(0, 3).map((skill, index) => (
              <span 
                key={index} 
                className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300 border border-slate-200 dark:border-slate-700"
              >
                {skill}
              </span>
            ))}
            {talent.skills.length > 3 && (
              <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-slate-50 text-slate-500 dark:bg-slate-800/50 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                +{talent.skills.length - 3}
              </span>
            )}
          </div>
        </div>
      )}
      
      <div className="bg-slate-50 dark:bg-slate-950/50 px-5 py-3 border-t border-slate-100 dark:border-slate-800 flex justify-between items-center group-hover:bg-primary/5 transition-colors">
        <span className="text-xs font-medium text-slate-500 dark:text-slate-400">Profil numérique</span>
        <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-primary transition-colors" />
      </div>
    </div>
  );
}
