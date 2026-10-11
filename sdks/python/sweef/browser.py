# Sweef Browser - Python SDK Browser Class
# Ultra-lightweight browser for AI agents and humans

import asyncio
import json
import subprocess
import threading
from typing import Optional, Dict, List, Any, Callable, Union, Tuple


class Browser:
    """
    The main browser class that manages browser instances.
    
    Example:
        browser = await Browser.launch(headless=True)
        page = await browser.new_page()
        await page.goto("https://example.com")
        await browser.close()
    """
    
    def __init__(self):
        self._process: Optional[subprocess.Popen] = None
        self._options: Dict[str, Any] = {}
        self._contexts: Dict[int, "BrowserContext"] = {}
        self._pages: Dict[int, "Page"] = {}
        self._next_page_id: int = 1
        self._next_context_id: int = 1
        self._message_id: int = 1
        self._pending_promises: Dict[int, Tuple[asyncio.Future, Callable]] = {}
        self._lock = threading.Lock()
        self._stdout_buffer: bytes = b""
        self._event_handlers: Dict[str, List[Callable]] = {}
    
    @classmethod
    async def launch(cls, **kwargs) -> "Browser":
        """
        Launch a new browser instance.
        
        Args:
            headless: Run browser in headless mode (default: True)
            debug: Enable debug logging (default: False)
            timeout: Default timeout in milliseconds (default: 5000)
            slow_mo: Slow down operations by this many milliseconds (default: 0)
            user_agent: Custom user agent (default: "Sweef/0.1.0")
            viewport: Viewport dimensions as dict with 'width' and 'height' (default: {"width": 800, "height": 600})
            args: Additional command line arguments (default: [])
        
        Returns:
            Browser: A new browser instance
        """
        browser = cls()
        browser._options = {
            "headless": True,
            "debug": False,
            "timeout": 5000,
            "slow_mo": 0,
            "user_agent": "Sweef/0.1.0",
            "viewport": {"width": 800, "height": 600},
            "args": [],
            **kwargs
        }
        
        await browser._launch()
        return browser
    
    @classmethod
    async def connect(cls, **kwargs) -> "Browser":
        """
        Connect to an existing browser instance.
        
        Args:
            ws_endpoint: WebSocket endpoint to connect to
        
        Returns:
            Browser: A browser instance connected to the existing browser
        """
        browser = cls()
        await browser._connect(kwargs)
        return browser
    
    async def _launch(self):
        """Internal method to launch the browser process."""
        # Build command line arguments
        args = ["--headless"]
        
        if self._options.get("debug"):
            args.append("--debug")
        
        if self._options.get("user_agent"):
            args.extend(["--user-agent", self._options["user_agent"]])
        
        if self._options.get("viewport"):
            viewport = self._options["viewport"]
            args.extend(["--viewport", f"{viewport['width']}x{viewport['height']}"])
        
        if self._options.get("timeout"):
            args.extend(["--timeout", str(self._options["timeout"])])
        
        if self._options.get("slow_mo"):
            args.extend(["--slow-mo", str(self._options["slow_mo"])])
        
        # Add any additional args
        if self._options.get("args"):
            args.extend(self._options["args"])
        
        # Start the browser process
        self._process = subprocess.Popen(
            ["sweef"] + args,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=1,
        )
        
        # Set up message handling
        self._setup_message_handling()
        
        # Create default context
        context = BrowserContext(self, self._next_context_id)
        self._next_context_id += 1
        self._contexts[context.id] = context
        self._default_context = context
    
    async def _connect(self, options: Dict[str, Any]):
        """Internal method to connect to an existing browser instance."""
        # For now, just launch a new instance
        # In the future, we'll support connecting to an existing instance
        await self._launch()
    
    def _setup_message_handling(self):
        """Set up message handling for stdout and stderr."""
        if not self._process:
            return
        
        # Start thread to read stdout
        self._thread = threading.Thread(target=self._read_stdout, daemon=True)
        self._thread.start()
        
        # Start thread to read stderr
        self._stderr_thread = threading.Thread(target=self._read_stderr, daemon=True)
        self._stderr_thread.start()
    
    def _read_stdout(self):
        """Read and process stdout messages."""
        if not self._process:
            return
        
        while True:
            data = self._process.stdout.read(4096)
            if not data:
                break
            
            with self._lock:
                self._stdout_buffer += data
            
            self._process_messages(data)
    
    def _read_stderr(self):
        """Read and process stderr messages (debug logs)."""
        if not self._process:
            return
        
        while True:
            data = self._process.stderr.read(4096)
            if not data:
                break
            
            # Emit debug event
            if "debug" in self._event_handlers:
                for handler in self._event_handlers["debug"]:
                    handler(data.decode("utf-8", errors="ignore"))
    
    def _process_messages(self, data: bytes):
        """Process incoming JSON-RPC messages."""
        with self._lock:
            buffer = self._stdout_buffer + data
            self._stdout_buffer = b""
        
        offset = 0
        while offset < len(buffer):
            # Find the end of the next message
            end = buffer.find(b'\n', offset)
            if end == -1:
                break
            
            message_str = buffer[offset:end].decode("utf-8", errors="ignore")
            offset = end + 1
            
            try:
                message = json.loads(message_str)
                self._handle_message(message)
            except json.JSONDecodeError:
                # Ignore invalid JSON
                pass
        
        # Keep any remaining data in the buffer
        with self._lock:
            self._stdout_buffer = buffer[offset:]
    
    def _handle_message(self, message: Dict[str, Any]):
        """Handle an incoming JSON-RPC message."""
        # Check if this is a response to a pending promise
        if "id" in message and message["id"] in self._pending_promises:
            future, _ = self._pending_promises.pop(message["id"])
            
            if "error" in message:
                future.set_exception(Exception(message["error"].get("message", "Unknown error")))
            else:
                future.set_result(message.get("result"))
            return
        
        # Handle events
        if message.get("method") == "page.onConsole":
            page_id = message["params"]["pageId"]
            if page_id in self._pages:
                page = self._pages[page_id]
                if "console" in page._event_handlers:
                    for handler in page._event_handlers["console"]:
                        handler(message["params"]["data"])
            return
        
        if message.get("method") == "page.onRequest":
            page_id = message["params"]["pageId"]
            if page_id in self._pages:
                page = self._pages[page_id]
                if "request" in page._event_handlers:
                    for handler in page._event_handlers["request"]:
                        handler(Request(message["params"]["data"]))
            return
        
        if message.get("method") == "page.onResponse":
            page_id = message["params"]["pageId"]
            if page_id in self._pages:
                page = self._pages[page_id]
                if "response" in page._event_handlers:
                    for handler in page._event_handlers["response"]:
                        handler(Response(message["params"]["data"]))
            return
        
        if message.get("method") == "page.onLoad":
            page_id = message["params"]["pageId"]
            if page_id in self._pages:
                page = self._pages[page_id]
                if "load" in page._event_handlers:
                    for handler in page._event_handlers["load"]:
                        handler(message["params"]["data"])
            return
        
        if message.get("method") == "page.onDOMContentLoaded":
            page_id = message["params"]["pageId"]
            if page_id in self._pages:
                page = self._pages[page_id]
                if "domcontentloaded" in page._event_handlers:
                    for handler in page._event_handlers["domcontentloaded"]:
                        handler(message["params"]["data"])
            return
        
        if message.get("method") == "page.onError":
            page_id = message["params"]["pageId"]
            if page_id in self._pages:
                page = self._pages[page_id]
                if "pageerror" in page._event_handlers:
                    for handler in page._event_handlers["pageerror"]:
                        handler(message["params"]["data"])
            return
    
    async def _send_message(self, message: Dict[str, Any]) -> Any:
        """
        Send a message to the browser process.
        
        Args:
            message: The message to send
        
        Returns:
            The response from the browser
        """
        loop = asyncio.get_event_loop()
        
        def set_result(future: asyncio.Future, result: Any):
            loop.call_soon_threadsafe(future.set_result, result)
        
        def set_exception(future: asyncio.Future, exception: Exception):
            loop.call_soon_threadsafe(future.set_exception, exception)
        
        future: asyncio.Future = loop.create_future()
        
        with self._lock:
            message_id = self._message_id
            self._message_id += 1
            message["id"] = message_id
            self._pending_promises[message_id] = (future, lambda r: None)
        
        try:
            self._process.stdin.write((json.dumps(message) + "\n").encode("utf-8"))
            self._process.stdin.flush()
        except Exception as e:
            future.set_exception(e)
            return await future
        
        return await future
    
    async def new_context(self, **kwargs) -> "BrowserContext":
        """
        Create a new browser context.
        
        Args:
            user_agent: Custom user agent for this context
            viewport: Viewport dimensions as dict with 'width' and 'height'
            java_script_enabled: Enable JavaScript (default: True)
            bypass_csp: Bypass Content Security Policy (default: False)
        
        Returns:
            BrowserContext: A new browser context
        """
        context = BrowserContext(self, self._next_context_id, **kwargs)
        self._next_context_id += 1
        self._contexts[context.id] = context
        return context
    
    async def contexts(self) -> List["BrowserContext"]:
        """
        Get all browser contexts.
        
        Returns:
            List of BrowserContext instances
        """
        return list(self._contexts.values())
    
    async def close(self):
        """Close the browser and all its contexts and pages."""
        if self._process:
            await self._send_message({"method": "Browser.close"})
            self._process.kill()
            self._process = None
        
        self._contexts.clear()
        self._pages.clear()
    
    async def version(self) -> str:
        """
        Get the browser version.
        
        Returns:
            Browser version string
        """
        result = await self._send_message({"method": "Browser.version"})
        return result.get("version", "0.1.0")
    
    def on(self, event: str, handler: Callable):
        """
        Register an event handler.
        
        Args:
            event: Event name ('close', 'debug', 'error')
            handler: Event handler function
        """
        if event not in self._event_handlers:
            self._event_handlers[event] = []
        self._event_handlers[event].append(handler)
    
    @property
    def process(self):
        """Get the underlying subprocess.Popen instance."""
        return self._process
