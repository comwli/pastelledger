// 오프라인 캐시: 캐시 먼저 응답하고 뒤에서 새 버전으로 갱신
const CACHE = "pl-v3";
const CORE = ["./", "index.html", "cloud.js", "firebase-config.js", "manifest.webmanifest", "icons/icon-180.png", "icons/icon-192.png", "icons/icon-512.png"];
const FB = "https://www.gstatic.com/firebasejs/";

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});

self.addEventListener("fetch", e => {
  const req = e.request;
  // 같은 출처 파일 + Firebase SDK만 캐시 (Firestore 통신은 건드리지 않음)
  if (req.method !== "GET" || (new URL(req.url).origin !== location.origin && !req.url.startsWith(FB))) return;
  e.respondWith(caches.open(CACHE).then(async c => {
    const hit = await c.match(req, { ignoreSearch: true });
    const net = fetch(req).then(res => { if (res.ok) c.put(req, res.clone()); return res; }).catch(() => hit);
    return hit || net;
  }));
});
