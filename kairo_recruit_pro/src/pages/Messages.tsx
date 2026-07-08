import { useEffect, useState } from "react";
import { MessageSquare, Send, User } from "lucide-react";
import { useMessageStore } from "../store/useMessageStore";
import { useAuthStore } from "../store/useAuthStore";

export function Messages() {
  const { user } = useAuthStore();
  const { 
    chats, 
    activeChatId, 
    messages, 
    initializeChatsListener, 
    setActiveChat, 
    initializeMessagesListener, 
    sendMessage 
  } = useMessageStore();
  
  const [inputText, setInputText] = useState("");

  useEffect(() => {
    if (user?.uid) {
      const unsub = initializeChatsListener(user.uid);
      return () => unsub();
    }
  }, [user?.uid, initializeChatsListener]);

  useEffect(() => {
    if (activeChatId) {
      const unsub = initializeMessagesListener(activeChatId);
      return () => unsub();
    }
  }, [activeChatId, initializeMessagesListener]);

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || !activeChatId || !user?.uid) return;
    
    sendMessage(activeChatId, user.uid, inputText.trim());
    setInputText("");
  };

  const activeChat = chats.find(c => c.id === activeChatId);
  // Identifie le candidat (l'autre participant)
  const candidateId = activeChat?.participantIds.find(id => id !== user?.uid);
  const candidateName = candidateId ? activeChat?.participantNames[candidateId] : '';
  const candidateAvatar = candidateId ? activeChat?.participantAvatars[candidateId] : '';

  return (
    <div className="h-full flex flex-col">
      <div className="mb-6 flex-shrink-0">
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Messagerie</h1>
        <p className="text-slate-500 dark:text-slate-400">Échangez directement avec vos candidats.</p>
      </div>
      
      <div className="flex-1 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden flex shadow-sm min-h-0">
        {/* Chat List */}
        <div className="w-1/3 border-r border-slate-200 dark:border-slate-800 flex flex-col">
          <div className="p-4 border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950/50">
            <input 
              type="text" 
              placeholder="Rechercher une conversation..." 
              className="w-full px-3 py-2 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-primary"
            />
          </div>
          
          <div className="flex-1 overflow-y-auto">
            {chats.length === 0 ? (
              <div className="flex flex-col items-center justify-center text-slate-400 p-8 text-center h-full">
                <MessageSquare className="w-12 h-12 mb-3 opacity-50" />
                <p>Aucune conversation.</p>
              </div>
            ) : (
              chats.map(chat => {
                const otherId = chat.participantIds.find(id => id !== user?.uid);
                const name = otherId ? chat.participantNames[otherId] : 'Candidat';
                const avatar = otherId ? chat.participantAvatars[otherId] : '';
                const unread = user?.uid ? (chat.unreadCounts[user.uid] || 0) : 0;
                
                return (
                  <div 
                    key={chat.id}
                    onClick={() => setActiveChat(chat.id)}
                    className={`p-4 border-b border-slate-100 dark:border-slate-800/50 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors flex items-center ${activeChatId === chat.id ? 'bg-primary/5 dark:bg-primary/10' : ''}`}
                  >
                    {avatar ? (
                      <img src={avatar} alt={name} className="w-12 h-12 rounded-full object-cover" />
                    ) : (
                      <div className="w-12 h-12 rounded-full bg-slate-200 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <User className="w-6 h-6" />
                      </div>
                    )}
                    <div className="ml-3 flex-1 overflow-hidden">
                      <div className="flex justify-between items-baseline">
                        <h4 className="font-semibold text-slate-900 dark:text-white truncate">{name}</h4>
                        <span className="text-xs text-slate-500">
                          {chat.lastMessageTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                        </span>
                      </div>
                      <p className={`text-sm truncate ${unread > 0 ? 'font-bold text-slate-900 dark:text-white' : 'text-slate-500'}`}>
                        {chat.lastSenderId === user?.uid ? 'Vous: ' : ''}{chat.lastMessage || 'Nouvelle conversation'}
                      </p>
                    </div>
                    {unread > 0 && (
                      <div className="ml-2 bg-primary text-white text-xs font-bold w-5 h-5 rounded-full flex items-center justify-center">
                        {unread}
                      </div>
                    )}
                  </div>
                )
              })
            )}
          </div>
        </div>

        {/* Chat Area */}
        <div className="flex-1 flex flex-col bg-slate-50 dark:bg-slate-950/30">
          {!activeChatId ? (
            <div className="flex-1 flex flex-col items-center justify-center text-slate-400">
              <MessageSquare className="w-16 h-16 mb-4 opacity-20" />
              <h3 className="text-lg font-medium text-slate-600 dark:text-slate-300">Vos Messages</h3>
              <p className="text-sm text-slate-500 max-w-sm text-center mt-2">
                Sélectionnez une conversation sur la gauche pour commencer à discuter avec un candidat.
              </p>
            </div>
          ) : (
            <>
              {/* Chat Header */}
              <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 flex items-center shadow-sm">
                {candidateAvatar ? (
                  <img src={candidateAvatar} alt={candidateName} className="w-10 h-10 rounded-full object-cover" />
                ) : (
                  <div className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-800 flex items-center justify-center">
                    <User className="w-5 h-5 text-slate-500" />
                  </div>
                )}
                <div className="ml-3">
                  <h3 className="font-bold text-slate-900 dark:text-white">{candidateName || 'Candidat'}</h3>
                  <p className="text-xs text-green-500 font-medium">Actif récemment</p>
                </div>
              </div>

              {/* Messages Flow */}
              <div className="flex-1 p-6 overflow-y-auto flex flex-col space-y-4">
                {messages.map((msg) => {
                  const isMe = msg.senderId === user?.uid;
                  return (
                    <div key={msg.id} className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}>
                      <div 
                        className={`max-w-[70%] px-4 py-2.5 rounded-2xl ${
                          isMe 
                            ? 'bg-primary text-white rounded-br-sm shadow-md shadow-primary/20' 
                            : 'bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white rounded-bl-sm shadow-sm'
                        }`}
                      >
                        <p>{msg.text}</p>
                        <p className={`text-[10px] mt-1 text-right ${isMe ? 'text-primary-foreground/70' : 'text-slate-500'}`}>
                          {msg.timestamp.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Input Area */}
              <div className="p-4 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800">
                <form onSubmit={handleSend} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={inputText}
                    onChange={(e) => setInputText(e.target.value)}
                    placeholder="Écrivez un message..."
                    className="flex-1 bg-slate-100 dark:bg-slate-950 border border-transparent focus:bg-white dark:focus:bg-slate-900 focus:border-primary px-4 py-3 rounded-full text-slate-900 dark:text-white transition-all outline-none"
                  />
                  <button 
                    type="submit"
                    disabled={!inputText.trim()}
                    className="bg-primary hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed text-white p-3 rounded-full transition-colors flex items-center justify-center"
                  >
                    <Send className="w-5 h-5" />
                  </button>
                </form>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
