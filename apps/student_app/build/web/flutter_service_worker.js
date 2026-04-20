'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "4a9efa15d66ea5335c2bc0d245c08fd7",
"assets/AssetManifest.bin.json": "2c019f2fc1bcd1237655e0fc1943a122",
"assets/assets/audio/music/cool_ward_loop.mp3": "239d66ff320e9b81418dfed9af42d7eb",
"assets/assets/audio/music/heartbeat_hallway.mp3": "37b9dcd36243b5517051c6113646b9c9",
"assets/assets/audio/music/quiet_ward_rounds.mp3": "1f4c86e5c1546fd96b1f257eb0899e9a",
"assets/assets/audio/music/ward_carousel.mp3": "57693ad4abef5520698edd191d7bfeae",
"assets/assets/audio/sfx/click.wav": "e291ffa35b3f3103978e088eb829abab",
"assets/assets/audio/sfx/error.mp3": "b33fc6a84e453a9e8cc7091633ae00be",
"assets/assets/audio/sfx/incorrect.mp3": "b33fc6a84e453a9e8cc7091633ae00be",
"assets/assets/audio/sfx/pop.wav": "2c6dedbbf153d878a6ac031a6fcb2199",
"assets/assets/audio/sfx/success.mp3": "9ebf31294c9fe3a9569fcf0bf1067bcb",
"assets/assets/icons/floating/K%25C3%25A9p1.png": "76b228cce02bd13db1d939bedcde63c7",
"assets/assets/icons/floating/K%25C3%25A9p10.png": "a63d8942f79907368683d446624a2b59",
"assets/assets/icons/floating/K%25C3%25A9p11.png": "ffce946e117a94fe3920c28f8779e503",
"assets/assets/icons/floating/K%25C3%25A9p12.png": "a3f4c5d90fdf8cd73daad883edeaf3b7",
"assets/assets/icons/floating/K%25C3%25A9p13.png": "915b09a2559c82c77e3181b165940dbc",
"assets/assets/icons/floating/K%25C3%25A9p14.png": "56e375f3afcc102c37fd8dac79d4c925",
"assets/assets/icons/floating/K%25C3%25A9p15.png": "0a7b6e3aea5e87a9f38ce02a04c1c233",
"assets/assets/icons/floating/K%25C3%25A9p16.png": "d4cc162973d4d6b4c6c7beba333cdba7",
"assets/assets/icons/floating/K%25C3%25A9p17.png": "a211dd6298480708d3dfa90f926d61dd",
"assets/assets/icons/floating/K%25C3%25A9p18.png": "2ff71b5e0ebda722961349082fcd9d3d",
"assets/assets/icons/floating/K%25C3%25A9p19.png": "2f78f558236ec59fd4918bea42c2a172",
"assets/assets/icons/floating/K%25C3%25A9p2.png": "40a1481f7bd895208177a4403ba8e12d",
"assets/assets/icons/floating/K%25C3%25A9p20.png": "53dbe9ffa95a944018f965d2aa587061",
"assets/assets/icons/floating/K%25C3%25A9p21.png": "c3b1cd9fd6354bfc21a3dac6457bf9bf",
"assets/assets/icons/floating/K%25C3%25A9p22.png": "d2f5ed14e4b96eebaede98b2eaf35ed5",
"assets/assets/icons/floating/K%25C3%25A9p23.png": "a69df700c345ed6dbd946d91b9701725",
"assets/assets/icons/floating/K%25C3%25A9p24.png": "038f39709901da6ef668660eb7784fa4",
"assets/assets/icons/floating/K%25C3%25A9p25.png": "15853ccbf68165a35731ae589bc68397",
"assets/assets/icons/floating/K%25C3%25A9p26.png": "c0f51dbc108acf5343591e90684bbe5a",
"assets/assets/icons/floating/K%25C3%25A9p27.png": "547576684c0be05d7bca127df7fea5db",
"assets/assets/icons/floating/K%25C3%25A9p28.png": "9dca2b51d6e00025a935d9b690bc0ed3",
"assets/assets/icons/floating/K%25C3%25A9p29.png": "5e9faf022b3d52ddf7d640ea2094a6f2",
"assets/assets/icons/floating/K%25C3%25A9p3.png": "a8c0e9ad3832bc6be26f6a479c45b6b8",
"assets/assets/icons/floating/K%25C3%25A9p30.png": "4cecb47abc3f2772d3417f5f1021c990",
"assets/assets/icons/floating/K%25C3%25A9p31.png": "7157c5c8a6cf4fc645607d3657f09a94",
"assets/assets/icons/floating/K%25C3%25A9p32.png": "5bed76bc8b30a9c25ab4f88c535fcb11",
"assets/assets/icons/floating/K%25C3%25A9p33.png": "5b2d718984118062c44870574cd351dc",
"assets/assets/icons/floating/K%25C3%25A9p34.png": "aa02f908e730baa543df44808aa65c70",
"assets/assets/icons/floating/K%25C3%25A9p35.png": "e566823d369462babbd35428bbc6cf70",
"assets/assets/icons/floating/K%25C3%25A9p36.png": "ca670fa7b61965655bb1c1cb2f67cc6b",
"assets/assets/icons/floating/K%25C3%25A9p37.png": "a6780c6077891941e584457d41cde66d",
"assets/assets/icons/floating/K%25C3%25A9p38.png": "f30c2390b3e77b01222aa541d045d42a",
"assets/assets/icons/floating/K%25C3%25A9p39.png": "a30dfe75d8e6b9743c5fac6b5bc1e96a",
"assets/assets/icons/floating/K%25C3%25A9p4.png": "807b85f3b41b998b3befa26238192005",
"assets/assets/icons/floating/K%25C3%25A9p40.png": "903b74c77b981349caa59b9fd5c6a336",
"assets/assets/icons/floating/K%25C3%25A9p41.png": "a378a07a114726e3c9182eb6d023126a",
"assets/assets/icons/floating/K%25C3%25A9p42.png": "0ee69ccb369c2d4d9ba4452a38f7f030",
"assets/assets/icons/floating/K%25C3%25A9p43.png": "bf9d3a1e742b42305b59a31b35c4051e",
"assets/assets/icons/floating/K%25C3%25A9p44.png": "c9ebac331ef2417faa4213c0de7d434c",
"assets/assets/icons/floating/K%25C3%25A9p45.png": "d999799ec47881b4e2560c614e8a2c42",
"assets/assets/icons/floating/K%25C3%25A9p46.png": "db2ffdc9c240be764f642d277205d098",
"assets/assets/icons/floating/K%25C3%25A9p47.png": "98048d182cc1778b855f46f16f53d4e7",
"assets/assets/icons/floating/K%25C3%25A9p48.png": "52900070f5b163427d29b72ac93247bd",
"assets/assets/icons/floating/K%25C3%25A9p49.png": "2bf69e11357d1b8be066e3b10de5a027",
"assets/assets/icons/floating/K%25C3%25A9p5.png": "c8c95727e4f859a616e1896b952d506c",
"assets/assets/icons/floating/K%25C3%25A9p50.png": "0bb7edbb41f69697ddef302994ee59ec",
"assets/assets/icons/floating/K%25C3%25A9p6.png": "6f37912070a505c6e35b791637c9bbbf",
"assets/assets/icons/floating/K%25C3%25A9p7.png": "657c8a4c0e398ccfd71701bcdebf6e6f",
"assets/assets/icons/floating/K%25C3%25A9p8.png": "f7cbcd544ade0fa11ed28f1701a20c9d",
"assets/assets/icons/floating/K%25C3%25A9p9.png": "e5c807bd30cc87458e4a4ab10d125685",
"assets/assets/images/characters/hemmy.svg": "2c07bd361dd5196879353b61d0415e43",
"assets/assets/images/furniture/computer_0.webp": "b2e7b241ee5ba0cec6c33cd9f162b277",
"assets/assets/images/furniture/computer_1.webp": "c9b223f501e41aefe2e816b9d124deef",
"assets/assets/images/furniture/computer_2.webp": "f77a771eeeba34c13b59fa7053dbe8fc",
"assets/assets/images/furniture/computer_3.webp": "0581a2ec51a5feabc6728f4f86c2f870",
"assets/assets/images/furniture/cornercabinet_0.webp": "0f5ae5984b9e6fb146a835849b2fa520",
"assets/assets/images/furniture/cornercabinet_1.webp": "822f2222fd95c9cfa347aa535cb62317",
"assets/assets/images/furniture/cornercabinet_2.webp": "39f5fa25b6741abe2479759a3b2b2f1b",
"assets/assets/images/furniture/cornercabinet_3.webp": "262dd348d80265b28ee51348915160ca",
"assets/assets/images/furniture/cornercabinet_4.webp": "7d4c65462c03da50bc444923386f5fe3",
"assets/assets/images/furniture/desk_0.webp": "2acc9d3797badef8cf5f231c44a4b983",
"assets/assets/images/furniture/desk_1.webp": "4d12aa52bd314cc6429ddacac4f740bd",
"assets/assets/images/furniture/desk_2.webp": "563637be0e6a0f25a8daed43619820d7",
"assets/assets/images/furniture/desk_3.webp": "760829d143abc87973030c11858dac51",
"assets/assets/images/furniture/desk_4.webp": "ff6ea4ab6e777db9daf080e482f8a724",
"assets/assets/images/furniture/gurney_0.webp": "dc3bb266ca95a3987d76bdc7c6b551dc",
"assets/assets/images/furniture/gurney_1.webp": "b1d248aaef661800caa5811234311b04",
"assets/assets/images/furniture/gurney_2.webp": "30ae02543921c7ff19b9d8eb6834a4d8",
"assets/assets/images/furniture/gurney_3.webp": "d0768daf38362ca348ad77bca2c198c3",
"assets/assets/images/furniture/rug_0.webp": "6549a4877d0c946df436b28f66df9f10",
"assets/assets/images/furniture/rug_1.webp": "343f36c6276093024faa817ad9f5f781",
"assets/assets/images/furniture/rug_2.webp": "c45338acf0fbef61e3d2f737e0436d7a",
"assets/assets/images/furniture/rug_3.webp": "180f2534ea2a171718046b297e032c48",
"assets/assets/images/room/room_0.webp": "b21b59dcf3206a3b007b6ed0cd909201",
"assets/assets/logo/app_icon.png": "5c57516e059eeda541683d09cc155e18",
"assets/assets/ui/buttons/equip.png": "e019f8ebfb01b0b292330479fce8c5dc",
"assets/assets/ui/buttons/heart.png": "11184f950eb4e7e5ef4688792b04b127",
"assets/assets/ui/buttons/home.png": "ba56007a0a58c9e024eb0418a338ea47",
"assets/assets/ui/buttons/network.png": "31984703a2ce1b40e82b86bd4df1493a",
"assets/assets/ui/buttons/profile.png": "a8604270e437db061a591427da751bac",
"assets/assets/ui/buttons/settings.png": "e4fa7eca95ce46a9ee39dcbf1fb9b04e",
"assets/assets/ui/buttons/shop.png": "b041e7041aef9208e104512734ea42a7",
"assets/assets/ui/buttons/stethoscope_hud.png": "bc2148ac1d8da94e4a0f4b27b60a6ebc",
"assets/assets/ui/buttons/swords.png": "c6e3562d89135bdd4d1f656a1c5b6c88",
"assets/FontManifest.json": "c75f7af11fb9919e042ad2ee704db319",
"assets/fonts/MaterialIcons-Regular.otf": "443f458096837321416658d2ce99727f",
"assets/NOTICES": "7cb004c0dba5f89d42135cacdc1d3f4c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "1fcba7a59e49001aa1b4409a25d425b0",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "b2703f18eee8303425a5342dba6958db",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "5b8d20acec3e57711717f61417c1be44",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"drift_worker.js": "fe6bf44feec6cc9fb1784a04e40e5e32",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "cd246a88908312f1d91e5f0cbf538c50",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "305ac69eb80d32ea522ac6f27ed20ba1",
"/": "305ac69eb80d32ea522ac6f27ed20ba1",
"main.dart.js": "2a4e37629a4e1401dd65e0f095c53b41",
"manifest.json": "6818dc0048f086a6849c17ab04b5b189",
"sqlite3.wasm": "59b0b16e9818fad51d4ec7c1400fd1dd",
"version.json": "fd439e1bd97b0984decd1e7ab9d3b58a",
"_headers": "6439ccf6462ec27e5d0812dd9a232d9b",
"_redirects": "2850381ae04204d7e647f8effb35d13e"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
