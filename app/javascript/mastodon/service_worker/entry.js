import { freeStorage } from '../storage/modifier';
import './web_push_notifications';

function openSystemCache() {
  return caches.open('mastodon-system');
}

function openWebCache() {
  return caches.open('mastodon-web');
}

function fetchRoot() {
  return fetch('/', { credentials: 'include' });
}

// Cause a new version of a registered Service Worker to replace an existing one
// that is already installed, and replace the currently active worker on open pages.
self.addEventListener('install', function(event) {
  event.waitUntil(Promise.all([openWebCache(), fetchRoot()]).then(([cache, root]) => cache.put('/', root)));
});
self.addEventListener('activate', function(event) {
  event.waitUntil(self.clients.claim());
});
self.addEventListener('fetch', function(event) {
  const url = new URL(event.request.url);

  if (url.pathname.startsWith('/web/')) {
    const asyncResponse = fetchRoot();
    const asyncCache = openWebCache();

    event.respondWith(asyncResponse.then(response => {
      if (response.ok) {
        return asyncCache.then(cache => cache.put('/', response))
                         .then(() => response.clone());
      }

      throw null;
    }).catch(() => asyncCache.then(cache => cache.match('/'))));
  } else if (url.pathname === '/auth/sign_out') {
    const asyncResponse = fetch(event.request);
    const asyncCache = openWebCache();

    event.respondWith(asyncResponse.then(response => {
      if (response.ok || response.type === 'opaqueredirect') {
        return Promise.all([
          asyncCache.then(cache => cache.delete('/')),
          indexedDB.deleteDatabase('mastodon'),
        ]).then(() => response);
      }

      return response;
    }));
  } else if (process.env.CDN_HOST ? url.host === process.env.CDN_HOST : url.pathname.startsWith('/system/')) {
    event.respondWith(openSystemCache().then(cache => {
      return cache.match(event.request.url).then(cached => {
        if (cached === undefined) {
          return fetch(event.request).then(fetched => {
            if (fetched.ok) {
              const put = cache.put(event.request.url, fetched.clone());

              put.catch(() => freeStorage());

              return put.then(() => {
                freeStorage();
                return fetched;
              });
            }

            return fetched;
          });
        }

        return cached;
      });
    }));
  }
});
