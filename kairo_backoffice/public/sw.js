const CACHE_NAME = 'kairo-admin-v2';

// Install event - normally used to cache core assets
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

// Activate event - normally used to clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => clients.claim())
  );
});

// Fetch event - simple network-first strategy for a basic PWA
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request).catch(() => {
      // If network fails, try to return from cache
      return caches.match(event.request);
    })
  );
});
