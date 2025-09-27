#!/usr/bin/env python3

# /// script
# dependencies = [
#   "typer",
#   "rich",
#   "crawl4ai",
#   "playwright",
#   "aiohttp",
#   "aiofiles",
#   "pydantic"
# ]
# ///

"""
Modern Web Scraping Tool using Crawl4AI

A comprehensive web scraping tool built with the latest versions of crawl4ai, typer, and rich.
Provides enhanced error handling, better logging, and modern async patterns.
"""

import asyncio
import json
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, Tuple, List
import base64

import typer
from rich import print as rprint
from rich.console import Console
from rich.logging import RichHandler
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.markdown import Markdown
from rich.table import Table
from rich.panel import Panel
from pydantic import BaseModel, ConfigDict

# Initialize console and app
console = Console()
app = typer.Typer(
    name="scrapecrawl",
    help="Modern web scraping tool powered by Crawl4AI",
    add_completion=False,
    rich_markup_mode="rich"
)

# Configure rich logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler(console=console, rich_tracebacks=True)]
)
logger = logging.getLogger("scrapecrawl")


class CrawlConfig(BaseModel):
    """Configuration model for crawl operations."""
    model_config = ConfigDict(extra="forbid")
    
    url: str
    browser_type: str = "chromium"
    headless: bool = True
    screenshot: bool = False
    screenshot_wait_for: float = 2.0
    wait_for_images: bool = False
    extract_links: bool = False
    magic_mode: bool = False
    output_dir: Optional[Path] = None
    write_files: bool = False
    include_debug: bool = False
    
    def model_post_init(self, __context) -> None:
        """Post-initialization to set default output directory."""
        if self.output_dir is None:
            self.output_dir = Path.cwd() / "crawl_outputs"


class CrawlResult(BaseModel):
    """Structured result from crawl operation."""
    model_config = ConfigDict(extra="allow")
    
    success: bool
    url: str
    status_code: Optional[int] = None
    html: Optional[str] = None
    markdown: Optional[str] = None
    cleaned_html: Optional[str] = None
    links: Optional[List[Dict[str, str]]] = None
    media: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None
    screenshot: Optional[str] = None
    error: Optional[str] = None
    timestamp: datetime = datetime.now()


async def ensure_playwright_setup() -> bool:
    """Ensure Playwright browsers are installed and ready."""
    try:
        from playwright.async_api import async_playwright
        
        # Test if browser is available
        async with async_playwright() as p:
            try:
                browser = await p.chromium.launch(headless=True)
                await browser.close()
                return True
            except Exception as e:
                console.print(f"[yellow]Playwright browser not found: {e}[/yellow]")
                console.print("[blue]Installing Playwright browsers...[/blue]")
                
                import subprocess
                result = subprocess.run([
                    sys.executable, '-m', 'playwright', 'install', 'chromium'
                ], capture_output=True, text=True)
                
                if result.returncode == 0:
                    console.print("[green]✓ Playwright browsers installed successfully[/green]")
                    return True
                else:
                    console.print(f"[red]✗ Failed to install browsers: {result.stderr}[/red]")
                    return False
                    
    except ImportError:
        console.print("[red]✗ Playwright not installed[/red]")
        return False
    except Exception as e:
        console.print(f"[red]✗ Playwright setup error: {e}[/red]")
        return False


