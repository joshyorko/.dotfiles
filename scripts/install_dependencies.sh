#!/bin/bash

# scrapeCrawl Dependencies Installation Script
# This script installs all required dependencies for the refactored scrapeCrawl.py

set -e  # Exit on any error

echo "🔧 Setting up scrapeCrawl dependencies..."

# Check if uv is available
if ! command -v uv &> /dev/null; then
    echo "❌ uv is required but not installed. Please install uv first."
    echo "   Visit: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    uv venv .venv
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source .venv/bin/activate

# Install core dependencies
echo "📥 Installing core dependencies..."
uv pip install typer==0.19.2 rich==14.1.0 pydantic==2.11.9

# Install async dependencies
echo "📥 Installing async dependencies..."
uv pip install aiohttp==3.12.15 aiofiles==24.1.0 aiosqlite==0.21.0

# Install UI dependencies  
echo "📥 Installing UI dependencies..."
uv pip install click==8.3.0 pygments==2.19.2 markdown-it-py==4.0.0

# Install crawling dependencies
echo "📥 Installing web crawling dependencies..."
uv pip install requests==2.32.5 beautifulsoup4==4.14.0 lxml

# Install supporting libraries
echo "📥 Installing supporting libraries..."
uv pip install python-dotenv==1.1.1 xxhash packaging colorama
uv pip install pyopenssl cryptography rank-bm25 numpy snowballstemmer

# Install playwright
echo "📥 Installing playwright..."
uv pip install playwright==1.55.0

# Install crawl4ai (this might fail due to dependency conflicts)
echo "📥 Attempting to install crawl4ai..."
if uv pip install crawl4ai==0.6.3; then
    echo "✅ crawl4ai installed successfully"
else
    echo "⚠️  crawl4ai installation failed due to dependency conflicts"
    echo "   You may need to install it manually or use system packages"
fi

echo "🎉 Dependency installation completed!"
echo ""
echo "📋 To verify installation, run:"
echo "   source .venv/bin/activate"
echo "   python scripts/scrapeCrawl_refactored.py version"
echo ""
echo "🚀 To start using the tool:"
echo "   python scripts/scrapeCrawl_refactored.py crawl --help"