// Service worker : met l'app en cache pour un lancement rapide et gère le clic sur une notification.
const CACHE = "cs2live-v1";
const SHELL = ["./", "index.html", "manifest.webmanifest", "icon-180.png", "icon-192.png", "icon-512.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Réseau d'abord pour la page (mises à jour), cache en secours. Les appels API ne sont jamais mis en cache.
self.addEventListener("fetch", e => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET" || url.origin !== location.origin) return;
  e.respondWith(
    fetch(e.request)
      .then(r => { const copy = r.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); return r; })
      .catch(() => caches.match(e.request))
  );
});

// Clic sur une notification : ouvre l'app sur le match concerné.
self.addEventListener("notificationclick", e => {
  e.notification.close();
  const matchId = e.notification.data?.matchId;
  e.waitUntil((async () => {
    const all = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
    if (all.length) {
      const c = all[0];
      await c.focus();
      if (matchId) c.postMessage({ matchId });
    } else {
      await self.clients.openWindow("./");
    }
  })());
});
