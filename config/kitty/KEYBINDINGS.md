# Kitty Keybindings and Animations

## Keybindings

### Tab Management
- `Ctrl+Shift+T` - New tab
- `Ctrl+Shift+W` - Close current tab
- `Ctrl+Shift+]` - Next tab
- `Ctrl+Shift+[` - Previous tab
- `Ctrl+Shift+Alt+T` - New tab with current directory
- `Ctrl+Shift+1` to `Ctrl+Shift+9` - Switch to tab 1-9

### Window Management
- `Ctrl+Shift+Enter` - New window
- `Ctrl+Shift+Q` - Close window
- `Ctrl+Shift+R` - Resize window
- `Ctrl+Shift+F` - Toggle fullscreen
- `Ctrl+Shift+D` - Horizontal split
- `Ctrl+Shift+E` - Vertical split

### Clipboard
- `Ctrl+Shift+C` - Copy to clipboard
- `Ctrl+Shift+V` - Paste from clipboard
- `Ctrl+Shift+S` - Paste from primary selection
- `Ctrl+Shift+Alt+S` - Paste from selection (fallback)

### Scrolling & Search
- `Ctrl+Shift+Up/Down` - Scroll up/down
- `Ctrl+Shift+PageUp/PageDown` - Scroll page up/down
- `Ctrl+Shift+Home/End` - Scroll to top/bottom
- `Ctrl+Shift+F` - Search forward
- `Ctrl+Shift+B` - Search backward
- `Ctrl+Shift+G` - Find next
- `Ctrl+Shift+H` - Find previous

### Font Size
- `Ctrl+Shift+Plus` - Increase font size
- `Ctrl+Shift+Minus` - Decrease font size
- `Ctrl+Shift+0` - Reset font size

### Miscellaneous
- `Ctrl+Shift+L` - Clear screen and scrollback
- `Ctrl+Shift+U` - Unicode input
- `Ctrl+Shift+Z` - Suspend kitty
- `Ctrl+Shift+Escape` - Reset terminal

## Animations

### Cursor Animations
- `cursor_trail 1` - Smooth cursor trail effect
- `cursor_blink yes` - Blinking cursor
- `cursor_shape block` - Cursor shape (block, beam, underline)
- Cursor pulse effect - Subtle pulsing animation

### Window Animations
- `window_transition 0.15` - Smooth window open/close animations
- `tab_transition 0.1` - Smooth tab switching animations

### Visual Feedback
- `visual_bell yes` - Subtle flash on errors
- `visual_feedback yes` - Subtle flash on copy/paste operations
- `background_opacity 0.9` - Semi-transparent background with smooth transitions

### Performance
- All animations optimized for performance
- No lag or stuttering
- Smooth integration with Hyprland window manager

## Theme Integration
- All keybindings and animations work seamlessly with Wallust warm theme
- No conflicts with existing configurations
- Automatic theme synchronization maintained

### Additional Paste Methods
- Middle mouse click - Paste from selection
- Shift+Insert - Paste from selection


### Reliable Paste Methods
- `Ctrl+Shift+S` - Paste from primary selection (kitten clipboard)
- `Ctrl+Shift+Alt+S` - Paste from primary selection (fallback)
- Middle mouse click - Paste from selection
- `Shift+Insert` - Paste from selection


### Wayland Clipboard Notes
- On Wayland, `wayland_enable_primary_selection yes` is required
- If paste from selection doesn't work, restart kitty
- Middle mouse click and Shift+Insert should always work
