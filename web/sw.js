// SearchWars Service Worker
// Caches the Flutter app shell for offline play
//
// ⚠️  VERSIONING: bump CACHE_NAME (e.g. searchwars-v2) every time you deploy
//     a new build, so returning users get fresh files instead of stale cache.

// Tie cache version to your app version — update on every release
const CACHE_NAME = 'searchwars-v1';

// Core Flutter web shell — verified against Flutter 3.x build output in build/web/
// After each `flutter build web --release`, open build/web/ and confirm these
// filenames still exist. Flutter occasionally renames files between versions.
const PRE_CACHE = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/flutter.js',
  '/main.dart.js',
  '/manifest.json',
  '/favicon.png',
  '/icon_512.png',
  '/assets/AssetManifest.json',
  '/assets/FontManifest.json',
  '/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  // dataset.json (~0.91 MB) is intentionally NOT pre-cached here.
  // It is large enough to noticeably slow the first install.
  // The network-first fetch handler below will cache it automatically
  // the first time the user plays, without blocking the SW install.
];

// ── Install ───────────────────────────────────────────────────────────────────

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Pre-caching app shell');
      return cache.addAll(PRE_CACHE).catch((err) => {
        console.warn('[SW] Pre-cache partial fail:', err);
      });
    })
  );
  self.skipWaiting();
});

// ── Activate ──────────────────────────────────────────────────────────────────

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// ── Fetch — Network first, cache fallback ─────────────────────────────────────

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Skip Firebase / external API calls — always live
  if (url.hostname.includes('firebasedatabase') ||
      url.hostname.includes('firebase') ||
      url.hostname.includes('googleapis')) {
    return;
  }

  // For navigation requests, serve index.html from cache if offline
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() =>
        caches.match('/index.html')
      )
    );
    return;
  }

  // Network first with cache fallback
  // This also lazily caches dataset.json and any other assets on first load
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        if (response && response.status === 200 && response.type === 'basic') {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});

// ── Push Notifications ────────────────────────────────────────────────────────

self.addEventListener('push', (event) => {
  if (!event.data) return;
  const data = event.data.json();
  event.waitUntil(
    self.registration.showNotification(data.title || 'SearchWars', {
      body:     data.body || "A new SearchWars challenge is ready! 🔥",
      icon:     '/favicon.png',
      badge:    '/favicon.png',
      tag:      'searchwars-notification',
      renotify: false,
      data:     { url: data.url || '/' },
    })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.openWindow(event.notification.data?.url || '/')
  );
});
