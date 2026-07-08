import { create } from 'zustand';
import { db } from '../lib/firebase';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  onSnapshot,
  addDoc,
  serverTimestamp,
  updateDoc,
  doc,
  getDoc,
  getDocs
} from 'firebase/firestore';

export interface Message {
  id: string;
  senderId: string;
  text: string;
  timestamp: Date;
  isRead: boolean;
}

export interface Chat {
  id: string;
  participantIds: string[];
  participantNames: Record<string, string>;
  participantAvatars: Record<string, string>;
  lastMessage: string;
  lastSenderId: string;
  lastMessageTime: Date;
  unreadCounts: Record<string, number>;
  typingStatus?: Record<string, boolean>;
}

interface MessageState {
  chats: Chat[];
  activeChatId: string | null;
  messages: Message[];
  isLoadingChats: boolean;
  isLoadingMessages: boolean;
  error: string | null;
  
  initializeChatsListener: (currentUserId: string) => () => void;
  setActiveChat: (chatId: string) => void;
  initializeMessagesListener: (chatId: string) => () => void;
  sendMessage: (chatId: string, senderId: string, text: string) => Promise<void>;
  createChatWithUser: (currentUserId: string, currentUserData: any, targetUserId: string, targetUserData: any) => Promise<string>;
}

export const useMessageStore = create<MessageState>((set) => ({
  chats: [],
  activeChatId: null,
  messages: [],
  isLoadingChats: false,
  isLoadingMessages: false,
  error: null,

  initializeChatsListener: (currentUserId: string) => {
    set({ isLoadingChats: true });
    
    const q = query(
      collection(db, 'chats'),
      where('participantIds', 'array-contains', currentUserId),
      orderBy('lastMessageTime', 'desc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const chats: Chat[] = [];
      snapshot.forEach((docSnap) => {
        const data = docSnap.data();
        chats.push({
          id: docSnap.id,
          participantIds: data.participantIds || [],
          participantNames: data.participantNames || {},
          participantAvatars: data.participantAvatars || {},
          lastMessage: data.lastMessage || '',
          lastSenderId: data.lastSenderId || '',
          lastMessageTime: data.lastMessageTime?.toDate() || new Date(),
          unreadCounts: data.unreadCounts || {},
        });
      });
      set({ chats, isLoadingChats: false });
    }, (error) => {
      console.error("Erreur chats:", error);
      set({ error: "Erreur de chargement des conversations.", isLoadingChats: false });
    });

    return unsubscribe;
  },

  setActiveChat: (chatId: string) => {
    set({ activeChatId: chatId, messages: [] });
  },

  initializeMessagesListener: (chatId: string) => {
    set({ isLoadingMessages: true });
    
    const q = query(
      collection(db, `chats/${chatId}/messages`),
      orderBy('timestamp', 'asc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const messages: Message[] = [];
      snapshot.forEach((docSnap) => {
        const data = docSnap.data();
        messages.push({
          id: docSnap.id,
          senderId: data.senderId,
          text: data.text,
          timestamp: data.timestamp?.toDate() || new Date(),
          isRead: data.isRead || false,
        });
      });
      set({ messages, isLoadingMessages: false });
    }, (error) => {
      console.error("Erreur messages:", error);
      set({ error: "Erreur de chargement des messages.", isLoadingMessages: false });
    });

    return unsubscribe;
  },

  sendMessage: async (chatId: string, senderId: string, text: string) => {
    try {
      // Add message
      await addDoc(collection(db, `chats/${chatId}/messages`), {
        senderId,
        text,
        timestamp: serverTimestamp(),
        isRead: false
      });

      // Update chat meta
      const chatRef = doc(db, 'chats', chatId);
      const chatSnap = await getDoc(chatRef);
      if (chatSnap.exists()) {
        const chatData = chatSnap.data();
        const otherUserId = chatData.participantIds.find((id: string) => id !== senderId);
        
        const newUnreadCounts = { ...chatData.unreadCounts };
        if (otherUserId) {
          newUnreadCounts[otherUserId] = (newUnreadCounts[otherUserId] || 0) + 1;
        }

        await updateDoc(chatRef, {
          lastMessage: text,
          lastSenderId: senderId,
          lastMessageTime: serverTimestamp(),
          unreadCounts: newUnreadCounts
        });
      }
    } catch (e) {
      console.error("Erreur lors de l'envoi:", e);
    }
  },

  createChatWithUser: async (currentUserId, currentUserData, targetUserId, targetUserData) => {
    const q = query(
      collection(db, 'chats'),
      where('participantIds', 'array-contains', currentUserId)
    );
    
    const snap = await getDocs(q);
    let existingChatId: string | null = null;
    snap.forEach((docSnap) => {
      if (docSnap.data().participantIds.includes(targetUserId)) {
        existingChatId = docSnap.id;
      }
    });

    if (existingChatId) return existingChatId;

    const docRef = await addDoc(collection(db, 'chats'), {
      participantIds: [currentUserId, targetUserId],
      participantNames: {
        [currentUserId]: currentUserData.name || 'Recruteur',
        [targetUserId]: targetUserData.name || 'Candidat'
      },
      participantAvatars: {
        [currentUserId]: currentUserData.photoUrl || '',
        [targetUserId]: targetUserData.photoUrl || ''
      },
      lastMessage: '',
      lastSenderId: '',
      lastMessageTime: serverTimestamp(),
      unreadCounts: {
        [currentUserId]: 0,
        [targetUserId]: 0
      },
      typingStatus: {
        [currentUserId]: false,
        [targetUserId]: false
      }
    });

    return docRef.id;
  }
}));
