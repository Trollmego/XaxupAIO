# 🐍 AI Snake Game

An intelligent Snake game that plays itself using the **A* pathfinding algorithm**. Watch as the AI navigates the board, avoids obstacles, and collects food automatically!

## Features

✨ **Smart AI Autopilot** - Uses A* pathfinding algorithm for intelligent navigation  
🎮 **Automatic Gameplay** - No manual controls needed, just watch the AI play  
📊 **Real-time Statistics** - Track score, high score, and snake length  
🎨 **Modern UI Design** - Beautiful gradient backgrounds and smooth animations  
🔄 **Game Controls** - Start, pause, and reset functionality  
💾 **High Score Persistence** - Saves your best score in browser localStorage  
🌙 **Visual Effects** - Glowing effects on snake and food with smooth rendering  

## How It Works

### A* Pathfinding Algorithm
The AI uses the A* (A-star) pathfinding algorithm to find the optimal path from the snake's head to the food. The algorithm:

1. **Calculates the shortest path** using Manhattan distance heuristic
2. **Avoids obstacles** including walls and the snake's own body
3. **Adapts dynamically** as the snake grows and the board changes
4. **Falls back to safe moves** when no direct path is available

### Fallback Logic
When the A* algorithm can't find a path to the food (e.g., when trapped), the AI switches to survival mode:
- Searches for any safe direction to move
- Prioritizes moves that keep the snake alive
- Prevents collision with walls and self

## Getting Started

### Option 1: Direct Browser Access
Simply open the HTML file in any modern web browser:
```bash
# Open in your default browser
open snake-ai-game.html

# Or use a specific browser
firefox snake-ai-game.html
chrome snake-ai-game.html
```

### Option 2: Local Web Server
For the best experience, serve the file through a local web server:

**Using Python 3:**
```bash
python3 -m http.server 8000
# Then visit: http://localhost:8000/snake-ai-game.html
```

**Using Node.js:**
```bash
npx http-server -p 8000
# Then visit: http://localhost:8000/snake-ai-game.html
```

**Using PHP:**
```bash
php -S localhost:8000
# Then visit: http://localhost:8000/snake-ai-game.html
```

## Game Controls

- **Start Game** - Begin the AI autopilot
- **Pause** - Pause/resume the game
- **Reset** - Reset the game to initial state

## Technical Details

### Technologies Used
- **HTML5 Canvas** - For game rendering
- **Vanilla JavaScript** - No external dependencies
- **CSS3** - Modern styling with gradients and animations

### Game Configuration
- **Grid Size**: 30x30 tiles (600x600 pixels)
- **Initial Speed**: 100ms per move
- **Speed Increase**: Gets faster as snake grows
- **Initial Snake Length**: 3 segments

### AI Implementation
```javascript
// A* pathfinding with Manhattan distance heuristic
function findPath(start, goal) {
    // Uses open set, closed set, and f-score calculation
    // Returns optimal path or null if no path exists
}

// Fallback safe move selection
function aiMove() {
    const path = findPath(head, food);
    if (path) {
        // Follow optimal path
    } else {
        // Find any safe direction
    }
}
```

## Game Mechanics

### Scoring
- **+10 points** for each food collected
- Snake grows by 1 segment per food
- High score is automatically saved

### Game Over Conditions
- Collision with walls
- Collision with snake's own body

### Visual Elements
- 🟢 **Green** - Snake head (with eyes)
- 🟩 **Light Green** - Snake body (fading opacity)
- 🔴 **Red** - Food (with glow effect)
- ⬛ **Dark Grid** - Game board with subtle grid lines

## Browser Compatibility

Works on all modern browsers:
- ✅ Chrome/Edge (Chromium)
- ✅ Firefox
- ✅ Safari
- ✅ Opera

## Performance

- Smooth 60 FPS rendering
- Efficient pathfinding algorithm
- Minimal CPU usage
- No external dependencies or libraries

## Future Enhancements

Possible improvements:
- Multiple difficulty levels
- Different AI algorithms (Hamiltonian cycle, etc.)
- Multiplayer mode (AI vs AI)
- Custom themes and skins
- Sound effects and music
- Mobile touch controls
- Leaderboard system

## License

This project is open source and available for educational purposes.

## Credits

Created with ❤️ using vanilla JavaScript and the A* pathfinding algorithm.

---

**Enjoy watching the AI play!** 🎮🐍
