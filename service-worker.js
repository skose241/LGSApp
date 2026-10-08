const onbellekAdi="lgs-v1";
const onbellekDosyalari=[
    "/LGSApp/offline.html",
    "/LGSApp/assets/css/style.css",
    "/LGSApp/assets/js/custom.js"
];

self.addEventListener("install",function(olay){
    olay.waitUntil(
        caches.open(onbellekAdi).then(function(onbellek){
            return onbellek.addAll(onbellekDosyalari);
        })
    );

    self.skipWaiting();
});

self.addEventListener("activate", function (olay){
    olay.waitUntil(
        caches.keys().then(function (adlar){
            return Promise.all(
                adlar.filter(function (ad){
                    return ad!==onbellekAdi;
                }).map(function(ad){
                    return caches.delete(ad);
                })
            );
        })
    );

    self.clients.claim();
});

self.addEventListener("fetch",function(olay){
    if (olay.request.method!=="GET") {
        return;
    }

    olay.respondWith(
        fetch(olay.request).catch(function (){
            return caches.match(olay.request).then(function(cevap){
                return cevap || caches.match("/LGSApp/offline.html");
            });
        })
    );
});