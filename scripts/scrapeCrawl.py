#!/usr/bin/env python3

# /// script
# dependencies = [
#   "typer>=0.15.1",
#   "rich>=13.9.4",
#   "crawl4ai==0.4.248"
# ]
# ///

import asyncio
import typer
import base64
import json
import os
import sys
import subprocess
import logging
import csv
from pathlib import Path
from rich import print
from rich.console import Console
from rich.markdown import Markdown
from typing import Optional, Dict, Any, Tuple
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig
from datetime import datetime

app = typer.Typer()
console = Console()

# Set up logging (optional)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("crawl4ai")

def ensure_playwright_browsers() -> bool:
    """Check and install Playwright browsers if needed."""
    try:
        from playwright.sync_api import sync_playwright
        
        try:
            with sync_playwright() as p:
                browser = p.chromium.launch()
                browser.close()
                return True
        except Exception:
            console.print("[yellow]Installing Playwright browsers...[/yellow]")
            result = subprocess.run([sys.executable, '-m', 'playwright', 'install'], 
                                 capture_output=True, 
                                 text=True)
            if result.returncode != 0:
                console.print(f"[red]Failed to install browsers: {result.stderr}[/red]")
                return False
            return True
    except ImportError:
        console.print("[red]Playwright not found in environment[/red]")
        return False

def write_to_file(content: bytes, file_path: Path) -> None:
    """Write binary content to a file."""
    file_path.write_bytes(content)
    logger.info("Written file: %s", file_path)

def write_text_to_file(text: str, file_path: Path) -> None:
    """Write text content to a file."""
    file_path.write_text(text)
    logger.info("Written text file: %s", file_path)

class CustomJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder to handle non-serializable objects."""
    def default(self, obj):
        # Convert any object to a dict of its public attributes
        try:
            return {k: v for k, v in obj.__dict__.items() if not k.startswith('_')}
        except AttributeError:
            try:
                return str(obj)
            except Exception:
                return None

def truncate_large_strings(obj, max_length=1000):
    """Recursively truncate large strings in nested structures."""
    if isinstance(obj, str):
        return obj if len(obj) <= max_length else obj[:max_length] + "... (truncated)"
    elif isinstance(obj, dict):
        return {k: truncate_large_strings(v, max_length) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [truncate_large_strings(x, max_length) for x in obj]
    return obj

def process_results(result: Dict[str, Any], task_id: str, url: str, output_dir: Path, options: Dict[str, Any]) -> None:
    """Process and output the crawl result with enhanced error handling."""
    # Print raw result keys
    print("\n[yellow]Raw Result Keys:[/yellow]")
    print(json.dumps(list(result.keys()), indent=2))

    # Print structure instead of full raw result
    print("\n[yellow]Result Structure:[/yellow]")
    def print_structure(d, level=0):
        for k, v in d.items():
            indent = "  " * level
            if hasattr(v, '__dict__'):
                print(f"{indent}{k}: {v.__class__.__name__} object")
                if level < 2:  # Limit nesting depth
                    print_structure(v.__dict__, level + 1)
            elif isinstance(v, dict):
                print(f"{indent}{k}: dict with {len(v)} keys")
                if level < 2:  # Limit nesting depth
                    print_structure(v, level + 1)
            elif isinstance(v, list):
                print(f"{indent}{k}: list with {len(v)} items")
            elif isinstance(v, str):
                preview = v[:50] + "..." if len(v) > 50 else v
                print(f"{indent}{k}: string ({len(v)} chars) - {preview}")
            else:
                print(f"{indent}{k}: {type(v).__name__}")
    
    print_structure(result)
    print("\n")

    # Only print full raw result if explicitly requested
    if options.get("debug"):
        print("\n[yellow]Full Raw Result (truncated):[/yellow]")
        try:
            # Truncate large strings and limit the output
            truncated_result = truncate_large_strings(result)
            print(json.dumps(truncated_result, indent=2, cls=CustomJSONEncoder))
        except Exception as e:
            print(f"[red]Error serializing full result: {e}[/red]")
            print({k: f"{type(v).__name__} ({len(str(v))} chars)" if isinstance(v, (str, bytes)) 
                   else type(v).__name__ for k, v in result.items()})

    # Extract markdown with debug logging
    
    markdown_data = result.get("markdown", "")
    if hasattr(markdown_data, 'text'):  # Handle MarkdownGenerationResult object
        markdown_data = markdown_data.text
    logger.debug("Markdown data type: %s", type(markdown_data))
    logger.debug("Markdown content: %s", markdown_data)
    
    markdown = markdown_data if isinstance(markdown_data, str) else json.dumps(markdown_data, indent=2)
    
    print("[green]Markdown Result:[/green]")
    try:
        print(Markdown(markdown))
        print("\n[blue]Rendered Markdown:[/blue]")
    except Exception as e:
        logger.error("Error rendering markdown: %s", e)
        print("[red]Error rendering markdown, falling back to plain text:[/red]")
        print(markdown)

    if options.get("links"):
        internal_links = result.get("links", {}).get("internal", [])
        external_links = result.get("links", {}).get("external", [])
        if internal_links or external_links:
            print("\n[blue]Found Links:[/blue]")
            print(f"[cyan]Internal Links: {len(internal_links)}[/cyan]")
            for link in internal_links:
                if isinstance(link, dict):
                    print(f"  • {link.get('href', 'N/A')} - {link.get('text', 'No text')}")
                else:
                    print(f"  • {link}")
                    
            print(f"\n[yellow]External Links: {len(external_links)}[/yellow]")
            for link in external_links:
                if isinstance(link, dict):
                    print(f"  • {link.get('href', 'N/A')} - {link.get('text', 'No text')}")
                else:
                    print(f"  • {link}")
            
            # Save links as CSV
            csv_file = output_dir / f"links_{task_id}.csv"
            with open(csv_file, 'w', newline='', encoding='utf-8') as f:
                writer = csv.writer(f)
                # Write header
                writer.writerow(['type', 'url', 'text', 'domain'])
                
                # Write internal links
                for link in internal_links:
                    if isinstance(link, dict):
                        writer.writerow(['internal', 
                                      link.get('href', 'N/A'),
                                      link.get('text', 'No text'),
                                      link.get('base_domain', '')])
                    else:
                        writer.writerow(['internal', link, '', ''])
                
                # Write external links
                for link in external_links:
                    if isinstance(link, dict):
                        writer.writerow(['external',
                                      link.get('href', 'N/A'),
                                      link.get('text', 'No text'),
                                      link.get('base_domain', '')])
                    else:
                        writer.writerow(['external', link, '', ''])
            
            print(f"[green]Links saved to: {csv_file}[/green]")

    # Fix screenshot handling
    if options.get("screenshot") and "screenshot" in result:  # Changed from result.get("result", {})
        screenshot_file = output_dir / f"screenshot_{task_id}.png"
        try:
            screenshot_data = base64.b64decode(result["screenshot"])  # Direct access to screenshot
            write_to_file(screenshot_data, screenshot_file)
            print(f"[green]Screenshot saved to: {screenshot_file}[/green]")
        except Exception as e:
            print(f"[red]Error saving screenshot: {e}[/red]")
            logger.exception("Screenshot save failed")

    if options.get("write_file") and markdown:
        markdown_file = output_dir / f"crawl_results_{task_id}.md"
        write_text_to_file(markdown, markdown_file)
        print(f"[green]Markdown saved to: {markdown_file}[/green]")

    # Fix alldata output
    if options.get("alldata"):
        json_file = output_dir / f"full_results_{task_id}.json"
        try:
            # Create a clean copy of the result without any circular references
            clean_result = {
                "url": result.get("url"),
                "html": truncate_large_strings(result.get("html"), 10000),
                "success": result.get("success"),
                "cleaned_html": truncate_large_strings(result.get("cleaned_html"), 10000),
                "media": result.get("media"),
                "links": result.get("links"),
                "downloaded_files": result.get("downloaded_files"),
                "screenshot": "<base64_data>" if result.get("screenshot") else None,
                "pdf": result.get("pdf"),
                "markdown": result.get("markdown"),
                "markdown_v2": result.get("markdown_v2"),
                "metadata": result.get("metadata"),
                "response_headers": result.get("response_headers"),
                "status_code": result.get("status_code"),
                "redirected_url": result.get("redirected_url")
            }
            write_text_to_file(json.dumps(clean_result, indent=2, cls=CustomJSONEncoder), json_file)
            print(f"[green]Full results saved to: {json_file}[/green]")
        except Exception as e:
            print(f"[red]Error saving full results: {e}[/red]")
            logger.exception("Full results save failed")

    print("[green]Crawl successful![/green]")

def create_output_dir(base_dir: Path, url: str) -> Path:
    """Create a timestamped output directory for the crawl."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Extract just the domain name from the URL
    clean_url = url.split("//")[-1].split("/")[0]
    # Remove www. if present
    clean_url = clean_url.replace("www.", "")
    # Get the main domain part
    domain = clean_url.split(".")[0]
    
    # Create final directory name with timestamp and short domain
    output_dir = base_dir / f"crawl_{domain}_{timestamp}"
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir

