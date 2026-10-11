# Sweef Browser - Python SDK Request Class
# Ultra-lightweight browser for AI agents and humans

from typing import Optional, Dict, Any


class Request:
    """
    Represents an HTTP request.
    
    Example:
        page = await browser.new_page()
        page.on("request", lambda req: print(req.url))
        await page.goto("https://example.com")
    """
    
    def __init__(self, data: Dict[str, Any]):
        self._data = data
    
    @property
    def url(self) -> str:
        """Get the request URL."""
        return self._data.get("url", "")
    
    @property
    def method(self) -> str:
        """Get the HTTP method."""
        return self._data.get("method", "GET")
    
    @property
    def headers(self) -> Dict[str, str]:
        """Get the request headers."""
        return self._data.get("headers", {})
    
    @property
    def post_data(self) -> Optional[bytes]:
        """Get the POST data."""
        import base64
        data = self._data.get("postData")
        if data:
            return base64.b64decode(data)
        return None
    
    def __repr__(self) -> str:
        return f"Request(url={self.url!r}, method={self.method!r})"
