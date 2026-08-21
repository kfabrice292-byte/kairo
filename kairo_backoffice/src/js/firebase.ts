// @ts-nocheck
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';
import { getFunctions } from 'firebase/functions';

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyDdVK9zAdqkjqaH0XvfSlT-Rp9yWc5Fne0",
  projectId: "kairo-522c2",
  storageBucket: "kairo-522c2.firebasestorage.app",
  authDomain: "kairo-522c2.firebaseapp.com",
  appId: "1:597307613597:web:unknown",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);
const functions = getFunctions(app);

export { auth, db, storage, functions };