def create_output_directory(config: CrawlConfig) -> Path:
    """Create a timestamped output directory for crawl results."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Extract domain from URL for directory naming
    try:
        from urllib.parse import urlparse
        parsed = urlparse(config.url)
        domain = parsed.netloc.replace('www.', '').split('.')[0]
    except Exception:
        domain = "crawl"
    
    output_dir = config.output_dir / f"{domain}_{timestamp}"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    return output_dir


def save_results(result: CrawlResult, output_dir: Path, config: CrawlConfig) -> None:
    """Save crawl results to files with proper error handling."""
    try:
        # Save JSON result
        json_file = output_dir / "result.json"
        with open(json_file, 'w', encoding='utf-8') as f:
            # Convert to dict and handle serialization
            result_dict = result.model_dump(mode='json', exclude_none=True)
            # Truncate large strings for JSON
            for key in ['html', 'cleaned_html']:
                if result_dict.get(key) and len(result_dict[key]) > 50000:
                    result_dict[key] = result_dict[key][:50000] + "... (truncated)"
            
            json.dump(result_dict, f, indent=2, ensure_ascii=False, default=str)
        
        console.print(f"[green]✓ Results saved to: {json_file}[/green]")
        
        # Save individual files if requested
        if config.write_files and result.success:
            if result.markdown:
                md_file = output_dir / "content.md"
                md_file.write_text(result.markdown, encoding='utf-8')
                console.print(f"[green]✓ Markdown saved to: {md_file}[/green]")
            
            if result.html:
                html_file = output_dir / "content.html"
                html_file.write_text(result.html, encoding='utf-8')
                console.print(f"[green]✓ HTML saved to: {html_file}[/green]")
            
            if result.screenshot:
                try:
                    screenshot_file = output_dir / "screenshot.png"
                    screenshot_data = base64.b64decode(result.screenshot)
                    screenshot_file.write_bytes(screenshot_data)
                    console.print(f"[green]✓ Screenshot saved to: {screenshot_file}[/green]")
                except Exception as e:
                    logger.warning(f"Failed to save screenshot: {e}")
                    
    except Exception as e:
        console.print(f"[red]✗ Error saving results: {e}[/red]")


def display_results(result: CrawlResult, config: CrawlConfig) -> None:
    """Display crawl results in a rich, formatted manner."""
    
    # Create status panel
    status_color = "green" if result.success else "red"
    status_text = "✓ Success" if result.success else "✗ Failed"
    
    status_panel = Panel(
        f"[{status_color}]{status_text}[/{status_color}]\n"
        f"URL: {result.url}\n"
        f"Status Code: {result.status_code or 'N/A'}\n"
        f"Timestamp: {result.timestamp.strftime('%Y-%m-%d %H:%M:%S')}",
        title="Crawl Status",
        border_style=status_color
    )
    console.print(status_panel)
    
    if not result.success:
        if result.error:
            console.print(f"[red]Error: {result.error}[/red]")
        return
    
    # Create results table
    table = Table(title="Crawl Results Summary", show_header=True)
    table.add_column("Metric", style="cyan")
    table.add_column("Value", style="white")
    
    if result.html:
        table.add_row("HTML Length", f"{len(result.html):,} characters")
    if result.markdown:
        table.add_row("Markdown Length", f"{len(result.markdown):,} characters")
    if result.links:
        table.add_row("Links Found", str(len(result.links)))
    if result.media:
        table.add_row("Media Items", str(len(result.media.get('images', []))))
    if result.screenshot:
        table.add_row("Screenshot", "✓ Captured")
    
    console.print(table)
    
    # Display markdown preview if available and not too long
    if result.markdown and len(result.markdown) < 2000:
        console.print("\n" + "="*50)
        console.print("[bold cyan]Markdown Preview:[/bold cyan]")
        console.print("="*50)
        md = Markdown(result.markdown[:1500] + ("..." if len(result.markdown) > 1500 else ""))
        console.print(md)
    elif result.markdown:
        console.print(f"\n[dim]Markdown content available ({len(result.markdown):,} chars) - saved to file[/dim]")
    
    # Show debug info if requested
    if config.include_debug and result.metadata:
        console.print(f"\n[dim]Metadata: {json.dumps(result.metadata, indent=2, default=str)[:500]}...[/dim]")


async def perform_crawl(config: CrawlConfig) -> CrawlResult:
    """Perform the actual web crawling operation."""
    try:
        # Dynamic import to handle missing dependencies gracefully
        from crawl4ai import AsyncWebCrawler
        
        # Configure crawler parameters based on version
        crawler_kwargs = {
            'browser_type': config.browser_type,
            'headless': config.headless,
            'verbose': config.include_debug
        }
        
        # Configure crawl parameters
        crawl_kwargs = {
            'screenshot': config.screenshot,
            'wait_for_images': config.wait_for_images,
        }
        
        if hasattr(AsyncWebCrawler, 'extract_links'):
            crawler_kwargs['extract_links'] = config.extract_links
        
        # Add version-specific parameters
        if config.screenshot and config.screenshot_wait_for > 0:
            crawl_kwargs['screenshot_wait_for'] = config.screenshot_wait_for
        
        async with AsyncWebCrawler(**crawler_kwargs) as crawler:
            # Perform the crawl
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
                transient=True
            ) as progress:
                task = progress.add_task(f"Crawling {config.url}...", total=None)
                
                result = await crawler.arun(config.url, **crawl_kwargs)
                
                progress.update(task, description=f"✓ Crawled {config.url}")
            
            # Convert to our result model
            crawl_result = CrawlResult(
                success=getattr(result, 'success', True),
                url=getattr(result, 'url', config.url),
                status_code=getattr(result, 'status_code', None),
                html=getattr(result, 'html', None),
                markdown=getattr(result, 'markdown', None),
                cleaned_html=getattr(result, 'cleaned_html', None),
                links=getattr(result, 'links', None),
                media=getattr(result, 'media', None),
                metadata=getattr(result, 'metadata', None),
                screenshot=getattr(result, 'screenshot', None),
            )
            
            return crawl_result
            
    except ImportError as e:
        return CrawlResult(
            success=False,
            url=config.url,
            error=f"Crawl4AI import error: {e}. Please install crawl4ai: pip install crawl4ai"
        )
    except Exception as e:
        return CrawlResult(
            success=False,
            url=config.url,
            error=str(e)
        )


@app.command()
def crawl(
    url: str = typer.Argument(..., help="🔗 URL to crawl"),
    
    # Output options
    write_files: bool = typer.Option(
        False, "--write", "-w", 
        help="💾 Write results to individual files (markdown, html, etc.)"
    ),
    output_dir: Optional[Path] = typer.Option(
        None, "--output-dir", "-o", 
        help="📁 Base output directory for results"
    ),
    
    # Browser options  
    browser: str = typer.Option(
        "chromium", "--browser", "-b",
        help="🌐 Browser type (chromium, firefox, webkit)"
    ),
    headless: bool = typer.Option(
        True, "--headless/--no-headless",
        help="👁️ Run browser in headless mode"
    ),
    
    # Capture options
    screenshot: bool = typer.Option(
        False, "--screenshot/--no-screenshot",
        help="📸 Capture page screenshot"
    ),
    screenshot_wait_for: float = typer.Option(
        2.0, "--screenshot-wait-for",
        help="⏱️ Wait time before taking screenshot (seconds)"
    ),
    wait_for_images: bool = typer.Option(
        False, "--wait-for-images",
        help="🖼️ Wait for images to load before processing"
    ),
    
    # Content options
    links: bool = typer.Option(
        False, "--links",
        help="🔗 Extract and include page links"
    ),
    magic: bool = typer.Option(
        False, "--magic",
        help="✨ Enable magic mode for enhanced content extraction"
    ),
    
    # Debug options
    debug: bool = typer.Option(
        False, "--debug",
        help="🔍 Include debug information and verbose logging"
    ),
):
    """
    🕷️ **Modern Web Scraping Tool** 
    
    Crawl web pages using the latest Crawl4AI technology with enhanced error handling,
    beautiful output formatting, and comprehensive result saving.
    
    **Examples:**
    
    • Basic crawl: `scrapecrawl https://example.com`
    
    • With screenshot: `scrapecrawl https://example.com --screenshot --write`
    
    • Full extraction: `scrapecrawl https://example.com --links --magic --write --debug`
    """
    
    # Configure logging level
    if debug:
        logging.getLogger().setLevel(logging.DEBUG)
        logger.debug("Debug mode enabled")
    
    # Create configuration
    config = CrawlConfig(
        url=url,
        browser_type=browser,
        headless=headless,
        screenshot=screenshot,
        screenshot_wait_for=screenshot_wait_for,
        wait_for_images=wait_for_images,
        extract_links=links,
        magic_mode=magic,
        output_dir=output_dir,
        write_files=write_files,
        include_debug=debug,
    )
    
    console.print(Panel(f"🚀 Starting crawl of [bold blue]{url}[/bold blue]", 
                       title="Crawl4AI Modern Scraper"))
    
    async def main():
        # Ensure Playwright is set up
        if not await ensure_playwright_setup():
            console.print("[red]✗ Cannot proceed without Playwright setup[/red]")
            raise typer.Exit(1)
        
        # Create output directory
        output_dir = create_output_directory(config)
        console.print(f"📁 Output directory: [blue]{output_dir}[/blue]")
        
        # Perform crawl
        result = await perform_crawl(config)
        
        # Display results
        display_results(result, config)
        
        # Save results
        save_results(result, output_dir, config)
        
        if result.success:
            console.print(f"\n🎉 [green]Crawl completed successfully![/green]")
        else:
            console.print(f"\n💥 [red]Crawl failed. Check the error messages above.[/red]")
            raise typer.Exit(1)
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        console.print("\n⏹️ [yellow]Crawl interrupted by user[/yellow]")
        raise typer.Exit(1)
    except Exception as e:
        console.print(f"\n💥 [red]Unexpected error: {e}[/red]")
        if debug:
            console.print_exception()
        raise typer.Exit(1)


@app.command()
def version():
    """📋 Show version information for all dependencies."""
    
    versions_table = Table(title="📦 Dependency Versions", show_header=True)
    versions_table.add_column("Package", style="cyan")
    versions_table.add_column("Version", style="white")
    versions_table.add_column("Status", style="green")
    
    packages = [
        ("typer", "typer"),
        ("rich", "rich"),
        ("crawl4ai", "crawl4ai"),
        ("playwright", "playwright"),
        ("aiohttp", "aiohttp"),
        ("pydantic", "pydantic")
    ]
    
    for display_name, import_name in packages:
        try:
            module = __import__(import_name)
            # Special handling for different version attributes
            if hasattr(module, '__version__'):
                version = module.__version__
            elif hasattr(module, 'VERSION'):
                version = module.VERSION
            elif import_name == 'rich':
                # Rich stores version differently
                try:
                    from rich import __version__ as rich_version
                    version = rich_version
                except:
                    version = 'unknown'
            else:
                version = 'unknown'
            status = "✓ Installed"
        except ImportError:
            version = "Not installed"
            status = "✗ Missing"
        
        versions_table.add_row(display_name, version, status)
    
    console.print(versions_table)


if __name__ == "__main__":
    app()