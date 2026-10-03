// ==========================================================================
// Freiwild Spotify modded - extension
// Adds a version badge + menu entry. Uses the Spicetify extension API.
// ==========================================================================

(async function Freiwild() {
  const VERSION = "1.0.0";
  const NAME = "Freiwild Spotify modded";

  while (!Spicetify || !Spicetify.Menu || !Spicetify.showNotification) {
    await new Promise((resolve) => setTimeout(resolve, 100));
  }

  const info = () => {
    Spicetify.showNotification(`${NAME} v${VERSION}`, true, 3000);
  };

  Spicetify.Menu.addItem(
    `${NAME} - Version`,
    info,
    "info"
  );

  // Announce once shortly after launch (non-blocking, no error if UI busy)
  setTimeout(() => {
    try {
      Spicetify.showNotification(`${NAME} v${VERSION}`, true, 2500);
    } catch (e) {
      /* ignore */
    }
  }, 4000);
})();
