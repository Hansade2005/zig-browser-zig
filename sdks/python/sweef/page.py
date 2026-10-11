# Sweef Browser - Python SDK Page Class
# Ultra-lightweight browser for AI agents and humans

from typing import Optional, Dict, List, Any, Callable, Union, Tuple
import asyncio

from .browser import Browser
from .browser_context import BrowserContext
from .element_handle import ElementHandle
from .js_handle import JSHandle
from .request import Request
from .response import Response


class Page:
    """
    A page in the browser that can load URLs and interact with content.
    
    Example:
        browser = await Browser.launch()
        page = await browser.new_page()
        await page.goto("https://example.com")
        title = await page.title()
        print(f"Title: {title}")
    """
    
    def __init__(self, browser: Browser, context: BrowserContext, page_id: int):
        self._browser = browser
        self._context = context
        self._id = page_id
        self._closed = False
        self._event_handlers: Dict[str, List[Callable]] = {}
    
    @property
    def id(self) -> int:
        """Get the page ID."""
        return self._id
    
    @property
    def browser(self) -> Browser:
        """Get the browser instance."""
        return self._browser
    
    @property
    def context(self) -> BrowserContext:
        """Get the browser context."""
        return self._context
    
    @property
    def closed(self) -> bool:
        """Check if the page is closed."""
        return self._closed
    
    async def goto(
        self,
        url: str,
        wait_until: Optional[str] = "load",
        timeout: Optional[int] = None
    ):
        """
        Navigate to a URL.
        
        Args:
            url: The URL to navigate to
            wait_until: Wait until this event ('load', 'domcontentloaded', 'networkidle')
            timeout: Timeout in milliseconds
        """
        await self._browser._send_message({
            "method": "Page.goto",
            "params": {
                "pageId": self._id,
                "url": url,
                "waitUntil": wait_until,
                "timeout": timeout
            }
        })
    
    async def reload(
        self,
        wait_until: Optional[str] = "load",
        timeout: Optional[int] = None
    ):
        """
        Reload the page.
        
        Args:
            wait_until: Wait until this event ('load', 'domcontentloaded', 'networkidle')
            timeout: Timeout in milliseconds
        """
        await self._browser._send_message({
            "method": "Page.reload",
            "params": {
                "pageId": self._id,
                "waitUntil": wait_until,
                "timeout": timeout
            }
        })
    
    async def go_back(
        self,
        wait_until: Optional[str] = "load",
        timeout: Optional[int] = None
    ):
        """
        Navigate back in history.
        
        Args:
            wait_until: Wait until this event ('load', 'domcontentloaded', 'networkidle')
            timeout: Timeout in milliseconds
        """
        await self._browser._send_message({
            "method": "Page.goBack",
            "params": {
                "pageId": self._id,
                "waitUntil": wait_until,
                "timeout": timeout
            }
        })
    
    async def go_forward(
        self,
        wait_until: Optional[str] = "load",
        timeout: Optional[int] = None
    ):
        """
        Navigate forward in history.
        
        Args:
            wait_until: Wait until this event ('load', 'domcontentloaded', 'networkidle')
            timeout: Timeout in milliseconds
        """
        await self._browser._send_message({
            "method": "Page.goForward",
            "params": {
                "pageId": self._id,
                "waitUntil": wait_until,
                "timeout": timeout
            }
        })
    
    async def close(self):
        """Close the page."""
        if self._closed:
            return
        
        await self._browser._send_message({
            "method": "Page.close",
            "params": {"pageId": self._id}
        })
        
        self._closed = True
        if self._id in self._context._pages:
            del self._context._pages[self._id]
        if self._id in self._browser._pages:
            del self._browser._pages[self._id]
    
    async def title(self) -> str:
        """
        Get the page title.
        
        Returns:
            Page title
        """
        result = await self._browser._send_message({
            "method": "Page.title",
            "params": {"pageId": self._id}
        })
        return result.get("title", "")
    
    async def url(self) -> str:
        """
        Get the current URL.
        
        Returns:
            Current URL
        """
        result = await self._browser._send_message({
            "method": "Page.url",
            "params": {"pageId": self._id}
        })
        return result.get("url", "")
    
    async def content(self) -> str:
        """
        Get the page HTML content.
        
        Returns:
            HTML content
        """
        result = await self._browser._send_message({
            "method": "Page.content",
            "params": {"pageId": self._id}
        })
        return result.get("content", "")
    
    async def set_content(self, html: str):
        """
        Set the page HTML content.
        
        Args:
            html: HTML content to set
        """
        await self._browser._send_message({
            "method": "Page.setContent",
            "params": {"pageId": self._id, "html": html}
        })
    
    async def click(
        self,
        selector: str,
        button: Optional[str] = "left",
        click_count: Optional[int] = 1
    ):
        """
        Click an element.
        
        Args:
            selector: CSS selector
            button: Mouse button ('left', 'right', 'middle')
            click_count: Number of clicks
        """
        await self._browser._send_message({
            "method": "Page.click",
            "params": {
                "pageId": self._id,
                "selector": selector,
                "button": button,
                "clickCount": click_count
            }
        })
    
    async def dblclick(self, selector: str):
        """
        Double click an element.
        
        Args:
            selector: CSS selector
        """
        await self._browser._send_message({
            "method": "Page.dblclick",
            "params": {"pageId": self._id, "selector": selector}
        })
    
    async def hover(self, selector: str):
        """
        Hover over an element.
        
        Args:
            selector: CSS selector
        """
        await self._browser._send_message({
            "method": "Page.hover",
            "params": {"pageId": self._id, "selector": selector}
        })
    
    async def focus(self, selector: str):
        """
        Focus on an element.
        
        Args:
            selector: CSS selector
        """
        await self._browser._send_message({
            "method": "Page.focus",
            "params": {"pageId": self._id, "selector": selector}
        })
    
    async def type(self, selector: str, text: str, delay: Optional[int] = None):
        """
        Type text into an element.
        
        Args:
            selector: CSS selector
            text: Text to type
            delay: Delay between keystrokes in milliseconds
        """
        await self._browser._send_message({
            "method": "Page.type",
            "params": {
                "pageId": self._id,
                "selector": selector,
                "text": text,
                "delay": delay
            }
        })
    
    async def fill(self, selector: str, value: str):
        """
        Fill an input element.
        
        Args:
            selector: CSS selector
            value: Value to fill
        """
        await self._browser._send_message({
            "method": "Page.fill",
            "params": {"pageId": self._id, "selector": selector, "value": value}
        })
    
    async def select(self, selector: str, value: Union[str, List[str]]):
        """
        Select option(s) in a dropdown.
        
        Args:
            selector: CSS selector
            value: Value(s) to select
        """
        await self._browser._send_message({
            "method": "Page.select",
            "params": {"pageId": self._id, "selector": selector, "value": value}
        })
    
    async def check(self, selector: str):
        """
        Check a checkbox.
        
        Args:
            selector: CSS selector
        """
        await self._browser._send_message({
            "method": "Page.check",
            "params": {"pageId": self._id, "selector": selector}
        })
    
    async def uncheck(self, selector: str):
        """
        Uncheck a checkbox.
        
        Args:
            selector: CSS selector
        """
        await self._browser._send_message({
            "method": "Page.uncheck",
            "params": {"pageId": self._id, "selector": selector}
        })
    
    async def press(self, key: str):
        """
        Press a key.
        
        Args:
            key: Key to press (e.g., 'Enter', 'Tab', 'Escape')
        """
        await self._browser._send_message({
            "method": "Page.press",
            "params": {"pageId": self._id, "key": key}
        })
    
    async def set_input_files(self, selector: str, files: Union[str, List[str]]):
        """
        Set files for file input.
        
        Args:
            selector: CSS selector
            files: File path(s)
        """
        await self._browser._send_message({
            "method": "Page.setInputFiles",
            "params": {"pageId": self._id, "selector": selector, "files": files}
        })
    
    async def wait_for_selector(
        self,
        selector: str,
        state: Optional[str] = "visible",
        timeout: Optional[int] = None
    ) -> Optional[ElementHandle]:
        """
        Wait for an element to appear.
        
        Args:
            selector: CSS selector
            state: State to wait for ('visible', 'hidden', 'attached', 'detached')
            timeout: Timeout in milliseconds
        
        Returns:
            ElementHandle or None if not found
        """
        result = await self._browser._send_message({
            "method": "Page.waitForSelector",
            "params": {
                "pageId": self._id,
                "selector": selector,
                "state": state,
                "timeout": timeout
            }
        })
        
        if result.get("success"):
            return ElementHandle(self, result.get("element"))
        return None
    
    async def wait_for_function(
        self,
        js: str,
        polling: Optional[str] = "raf",
        timeout: Optional[int] = None
    ) -> Any:
        """
        Wait for a JavaScript condition.
        
        Args:
            js: JavaScript expression to evaluate
            polling: Polling strategy ('raf', 'mutation', or number in ms)
            timeout: Timeout in milliseconds
        
        Returns:
            The result of the JavaScript expression
        """
        result = await self._browser._send_message({
            "method": "Page.waitForFunction",
            "params": {
                "pageId": self._id,
                "js": js,
                "polling": polling,
                "timeout": timeout
            }
        })
        return result.get("value")
    
    async def wait_for_navigation(
        self,
        wait_until: Optional[str] = "load",
        timeout: Optional[int] = None
    ):
        """
        Wait for page navigation.
        
        Args:
            wait_until: Wait until this event ('load', 'domcontentloaded', 'networkidle')
            timeout: Timeout in milliseconds
        """
        await self._browser._send_message({
            "method": "Page.waitForNavigation",
            "params": {
                "pageId": self._id,
                "waitUntil": wait_until,
                "timeout": timeout
            }
        })
    
    async def wait_for_load_state(
        self,
        state: str,
        timeout: Optional[int] = None
    ):
        """
        Wait for a specific load state.
        
        Args:
            state: Load state to wait for ('load', 'domcontentloaded', 'networkidle')
            timeout: Timeout in milliseconds
        """
        await self._browser._send_message({
            "method": "Page.waitForLoadState",
            "params": {
                "pageId": self._id,
                "state": state,
                "timeout": timeout
            }
        })
    
    async def wait_for_request(
        self,
        url: str,
        timeout: Optional[int] = None
    ) -> Request:
        """
        Wait for a specific request.
        
        Args:
            url: URL to wait for
            timeout: Timeout in milliseconds
        
        Returns:
            Request object
        """
        result = await self._browser._send_message({
            "method": "Page.waitForRequest",
            "params": {"pageId": self._id, "url": url, "timeout": timeout}
        })
        return Request(result)
    
    async def wait_for_response(
        self,
        url: str,
        timeout: Optional[int] = None
    ) -> Response:
        """
        Wait for a specific response.
        
        Args:
            url: URL to wait for
            timeout: Timeout in milliseconds
        
        Returns:
            Response object
        """
        result = await self._browser._send_message({
            "method": "Page.waitForResponse",
            "params": {"pageId": self._id, "url": url, "timeout": timeout}
        })
        return Response(result)
    
    async def wait_for_timeout(self, ms: int):
        """
        Wait for a timeout.
        
        Args:
            ms: Milliseconds to wait
        """
        await self._browser._send_message({
            "method": "Page.waitForTimeout",
            "params": {"pageId": self._id, "ms": ms}
        })
    
    async def evaluate(self, js: str, arg: Optional[Any] = None) -> Any:
        """
        Execute JavaScript in the page context.
        
        Args:
            js: JavaScript code to execute
            arg: Argument to pass to the JavaScript function
        
        Returns:
            Result of the JavaScript execution
        """
        result = await self._browser._send_message({
            "method": "Page.evaluate",
            "params": {"pageId": self._id, "js": js, "arg": arg}
        })
        return result.get("result")
    
    async def evaluate_handle(self, js: str) -> JSHandle:
        """
        Execute JavaScript and return a handle to the result.
        
        Args:
            js: JavaScript code to execute
        
        Returns:
            JSHandle to the result
        """
        result = await self._browser._send_message({
            "method": "Page.evaluateHandle",
            "params": {"pageId": self._id, "js": js}
        })
        return JSHandle(self, result.get("handle"))
    
    async def query_selector(self, selector: str) -> Optional[ElementHandle]:
        """
        Query selector (single element).
        
        Args:
            selector: CSS selector
        
        Returns:
            ElementHandle or None if not found
        """
        result = await self._browser._send_message({
            "method": "Page.querySelector",
            "params": {"pageId": self._id, "selector": selector}
        })
        
        if result.get("element"):
            return ElementHandle(self, result["element"])
        return None
    
    async def query_selector_all(self, selector: str) -> List[ElementHandle]:
        """
        Query selector (all elements).
        
        Args:
            selector: CSS selector
        
        Returns:
            List of ElementHandle instances
        """
        result = await self._browser._send_message({
            "method": "Page.querySelectorAll",
            "params": {"pageId": self._id, "selector": selector}
        })
        
        elements = result.get("elements", [])
        return [ElementHandle(self, el) for el in elements]
    
    async def text_content(self, selector: str) -> str:
        """
        Get text content of an element.
        
        Args:
            selector: CSS selector
        
        Returns:
            Text content
        """
        result = await self._browser._send_message({
            "method": "Page.textContent",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("text", "")
    
    async def inner_html(self, selector: str) -> str:
        """
        Get inner HTML of an element.
        
        Args:
            selector: CSS selector
        
        Returns:
            Inner HTML
        """
        result = await self._browser._send_message({
            "method": "Page.innerHTML",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("html", "")
    
    async def inner_text(self, selector: str) -> str:
        """
        Get inner text of an element.
        
        Args:
            selector: CSS selector
        
        Returns:
            Inner text
        """
        result = await self._browser._send_message({
            "method": "Page.innerText",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("text", "")
    
    async def get_attribute(self, selector: str, attribute: str) -> Optional[str]:
        """
        Get an attribute value.
        
        Args:
            selector: CSS selector
            attribute: Attribute name
        
        Returns:
            Attribute value or None
        """
        result = await self._browser._send_message({
            "method": "Page.getAttribute",
            "params": {"pageId": self._id, "selector": selector, "attribute": attribute}
        })
        return result.get("value")
    
    async def bounding_box(self, selector: str) -> Dict[str, float]:
        """
        Get element bounding box.
        
        Args:
            selector: CSS selector
        
        Returns:
            Dict with 'x', 'y', 'width', 'height' keys
        """
        result = await self._browser._send_message({
            "method": "Page.boundingBox",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("box", {"x": 0, "y": 0, "width": 0, "height": 0})
    
    async def get_computed_style(self, selector: str) -> Dict[str, str]:
        """
        Get computed styles for an element.
        
        Args:
            selector: CSS selector
        
        Returns:
            Dict of computed styles
        """
        result = await self._browser._send_message({
            "method": "Page.getComputedStyle",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("styles", {})
    
    async def is_visible(self, selector: str) -> bool:
        """
        Check if an element is visible.
        
        Args:
            selector: CSS selector
        
        Returns:
            True if visible, False otherwise
        """
        result = await self._browser._send_message({
            "method": "Page.isVisible",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("visible", False)
    
    async def is_hidden(self, selector: str) -> bool:
        """
        Check if an element is hidden.
        
        Args:
            selector: CSS selector
        
        Returns:
            True if hidden, False otherwise
        """
        result = await self._browser._send_message({
            "method": "Page.isHidden",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("hidden", False)
    
    async def is_enabled(self, selector: str) -> bool:
        """
        Check if an element is enabled.
        
        Args:
            selector: CSS selector
        
        Returns:
            True if enabled, False otherwise
        """
        result = await self._browser._send_message({
            "method": "Page.isEnabled",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("enabled", False)
    
    async def is_checked(self, selector: str) -> bool:
        """
        Check if a checkbox is checked.
        
        Args:
            selector: CSS selector
        
        Returns:
            True if checked, False otherwise
        """
        result = await self._browser._send_message({
            "method": "Page.isChecked",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("checked", False)
    
    async def is_selected(self, selector: str) -> bool:
        """
        Check if an option is selected.
        
        Args:
            selector: CSS selector
        
        Returns:
            True if selected, False otherwise
        """
        result = await self._browser._send_message({
            "method": "Page.isSelected",
            "params": {"pageId": self._id, "selector": selector}
        })
        return result.get("selected", False)
    
    async def screenshot(
        self,
        path: Optional[str] = None,
        type: Optional[str] = "png",
        quality: Optional[int] = 100,
        full_page: Optional[bool] = False
    ) -> bytes:
        """
        Take a screenshot.
        
        Args:
            path: Path to save the screenshot
            type: Image type ('png' or 'jpeg')
            quality: Image quality (0-100)
            full_page: Capture full page
        
        Returns:
            Screenshot as bytes
        """
        result = await self._browser._send_message({
            "method": "Page.screenshot",
            "params": {
                "pageId": self._id,
                "path": path,
                "type": type,
                "quality": quality,
                "fullPage": full_page
            }
        })
        
        buffer = result.get("buffer", "")
        if buffer:
            import base64
            return base64.b64decode(buffer)
        return b""
    
    async def get_network_logs(self) -> List[Dict[str, Any]]:
        """
        Get all network logs.
        
        Returns:
            List of network log entries
        """
        result = await self._browser._send_message({
            "method": "Page.getNetworkLogs",
            "params": {"pageId": self._id}
        })
        
        logs = result.get("logs", [])
        return [
            {"request": Request(log["request"]), "response": Response(log.get("response"))}
            for log in logs
        ]
    
    async def clear_network_logs(self):
        """Clear all network logs."""
        await self._browser._send_message({
            "method": "Page.clearNetworkLogs",
            "params": {"pageId": self._id}
        })
    
    async def get_console_logs(self) -> List[Dict[str, Any]]:
        """
        Get all console logs.
        
        Returns:
            List of console log entries
        """
        result = await self._browser._send_message({
            "method": "Page.getConsoleLogs",
            "params": {"pageId": self._id}
        })
        return result.get("logs", [])
    
    async def clear_console_logs(self):
        """Clear all console logs."""
        await self._browser._send_message({
            "method": "Page.clearConsoleLogs",
            "params": {"pageId": self._id}
        })
    
    async def set_request_interception(self, enabled: bool):
        """
        Enable or disable request interception.
        
        Args:
            enabled: Whether to enable request interception
        """
        await self._browser._send_message({
            "method": "Page.setRequestInterception",
            "params": {"pageId": self._id, "enabled": enabled}
        })
    
    def on(self, event: str, handler: Callable):
        """
        Register an event handler.
        
        Args:
            event: Event name ('console', 'request', 'response', 'load', 'domcontentloaded', 'pageerror')
            handler: Event handler function
        """
        if event not in self._event_handlers:
            self._event_handlers[event] = []
        self._event_handlers[event].append(handler)
    
    # Aliases for common methods
    async def query_selector(self, selector: str) -> Optional[ElementHandle]:
        """Alias for query_selector."""
        return await self.query_selector(selector)
    
    async def query_selector_all(self, selector: str) -> List[ElementHandle]:
        """Alias for query_selector_all."""
        return await self.query_selector_all(selector)
