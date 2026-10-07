{{flutter_js}}
{{flutter_build_config}}

// Load CanvasKit from the application bundle instead of Google's CDN.
// This keeps the app usable behind campus firewalls, proxies, or offline.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: '/canvaskit/',
  },
});
