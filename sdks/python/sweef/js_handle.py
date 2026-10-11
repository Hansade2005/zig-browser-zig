# Sweef Browser - Python SDK JSHandle Class
# Ultra-lightweight browser for AI agents and humans

from typing import Optional, Dict, List, Any, Callable, Union
import asyncio

from .page import Page


class JSHandle:
    """
    A handle to a JavaScript object that allows interaction.
    
    Example:
        page = await browser.new_page()
        await page.goto("https://example.com")
        result = await page.evaluate("() => window")
        handle = await page.evaluate_handle("() => window")
        properties = await handle.get_properties()
    """
    
    def __init__(self, page: Page, handle: Dict[str, Any]):
        self._page = page
        self._handle = handle
    
    @property
    def page(self) -> Page:
        """Get the page instance."""
        return self._page
    
    @property
    def handle(self) -> Dict[str, Any]:
        """Get the handle data."""
        return self._handle
    
    async def evaluate(self, js: str, arg: Optional[Any] = None) -> Any:
        """
        Execute JavaScript with this handle as `this`.
        
        Args:
            js: JavaScript code to execute
            arg: Argument to pass to the JavaScript function
        
        Returns:
            Result of the JavaScript execution
        """
        result = await self._page._browser._send_message({
            "method": "JSHandle.evaluate",
            "params": {
                "pageId": self._page.id,
                "handleId": self._handle.get("id"),
                "js": js,
                "arg": arg
            }
        })
        return result.get("value")
    
    async def get_properties(self) -> Dict[str, Any]:
        """
        Get all properties of the JavaScript object.
        
        Returns:
            Dict of properties
        """
        result = await self._page._browser._send_message({
            "method": "JSHandle.getProperties",
            "params": {
                "pageId": self._page.id,
                "handleId": self._handle.get("id")
            }
        })
        return result.get("properties", {})
    
    async def get_property(self, property: str) -> Any:
        """
        Get a specific property of the JavaScript object.
        
        Args:
            property: Property name
        
        Returns:
            Property value
        """
        result = await self._page._browser._send_message({
            "method": "JSHandle.getProperty",
            "params": {
                "pageId": self._page.id,
                "handleId": self._handle.get("id"),
                "property": property
            }
        })
        return result.get("value")
    
    async def dispose(self):
        """Dispose the JS handle."""
        await self._page._browser._send_message({
            "method": "JSHandle.dispose",
            "params": {
                "pageId": self._page.id,
                "handleId": self._handle.get("id")
            }
        })
