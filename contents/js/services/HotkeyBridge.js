.pragma library

var DEFAULT_SHORTCUTS = {
  togglePlay: "Space",
  nextTrack: "Ctrl+Right",
  previousTrack: "Ctrl+Left",
  faster: "Ctrl+Up",
  slower: "Ctrl+Down",
  bookmark: "Ctrl+B"
};

function keys() {
  return {
    togglePlay: DEFAULT_SHORTCUTS.togglePlay,
    nextTrack: DEFAULT_SHORTCUTS.nextTrack,
    previousTrack: DEFAULT_SHORTCUTS.previousTrack,
    faster: DEFAULT_SHORTCUTS.faster,
    slower: DEFAULT_SHORTCUTS.slower,
    bookmark: DEFAULT_SHORTCUTS.bookmark
  };
}
