#!/bin/bash

# AI Snake Game Launcher
# This script starts a local web server and opens the game in your browser

echo "🐍 Starting AI Snake Game..."
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    echo "✓ Python 3 found"
    echo "✓ Starting web server on http://localhost:8000"
    echo ""
    echo "🎮 Open your browser and navigate to:"
    echo "   http://localhost:8000/snake-ai-game.html"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    # Start the server
    python3 -m http.server 8000
else
    echo "❌ Python 3 not found. Please install Python 3 or open snake-ai-game.html directly in your browser."
    exit 1
fi
