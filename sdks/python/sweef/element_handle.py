# Sweef Browser - Python SDK ElementHandle Class
# Ultra-lightweight browser for AI agents and humans

from typing import Optional, Dict, List, Any, Callable, Union
import asyncio

from .page import Page


class ElementHandle:
    """
    A handle to a DOM element that allows interaction.
    
    Example:
        page = await browser.new_page()
        await page.goto("https://example.com")
        element = await page.query_selector("button#submit")
        await element.click()
    """
    
    def __init__(self, page: Page, element: Dict[str, Any]):
        self._page = page
        self._element = element
        self._event_handlers: Dict[str, List[Callable]] = {}
    
    @property
    def page(self) -> Page:
        """Get the page instance."""
        return self._page
    
    @property
    def element(self) -> Dict[str, Any]:
        """Get the element data."""
        return self._element
    
    async def click(
        self,
        button: Optional[str] = "left",
        click_count: Optional[int] = 1
    ):
        """
        Click the element.
        
        Args:
            button: Mouse button ('left', 'right', 'middle')
            click_count: Number of clicks
        """
        await self._page._browser._send_message({
            "method": "ElementHandle.click",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "button": button,
                "clickCount": click_count
            }
        })
    
    async def hover(self):
        """Hover over the element."""
        await self._page._browser._send_message({
            "method": "ElementHandle.hover",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
    
    async def focus(self):
        """Focus on the element."""
        await self._page._browser._send_message({
            "method": "ElementHandle.focus",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
    
    async def type(self, text: str, delay: Optional[int] = None):
        """
        Type text into the element.
        
        Args:
            text: Text to type
            delay: Delay between keystrokes in milliseconds
        """
        await self._page._browser._send_message({
            "method": "ElementHandle.type",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "text": text,
                "delay": delay
            }
        })
    
    async def fill(self, value: str):
        """
        Fill the element.
        
        Args:
            value: Value to fill
        """
        await self._page._browser._send_message({
            "method": "ElementHandle.fill",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "value": value
            }
        })
    
    async def select(self, value: Union[str, List[str]]):
        """
        Select option(s) in a dropdown.
        
        Args:
            value: Value(s) to select
        """
        await self._page._browser._send_message({
            "method": "ElementHandle.select",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "value": value
            }
        })
    
    async def check(self):
        """Check the checkbox."""
        await self._page._browser._send_message({
            "method": "ElementHandle.check",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
    
    async def uncheck(self):
        """Uncheck the checkbox."""
        await self._page._browser._send_message({
            "method": "ElementHandle.uncheck",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
    
    async def upload_file(self, files: Union[str, List[str]]):
        """
        Upload file(s) to the element.
        
        Args:
            files: File path(s) to upload
        """
        await self._page._browser._send_message({
            "method": "ElementHandle.uploadFile",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "files": files
            }
        })
    
    async def text_content(self) -> str:
        """
        Get the text content of the element.
        
        Returns:
            Text content
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.textContent",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("text", "")
    
    async def inner_html(self) -> str:
        """
        Get the inner HTML of the element.
        
        Returns:
            Inner HTML
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.innerHTML",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("html", "")
    
    async def inner_text(self) -> str:
        """
        Get the inner text of the element.
        
        Returns:
            Inner text
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.innerText",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("text", "")
    
    async def get_attribute(self, attribute: str) -> Optional[str]:
        """
        Get an attribute value.
        
        Args:
            attribute: Attribute name
        
        Returns:
            Attribute value or None
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.getAttribute",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "attribute": attribute
            }
        })
        return result.get("value")
    
    async def bounding_box(self) -> Dict[str, float]:
        """
        Get the bounding box of the element.
        
        Returns:
            Dict with 'x', 'y', 'width', 'height' keys
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.boundingBox",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("box", {"x": 0, "y": 0, "width": 0, "height": 0})
    
    async def get_computed_style(self) -> Dict[str, str]:
        """
        Get the computed styles of the element.
        
        Returns:
            Dict of computed styles
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.getComputedStyle",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("styles", {})
    
    async def is_visible(self) -> bool:
        """
        Check if the element is visible.
        
        Returns:
            True if visible, False otherwise
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.isVisible",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("visible", False)
    
    async def is_hidden(self) -> bool:
        """
        Check if the element is hidden.
        
        Returns:
            True if hidden, False otherwise
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.isHidden",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("hidden", False)
    
    async def is_enabled(self) -> bool:
        """
        Check if the element is enabled.
        
        Returns:
            True if enabled, False otherwise
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.isEnabled",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("enabled", False)
    
    async def is_checked(self) -> bool:
        """
        Check if the element (checkbox) is checked.
        
        Returns:
            True if checked, False otherwise
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.isChecked",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("checked", False)
    
    async def is_selected(self) -> bool:
        """
        Check if the element (option) is selected.
        
        Returns:
            True if selected, False otherwise
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.isSelected",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id")
            }
        })
        return result.get("selected", False)
    
    async def query_selector(self, selector: str) -> Optional["ElementHandle"]:
        """
        Query selector (single element) within this element.
        
        Args:
            selector: CSS selector
        
        Returns:
            ElementHandle or None if not found
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.querySelector",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "selector": selector
            }
        })
        
        if result.get("element"):
            return ElementHandle(self._page, result["element"])
        return None
    
    async def query_selector_all(self, selector: str) -> List["ElementHandle"]:
        """
        Query selector (all elements) within this element.
        
        Args:
            selector: CSS selector
        
        Returns:
            List of ElementHandle instances
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.querySelectorAll",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "selector": selector
            }
        })
        
        elements = result.get("elements", [])
        return [ElementHandle(self._page, el) for el in elements]
    
    async def evaluate(self, js: str, arg: Optional[Any] = None) -> Any:
        """
        Execute JavaScript in the element context.
        
        Args:
            js: JavaScript code to execute
            arg: Argument to pass to the JavaScript function
        
        Returns:
            Result of the JavaScript execution
        """
        result = await self._page._browser._send_message({
            "method": "ElementHandle.evaluate",
            "params": {
                "pageId": self._page.id,
                "elementId": self._element.get("id"),
                "js": js,
                "arg": arg
            }
        })
        return result.get("value")
    
    async def dispose(self):
        """Dispose the element handle."""
        # Element handles are automatically cleaned up
        pass
    
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
