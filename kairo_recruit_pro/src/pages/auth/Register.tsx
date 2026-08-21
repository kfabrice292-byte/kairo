import { useState } from "react";
import { useAuthStore } from "../../store/useAuthStore";
import { Link, useNavigate } from "react-router-dom";
import { Building2, Briefcase, Loader2, CheckCircle2, ChevronRight, ChevronLeft, Building, Users, Star } from "lucide-react";

export function Register() {
  const [step, setStep] = useState(1);
  const [accountType, setAccountType] = useState<"entreprise" | "cabinet">("entreprise");
  const [company, setCompany] = useState("");
  const [industry, setIndustry] = useState("");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [plan, setPlan] = useState<"freemium" | "premium" | "cabinet">("freemium");
  
  const { register, isLoading, error, clearError } = useAuthStore();
  const navigate = useNavigate();

  const handleNextStep = (e: React.FormEvent) => {
    e.preventDefault();
    if (step === 1 && company.trim() && industry.trim()) {
      setStep(2);
    } else if (step === 2 && name.trim() && email.trim() && password.length >= 6) {
      if (accountType === "cabinet") {
        setPlan("cabinet");
      }
      setStep(3);
    }
  };

  const handlePreviousStep = () => {
    setStep(Math.max(1, step - 1));
  };

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    clearError();
    try {
      await register(email, password, name, company, accountType);
      // We could ideally also pass the 'plan' and 'industry' to register
      navigate("/");
    } catch (_err) {
      // Error handled in store
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 relative flex items-center justify-center p-4 font-sans overflow-hidden">
      {/* Decorative Background */}
      <div className="absolute inset-0 z-0 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-orange-100/50 via-slate-50 to-purple-50/30 pointer-events-none"></div>
      
      {/* Abstract Shapes */}
      <div className="absolute top-[-10%] left-[-10%] w-96 h-96 bg-purple-300 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob"></div>
      <div className="absolute top-[20%] right-[-10%] w-96 h-96 bg-orange-300 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-2000"></div>

      <div className="w-full max-w-5xl grid lg:grid-cols-2 gap-12 z-10">
        
        {/* Left Column: Branding */}
        <div className="hidden lg:flex flex-col justify-center">
          <div className="inline-flex items-center gap-3 px-4 py-2 rounded-full bg-white/50 backdrop-blur-sm border border-white mb-6 shadow-sm w-fit">
            <span className="w-2 h-2 rounded-full bg-orange-500 animate-pulse"></span>
            <span className="text-sm font-bold text-slate-800 tracking-wide uppercase">Kaïro B2B Portal</span>
          </div>
          <h1 className="text-5xl font-extrabold text-slate-900 tracking-tight leading-tight mb-6">
            Recrutez les <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange-500 to-purple-600">meilleurs talents</span>, sans effort.
          </h1>
          <p className="text-lg text-slate-600 font-medium mb-10 leading-relaxed">
            Que vous soyez une entreprise pour un recrutement ponctuel, ou un cabinet de recrutement pour un volume intensif, Kaïro s'adapte à votre workflow.
          </p>
          
          <div className="space-y-4">
            <div className={`flex items-center gap-4 bg-white/40 p-4 rounded-2xl backdrop-blur-sm border ${accountType === "entreprise" ? "border-orange-500 shadow-md" : "border-white/50"}`}>
              <div className="w-12 h-12 bg-white rounded-xl shadow-sm flex items-center justify-center text-orange-500"><Building2 size={24} /></div>
              <div>
                <h4 className="font-bold text-slate-800">Compte Entreprise</h4>
                <p className="text-sm text-slate-500">Recrutement ponctuel, session rapide.</p>
              </div>
            </div>
            <div className={`flex items-center gap-4 bg-white/40 p-4 rounded-2xl backdrop-blur-sm border ${accountType === "cabinet" ? "border-purple-500 shadow-md" : "border-white/50"}`}>
              <div className="w-12 h-12 bg-white rounded-xl shadow-sm flex items-center justify-center text-purple-600"><Briefcase size={24} /></div>
              <div>
                <h4 className="font-bold text-slate-800">Compte Cabinet</h4>
                <p className="text-sm text-slate-500">Usage intensif, PWA installable sur bureau.</p>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Form Wizard */}
        <div className="flex flex-col justify-center w-full max-w-md mx-auto">
          <div className="bg-white/80 backdrop-blur-xl rounded-[2.5rem] shadow-2xl shadow-slate-200/50 p-8 border border-white/50 relative overflow-hidden transition-all duration-300">
            {/* Top Shine */}
            <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-orange-400 to-purple-500"></div>

            <div className="flex items-center justify-between mb-6">
              {step > 1 ? (
                <button type="button" onClick={handlePreviousStep} className="p-2 -ml-2 text-slate-400 hover:text-slate-700 rounded-full hover:bg-slate-100 transition-colors">
                  <ChevronLeft size={20} />
                </button>
              ) : (
                <div className="w-9"></div>
              )}
              <div className="flex gap-2">
                {[1, 2, 3].map((s) => (
                  <div key={s} className={`h-1.5 w-6 rounded-full transition-all duration-300 ${step >= s ? "bg-orange-500" : "bg-slate-200"}`} />
                ))}
              </div>
              <div className="w-9"></div>
            </div>

            <h2 className="text-3xl font-black text-slate-900 mb-2 text-center">
              {step === 1 ? "Votre Organisation" : step === 2 ? "Vos Informations" : "Choisissez un plan"}
            </h2>
            <p className="text-slate-500 text-center font-medium mb-8">
              {step === 1 ? "Commençons par configurer votre espace." : step === 2 ? "Créez votre accès recruteur." : "Débloquez tout le potentiel de Kaïro."}
            </p>

            {error && (
              <div className="bg-red-50 border border-red-100 text-red-600 p-4 rounded-xl text-sm font-medium flex items-center gap-3 mb-6">
                <span className="w-2 h-2 rounded-full bg-red-500"></span>
                {error}
              </div>
            )}

            <form className="space-y-5" onSubmit={step < 3 ? handleNextStep : handleSubmit}>
              
              {/* STEP 1: COMPANY INFO */}
              {step === 1 && (
                <div className="space-y-5 animate-in fade-in slide-in-from-bottom-4 duration-300">
                  <div className="flex p-1 bg-slate-100 rounded-2xl mb-4">
                    <button
                      type="button"
                      onClick={() => setAccountType("entreprise")}
                      className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-bold transition-all ${
                        accountType === "entreprise" ? "bg-white text-slate-800 shadow-sm" : "text-slate-500 hover:text-slate-700"
                      }`}
                    >
                      <Building2 size={18} className={accountType === "entreprise" ? "text-orange-500" : ""} />
                      Entreprise
                    </button>
                    <button
                      type="button"
                      onClick={() => setAccountType("cabinet")}
                      className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-bold transition-all ${
                        accountType === "cabinet" ? "bg-white text-slate-800 shadow-sm" : "text-slate-500 hover:text-slate-700"
                      }`}
                    >
                      <Briefcase size={18} className={accountType === "cabinet" ? "text-purple-600" : ""} />
                      Cabinet
                    </button>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                      {accountType === "entreprise" ? "Nom de l'entreprise" : "Nom du cabinet"}
                    </label>
                    <input
                      type="text"
                      required
                      value={company}
                      onChange={(e) => setCompany(e.target.value)}
                      placeholder="Tech Corp / HR Agency"
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all font-medium"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                      Secteur d'activité
                    </label>
                    <input
                      type="text"
                      required
                      value={industry}
                      onChange={(e) => setIndustry(e.target.value)}
                      placeholder="Ex: Informatique, Finance..."
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all font-medium"
                    />
                  </div>

                  <button
                    type="submit"
                    className="w-full flex justify-center items-center gap-2 py-4 px-4 rounded-xl text-sm font-bold text-white bg-slate-900 hover:bg-slate-800 shadow-lg shadow-slate-900/20 hover:-translate-y-0.5 transition-all mt-4"
                  >
                    Suivant <ChevronRight size={18} />
                  </button>
                </div>
              )}

              {/* STEP 2: PERSONAL INFO */}
              {step === 2 && (
                <div className="space-y-5 animate-in fade-in slide-in-from-right-8 duration-300">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Nom complet</label>
                    <input
                      type="text"
                      required
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="Jean Dupont"
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all font-medium"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Email Professionnel</label>
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="jean@entreprise.com"
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all font-medium"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Mot de passe</label>
                    <input
                      type="password"
                      required
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all font-medium"
                    />
                  </div>
                  <button
                    type="submit"
                    className="w-full flex justify-center items-center gap-2 py-4 px-4 rounded-xl text-sm font-bold text-white bg-slate-900 hover:bg-slate-800 shadow-lg shadow-slate-900/20 hover:-translate-y-0.5 transition-all mt-4"
                  >
                    Suivant <ChevronRight size={18} />
                  </button>
                </div>
              )}

              {/* STEP 3: PLAN SELECTION */}
              {step === 3 && (
                <div className="space-y-4 animate-in fade-in slide-in-from-right-8 duration-300">
                  {accountType === "entreprise" ? (
                    <>
                      <div 
                        onClick={() => setPlan("freemium")}
                        className={`p-4 rounded-2xl border-2 cursor-pointer transition-all ${plan === "freemium" ? "border-orange-500 bg-orange-50" : "border-slate-200 hover:border-orange-200 bg-white"}`}
                      >
                        <div className="flex justify-between items-center mb-2">
                          <h4 className="font-bold text-slate-800 flex items-center gap-2">
                            <Building size={18} className="text-orange-500"/> Freemium
                          </h4>
                          <span className="text-sm font-bold text-slate-500">0 FCFA</span>
                        </div>
                        <p className="text-sm text-slate-500">1 offre d'emploi active, accès basique aux talents.</p>
                      </div>

                      <div 
                        onClick={() => setPlan("premium")}
                        className={`p-4 rounded-2xl border-2 cursor-pointer transition-all relative overflow-hidden ${plan === "premium" ? "border-orange-500 bg-orange-500 text-white" : "border-slate-200 hover:border-orange-200 bg-white"}`}
                      >
                        <div className="absolute top-0 right-0 bg-yellow-400 text-yellow-900 text-[10px] font-bold px-2 py-1 rounded-bl-lg uppercase">Populaire</div>
                        <div className="flex justify-between items-center mb-2">
                          <h4 className={`font-bold flex items-center gap-2 ${plan === "premium" ? "text-white" : "text-slate-800"}`}>
                            <Star size={18} className={plan === "premium" ? "text-white" : "text-orange-500"}/> Premium
                          </h4>
                          <span className={`text-sm font-bold ${plan === "premium" ? "text-orange-100" : "text-slate-500"}`}>~3000 FCFA/mois</span>
                        </div>
                        <p className={`text-sm ${plan === "premium" ? "text-orange-50" : "text-slate-500"}`}>Offres illimitées, accès complet à la CVthèque, matching IA avancé.</p>
                      </div>
                    </>
                  ) : (
                    <div className="p-4 rounded-2xl border-2 border-purple-500 bg-purple-50 relative overflow-hidden">
                      <div className="flex justify-between items-center mb-2">
                        <h4 className="font-bold text-slate-800 flex items-center gap-2">
                          <Users size={18} className="text-purple-600"/> Plan Cabinet
                        </h4>
                        <span className="text-sm font-bold text-slate-500">~10 000 FCFA/mois</span>
                      </div>
                      <p className="text-sm text-slate-600 mb-3">Multi-recruteurs (jusqu'à 50), gestion des viviers, export de données.</p>
                      <div className="text-xs font-semibold text-purple-700 bg-purple-100 p-2 rounded-lg inline-block">Essai gratuit de 14 jours inclus</div>
                    </div>
                  )}

                  <div className="pt-4">
                    <button
                      type="submit"
                      disabled={isLoading}
                      className="w-full flex justify-center items-center gap-2 py-4 px-4 rounded-xl text-sm font-bold text-white bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 shadow-lg shadow-orange-500/30 hover:shadow-orange-500/40 hover:-translate-y-0.5 transition-all disabled:opacity-70"
                    >
                      {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : (
                        <>
                          Créer mon espace
                          <CheckCircle2 size={18} />
                        </>
                      )}
                    </button>
                    {accountType === "entreprise" && plan === "premium" && (
                      <button 
                        type="button" 
                        onClick={() => { setPlan("freemium"); handleSubmit(); }}
                        className="w-full mt-3 py-2 text-sm font-medium text-slate-500 hover:text-slate-800 transition-colors"
                      >
                        Passer pour l'instant (Démarrer en Freemium)
                      </button>
                    )}
                  </div>
                </div>
              )}
            </form>

            <div className="mt-8 text-center">
              <p className="text-sm font-medium text-slate-500">
                Vous avez déjà un compte ?{" "}
                <Link to="/login" className="text-orange-600 font-bold hover:text-orange-700 underline decoration-orange-200 underline-offset-4">
                  Se connecter
                </Link>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
