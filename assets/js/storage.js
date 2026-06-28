// Storage Utility Functions

export const Storage = {
    // Auth Keys
    USER_KEY: 'kairo_user',
    
    // Data Keys
    PROFILE_KEY: 'kairo_profile',
    CV_KEY: 'kairo_cv',

    // Generic Methods
    set(key, value) {
        localStorage.setItem(key, JSON.stringify(value));
    },

    get(key) {
        const item = localStorage.getItem(key);
        return item ? JSON.parse(item) : null;
    },

    remove(key) {
        localStorage.removeItem(key);
    },

    // Specific Methods
    setUser(user) {
        this.set(this.USER_KEY, user);
    },

    getUser() {
        return this.get(this.USER_KEY);
    },

    logout() {
        this.remove(this.USER_KEY);
    },

    setProfile(profile) {
        this.set(this.PROFILE_KEY, profile);
    },

    getProfile() {
        return this.get(this.PROFILE_KEY);
    },

    setCvData(data) {
        this.set(this.CV_KEY, data);
    },

    getCvData() {
        return this.get(this.CV_KEY);
    }
};