@app.command()
def crawl(
    url: str = typer.Argument(..., help="URL to crawl"),
    write_file: bool = typer.Option(False, "--write", "-w", help="Write markdown results to a file"),
    screenshot: bool = typer.Option(False, "--screenshot/--no-screenshot", help="Enable screenshot capture"),
    screenshot_wait_for: float = typer.Option(2.0, "--screenshot-wait-for", help="Wait time for screenshot"),
    output_dir: Optional[Path] = typer.Option(None, "--output-dir", "-o", help="Base output directory for files"),
    browser: str = typer.Option("chromium", "--browser", "-b", help="Browser type: chromium, firefox, or webkit"),
    wait_for_images: bool = typer.Option(False, "--wait-for-images", help="Wait for images to fully load"),
    links: bool = typer.Option(False, "--links", help="Extract links from the page"),
    alldata: bool = typer.Option(False, "--alldata", help="Output full JSON result"),
    headless: bool = typer.Option(True, "--headless/--no-headless", help="Run browser in headless mode"),
    debug: bool = typer.Option(False, "--debug", help="Print full raw result (truncated)")
):
    """
    Crawl the given URL using the Crawl4AI Python API.
    """
    if not ensure_playwright_browsers():
        raise typer.Exit(1)
        
    # Create base output directory if not specified
    base_dir = output_dir or Path.cwd() / "crawl_outputs"
    base_dir.mkdir(parents=True, exist_ok=True)
    
    # Create timestamped directory for this crawl
    crawl_dir = create_output_dir(base_dir, url)
    console.print(f"[cyan]Output directory: {crawl_dir}[/cyan]")

    async def run_crawl() -> Tuple[Dict[str, Any], str]:
        browser_config = BrowserConfig(
            browser_type=browser,
            headless=headless
        )
        run_config = CrawlerRunConfig(
            screenshot=screenshot,
            screenshot_wait_for=screenshot_wait_for,
            wait_for_images=wait_for_images,
            verbose=True
        )
        async with AsyncWebCrawler(config=browser_config,extract_links=links) as crawler:
            result = await crawler.arun(url, config=run_config)
            # Convert CrawlResult to dict more safely
            result_dict = {
                k: v.__dict__ if hasattr(v, '__dict__') else v 
                for k, v in result.__dict__.items()
            }
            # Ensure links are properly captured
            if hasattr(result, 'links'):
                result_dict['links'] = result.links
            return result_dict, "local"

    options = {
        "write_file": write_file,
        "screenshot": screenshot,
        "alldata": alldata,
        "links": links,
        "debug": debug,
    }

    try:
        console.print(f"[cyan]Crawling URL: {url}[/cyan]")
        result, task_id = asyncio.run(run_crawl())
        process_results(result, task_id, url, crawl_dir, options)
    except Exception as e:
        console.print(f"[red]Error during crawl: {e}[/red]")
        logger.exception("Crawl failed")
        raise typer.Exit(1)

if __name__ == "__main__":
    app()