// sw.js - Service Worker لتطبيق إدارة المشاريع
const CACHE_NAME = 'project-management-v1';
const urlsToCache = [
    '/',
'/index.html',
'https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js',
'https://www.gstatic.com/firebasejs/10.8.0/firebase-auth-compat.js',
'https://www.gstatic.com/firebasejs/10.8.0/firebase-database-compat.js'
];

// تثبيت Service Worker وتخزين الملفات الأساسية
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
        .then(cache => {
            console.log('تم فتح التخزين المؤقت');
            return cache.addAll(urlsToCache);
        })
    );
});

// استرجاع الملفات من التخزين المؤقت
self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
        .then(response => {
            // إرجاع الملف من التخزين المؤقت إذا وجد
            if (response) {
                return response;
            }
            // وإلا تحميل من الشبكة
            return fetch(event.request);
        })
    );
});

// تحديث Service Worker
self.addEventListener('activate', event => {
    const cacheWhitelist = [CACHE_NAME];
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (cacheWhitelist.indexOf(cacheName) === -1) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
});
