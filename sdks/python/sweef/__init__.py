# Sweef Browser - Python SDK
# Ultra-lightweight browser for AI agents and humans

"""
Sweef Browser - Python SDK
==========================

Ultra-lightweight browser for AI agents and humans.

Features:
- Headless and GUI modes
- Full Playwright-like API
- MCP (Model Context Protocol) support for AI agents
- Memory-efficient (50MB RAM target)
- Cross-platform (Linux, Windows, macOS, ARM)

Example:
    from sweef import Browser

    async def main():
        browser = await Browser.launch(headless=True)
        page = await browser.new_page()
        
        await page.goto("https://example.com")
        title = await page.title()
        print(f"Title: {title}")
        
        await browser.close()

    # Run with: python -m asyncio main.py
"""

from .browser import Browser
from .browser_context import BrowserContext
from .page import Page
from .element_handle import ElementHandle
from .js_handle import JSHandle
from .request import Request
from .response import Response

__all__ = [
    "Browser",
    "BrowserContext",
    "Page",
    "ElementHandle",
    "JSHandle",
    "Request",
    "Response",
]

__version__ = "0.1.0"
