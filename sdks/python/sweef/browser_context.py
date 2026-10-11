# Sweef Browser - Python SDK BrowserContext Class
# Ultra-lightweight browser for AI agents and humans

from typing import Optional, Dict, List, Any, Callable, Union
import asyncio

from .browser import Browser
from .page import Page


class BrowserContext:
    """
    A browser context that isolates pages from each other.
    
    Example:
        browser = await Browser.launch()
        context = await browser.new_context()
        page = await context.new_page()
        await page.goto("https://example.com")
    """
    
    def __init__(self, browser: Browser, context_id: int, **kwargs):
        self._browser = browser
        self._id = context_id
        self._options = kwargs
        self._pages: Dict[int, Page] = {}
        self._next_page_id: int = 1
        self._event_handlers: Dict[str, List[Callable]] = {}
    
    @property
    def id(self) -> int:
        """Get the context ID."""
        return self._id
    
    @property
    def browser(self) -> Browser:
        """Get the browser instance."""
        return self._browser
    
    @property
    def options(self) -> Dict[str, Any]:
        """Get the context options."""
        return self._options
    
    async def new_page(self) -> Page:
        """
        Create a new page in this context.
        
        Returns:
            Page: A new page instance
        """
        page_id = self._next_page_id
        self._next_page_id += 1
        page = Page(self._browser, self, page_id)
        self._pages[page_id] = page
        self._browser._pages[page_id] = page
        return page
    
    async def pages(self) -> List[Page]:
        """
        Get all pages in this context.
        
        Returns:
            List of Page instances
        """
        return list(self._pages.values())
    
    async def close(self):
        """Close this context and all its pages."""
        for page in list(self._pages.values()):
            await page.close()
        self._pages.clear()
        if self._id in self._browser._contexts:
            del self._browser._contexts[self._id]
    
    async def add_cookies(self, cookies: List[Dict[str, Any]]):
        """
        Add cookies to this context.
        
        Args:
            cookies: List of cookies to add, each with 'name', 'value', and optional 'url'
        """
        await self._browser._send_message({
            "method": "BrowserContext.addCookies",
            "params": {"cookies": cookies}
        })
    
    async def cookies(self, urls: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """
        Get cookies from this context.
        
        Args:
            urls: Optional list of URLs to get cookies for
        
        Returns:
            List of cookies, each with 'name', 'value', and 'url'
        """
        result = await self._browser._send_message({
            "method": "BrowserContext.cookies",
            "params": {"urls": urls or []}
        })
        return result.get("cookies", [])
    
    async def clear_cookies(self):
        """Clear all cookies in this context."""
        await self._browser._send_message({
            "method": "BrowserContext.clearCookies"
        })
    
    async def set_offline(self, offline: bool):
        """
        Set offline mode for this context.
        
        Args:
            offline: Whether to enable offline mode
        """
        await self._browser._send_message({
            "method": "BrowserContext.setOffline",
            "params": {"offline": offline}
        })
    
    async def set_geolocation(self, geolocation: Dict[str, float]):
        """
        Set geolocation for this context.
        
        Args:
            geolocation: Dict with 'latitude' and 'longitude' keys
        """
        await self._browser._send_message({
            "method": "BrowserContext.setGeolocation",
            "params": {"geolocation": geolocation}
        })
    
    async def set_user_agent(self, user_agent: str):
        """
        Set user agent for this context.
        
        Args:
            user_agent: User agent string
        """
        await self._browser._send_message({
            "method": "BrowserContext.setUserAgent",
            "params": {"userAgent": user_agent}
        })
    
    async def set_viewport(self, viewport: Dict[str, int]):
        """
        Set viewport dimensions for this context.
        
        Args:
            viewport: Dict with 'width' and 'height' keys
        """
        await self._browser._send_message({
            "method": "BrowserContext.setViewport",
            "params": {"viewport": viewport}
        })
    
    def on(self, event: str, handler: Callable):
        """
        Register an event handler.
        
        Args:
            event: Event name
            handler: Event handler function
        """
        if event not in self._event_handlers:
            self._event_handlers[event] = []
        self._event_handlers[event].append(handler)
