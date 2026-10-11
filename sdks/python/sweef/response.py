# Sweef Browser - Python SDK Response Class
# Ultra-lightweight browser for AI agents and humans

from typing import Optional, Dict, Any


class Response:
    """
    Represents an HTTP response.
    
    Example:
        page = await browser.new_page()
        page.on("response", lambda res: print(res.status, res.url))
        await page.goto("https://example.com")
    """
    
    def __init__(self, data: Dict[str, Any]):
        self._data = data
    
    @property
    def url(self) -> str:
        """Get the response URL."""
        return self._data.get("url", "")
    
    @property
    def status(self) -> int:
        """Get the HTTP status code."""
        return self._data.get("status", 0)
    
    @property
    def status_text(self) -> str:
        """Get the HTTP status text."""
        return self._data.get("statusText", "")
    
    @property
    def headers(self) -> Dict[str, str]:
        """Get the response headers."""
        return self._data.get("headers", {})
    
    def __repr__(self) -> str:
        return f"Response(url={self.url!r}, status={self.status})"
