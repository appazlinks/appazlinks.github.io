// AZLinks - cache para funcionar sem internet (colocar na mesma pasta do index.html)
const CACHE = 'azlinks-v2';
const CORE = ['./', './index.html', './manifest.json', './azlinks-192x192.png', './azlinks-512x512.png'];

self.addEventListener('install', e => {
    e.waitUntil(
        caches.open(CACHE)
            .then(c => Promise.all(CORE.map(u => c.add(u).catch(() => {})))) // um arquivo ausente não impede a instalação
            .then(() => self.skipWaiting())
    );
});

self.addEventListener('activate', e => {
    e.waitUntil(
        caches.keys()
            .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
            .then(() => self.clients.claim())
    );
});

// Online: sempre busca a versão mais nova e guarda no cache. Offline: usa o que foi guardado.
self.addEventListener('fetch', e => {
    const r = e.request;
    if (r.method !== 'GET') return;
    const host = new URL(r.url).hostname;
    if (host.endsWith('script.google.com') || host.endsWith('googleusercontent.com')) return; // sincronização nunca vai para o cache
    e.respondWith(
        caches.open(CACHE).then(cache =>
            fetch(r).then(resp => {
                if (resp && (resp.ok || resp.type === 'opaque')) cache.put(r, resp.clone());
                return resp;
            }).catch(() =>
                cache.match(r).then(m => m || (r.mode === 'navigate' ? cache.match('./index.html') : Response.error()))
            )
        )
    );
});
