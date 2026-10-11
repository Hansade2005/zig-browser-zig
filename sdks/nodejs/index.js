// Sweef Browser - Node.js SDK
// Ultra-lightweight browser for AI agents and humans

const { spawn } = require('child_process');
const EventEmitter = require('events');
const path = require('path');

/**
 * @typedef {Object} BrowserLaunchOptions
 * @property {boolean} [headless=true] - Run browser in headless mode
 * @property {boolean} [debug=false] - Enable debug logging
 * @property {number} [timeout=5000] - Default timeout in milliseconds
 * @property {number} [slowMo=0] - Slow down operations by this many milliseconds
 * @property {string} [userAgent='Sweef/0.1.0'] - Custom user agent
 * @property {Object} [viewport] - Viewport dimensions
 * @property {number} [viewport.width=800] - Viewport width
 * @property {number} [viewport.height=600] - Viewport height
 * @property {string[]} [args=[]] - Additional command line arguments
 */

/**
 * @typedef {Object} Browser
 * @property {() => Promise<BrowserContext>} newContext - Create a new browser context
 * @property {() => Promise<BrowserContext[]>} contexts - Get all browser contexts
 * @property {() => Promise<void>} close - Close the browser
 * @property {() => Promise<string>} version - Get browser version
 */

/**
 * @typedef {Object} BrowserContextOptions
 * @property {string} [userAgent] - Custom user agent for this context
 * @property {Object} [viewport] - Viewport dimensions for this context
 * @property {boolean} [javaScriptEnabled=true] - Enable JavaScript
 * @property {boolean} [bypassCSP=false] - Bypass Content Security Policy
 */

/**
 * @typedef {Object} BrowserContext
 * @property {() => Promise<Page>} newPage - Create a new page in this context
 * @property {() => Promise<Page[]>} pages - Get all pages in this context
 * @property {() => Promise<void>} close - Close this context
 * @property {(cookies: Array<{name: string, value: string, url?: string}>) => Promise<void>} addCookies - Add cookies to this context
 * @property {(urls?: string[]) => Promise<Array<{name: string, value: string, url: string}>>} cookies - Get cookies from this context
 * @property {() => Promise<void>} clearCookies - Clear all cookies in this context
 * @property {(offline: boolean) => Promise<void>} setOffline - Set offline mode
 * @property {(geolocation: {latitude: number, longitude: number}) => Promise<void>} setGeolocation - Set geolocation
 * @property {(userAgent: string) => Promise<void>} setUserAgent - Set user agent
 * @property {(viewport: {width: number, height: number}) => Promise<void>} setViewport - Set viewport dimensions
 */

/**
 * @typedef {Object} Page
 * @property {(url: string, options?: {waitUntil?: 'load' | 'domcontentloaded' | 'networkidle', timeout?: number}) => Promise<void>} goto - Navigate to URL
 * @property {() => Promise<void>} reload - Reload the page
 * @property {() => Promise<void>} goBack - Navigate back in history
 * @property {() => Promise<void>} goForward - Navigate forward in history
 * @property {() => Promise<void>} close - Close the page
 * @property {() => Promise<string>} title - Get page title
 * @property {() => Promise<string>} url - Get current URL
 * @property {() => Promise<string>} content - Get page HTML content
 * @property {(html: string) => Promise<void>} setContent - Set page HTML content
 * @property {(selector: string, options?: {button?: 'left' | 'right' | 'middle', clickCount?: number}) => Promise<void>} click - Click an element
 * @property {(selector: string) => Promise<void>} dblclick - Double click an element
 * @property {(selector: string) => Promise<void>} hover - Hover over an element
 * @property {(selector: string) => Promise<void>} focus - Focus on an element
 * @property {(selector: string, text: string, options?: {delay?: number}) => Promise<void>} type - Type text into an element
 * @property {(selector: string, value: string) => Promise<void>} fill - Fill an input element
 * @property {(selector: string, value: string | string[]) => Promise<void>} select - Select option(s) in a dropdown
 * @property {(selector: string) => Promise<void>} check - Check a checkbox
 * @property {(selector: string) => Promise<void>} uncheck - Uncheck a checkbox
 * @property {(key: string) => Promise<void>} press - Press a key
 * @property {(selector: string, files: string | string[]) => Promise<void>} setInputFiles - Set files for file input
 * @property {(selector: string, options?: {state?: 'visible' | 'hidden' | 'attached' | 'detached', timeout?: number}) => Promise<?ElementHandle>} waitForSelector - Wait for an element to appear
 * @property {(js: string, options?: {timeout?: number, polling?: 'raf' | 'mutation' | number}) => Promise<any>} waitForFunction - Wait for a JavaScript condition
 * @property {(options?: {timeout?: number, waitUntil?: 'load' | 'domcontentloaded' | 'networkidle'}) => Promise<void>} waitForNavigation - Wait for page navigation
 * @property {(state: 'load' | 'domcontentloaded' | 'networkidle', options?: {timeout?: number}) => Promise<void>} waitForLoadState - Wait for a specific load state
 * @property {(url: string, options?: {timeout?: number}) => Promise<Request>} waitForRequest - Wait for a specific request
 * @property {(url: string, options?: {timeout?: number}) => Promise<Response>} waitForResponse - Wait for a specific response
 * @property {(ms: number) => Promise<void>} waitForTimeout - Wait for a timeout
 * @property {(js: string, arg?: any) => Promise<any>} evaluate - Execute JavaScript in the page context
 * @property {(js: string) => Promise<JSHandle>} evaluateHandle - Execute JavaScript and return a handle to the result
 * @property {(selector: string) => Promise<?ElementHandle>} $ - Query selector (single element)
 * @property {(selector: string) => Promise<ElementHandle[]>} $$ - Query selector (all elements)
 * @property {(expression: string) => Promise<ElementHandle[]>} $x - XPath selector
 * @property {(selector: string) => Promise<string>} textContent - Get text content of an element
 * @property {(selector: string) => Promise<string>} innerHTML - Get inner HTML of an element
 * @property {(selector: string) => Promise<string>} innerText - Get inner text of an element
 * @property {(selector: string, attribute: string) => Promise<?string>} getAttribute - Get an attribute value
 * @property {(selector: string) => Promise<{x: number, y: number, width: number, height: number}>} boundingBox - Get element bounding box
 * @property {(selector: string) => Promise<Object>} getComputedStyle - Get computed styles for an element
 * @property {(selector: string) => Promise<boolean>} isVisible - Check if an element is visible
 * @property {(selector: string) => Promise<boolean>} isHidden - Check if an element is hidden
 * @property {(selector: string) => Promise<boolean>} isEnabled - Check if an element is enabled
 * @property {(selector: string) => Promise<boolean>} isChecked - Check if a checkbox is checked
 * @property {(selector: string) => Promise<boolean>} isSelected - Check if an option is selected
 * @property {(path?: string, options?: {type?: 'png' | 'jpeg', quality?: number, fullPage?: boolean}) => Promise<Buffer>} screenshot - Take a screenshot
 * @property {() => Promise<Array<{request: Request, response?: Response}>>} getNetworkLogs - Get all network logs
 * @property {() => Promise<void>} clearNetworkLogs - Clear network logs
 * @property {() => Promise<Array<{type: string, text: string, args: any[]}>>} getConsoleLogs - Get all console logs
 * @property {() => Promise<void>} clearConsoleLogs - Clear console logs
 * @property {(enabled: boolean) => Promise<void>} setRequestInterception - Enable/disable request interception
 */

/**
 * @typedef {Object} ElementHandle
 * @property {(options?: {button?: 'left' | 'right' | 'middle', clickCount?: number}) => Promise<void>} click - Click the element
 * @property {() => Promise<void>} hover - Hover over the element
 * @property {() => Promise<void>} focus - Focus on the element
 * @property {(text: string, options?: {delay?: number}) => Promise<void>} type - Type text into the element
 * @property {(value: string) => Promise<void>} fill - Fill the element
 * @property {(value: string | string[]) => Promise<void>} select - Select option(s) in a dropdown
 * @property {() => Promise<void>} check - Check the checkbox
 * @property {() => Promise<void>} uncheck - Uncheck the checkbox
 * @property {(files: string | string[]) => Promise<void>} uploadFile - Upload file(s)
 * @property {() => Promise<string>} textContent - Get text content
 * @property {() => Promise<string>} innerHTML - Get inner HTML
 * @property {() => Promise<string>} innerText - Get inner text
 * @property {(attribute: string) => Promise<?string>} getAttribute - Get an attribute value
 * @property {() => Promise<{x: number, y: number, width: number, height: number}>} boundingBox - Get bounding box
 * @property {() => Promise<Object>} getComputedStyle - Get computed styles
 * @property {() => Promise<boolean>} isVisible - Check if visible
 * @property {() => Promise<boolean>} isHidden - Check if hidden
 * @property {() => Promise<boolean>} isEnabled - Check if enabled
 * @property {() => Promise<boolean>} isChecked - Check if checked
 * @property {() => Promise<boolean>} isSelected - Check if selected
 * @property {(selector: string) => Promise<?ElementHandle>} $ - Query selector (single element)
 * @property {(selector: string) => Promise<ElementHandle[]>} $$ - Query selector (all elements)
 * @property {(expression: string) => Promise<ElementHandle[]>} $x - XPath selector
 * @property {(js: string, arg?: any) => Promise<any>} evaluate - Execute JavaScript in element context
 * @property {() => Promise<void>} dispose - Dispose the element handle
 */

/**
 * @typedef {Object} JSHandle
 * @property {() => Promise<any>} evaluate - Execute JavaScript with this handle as `this`
 * @property {() => Promise<any>} getProperties - Get all properties of the object
 * @property {(property: string) => Promise<any>} getProperty - Get a specific property
 * @property {() => Promise<void>} dispose - Dispose the JS handle
 */

/**
 * @typedef {Object} Request
 * @property {string} url - Request URL
 * @property {string} method - HTTP method
 * @property {Object} headers - Request headers
 * @property {?Buffer} postData - POST data (if applicable)
 */

/**
 * @typedef {Object} Response
 * @property {string} url - Response URL
 * @property {number} status - HTTP status code
 * @property {string} statusText - HTTP status text
 * @property {Object} headers - Response headers
 */

/**
 * Sweef Browser - Node.js SDK
 * Ultra-lightweight browser for AI agents and humans
 */
class Browser extends EventEmitter {
    /**
     * @param {BrowserLaunchOptions} [options]
     */
    constructor(options = {}) {
        super();
        this.options = {
            headless: true,
            debug: false,
            timeout: 5000,
            slowMo: 0,
            userAgent: 'Sweef/0.1.0',
            viewport: { width: 800, height: 600 },
            args: [],
            ...options
        };

        this.process = null;
        this.contexts = new Map();
        this.pages = new Map();
        this.nextPageId = 1;
        this.nextContextId = 1;
        this.messageId = 1;
        this.pendingPromises = new Map();
    }

    /**
     * Launch the browser
     * @returns {Promise<Browser>}
     */
    static async launch(options = {}) {
        const browser = new Browser(options);
        await browser._launch();
        return browser;
    }

    /**
     * Connect to an existing browser instance
     * @param {Object} [options]
     * @param {string} [options.wsEndpoint] - WebSocket endpoint to connect to
     * @returns {Promise<Browser>}
     */
    static async connect(options = {}) {
        const browser = new Browser();
        await browser._connect(options);
        return browser;
    }

    async _launch() {
        // Build command line arguments
        const args = ['--headless'];
        
        if (this.options.debug) {
            args.push('--debug');
        }
        
        if (this.options.userAgent) {
            args.push('--user-agent', this.options.userAgent);
        }
        
        if (this.options.viewport) {
            args.push('--viewport', `${this.options.viewport.width}x${this.options.viewport.height}`);
        }
        
        if (this.options.timeout) {
            args.push('--timeout', String(this.options.timeout));
        }
        
        if (this.options.slowMo) {
            args.push('--slow-mo', String(this.options.slowMo));
        }
        
        // Add any additional args
        args.push(...this.options.args);

        // Start the browser process
        this.process = spawn(path.join(__dirname, '..', '..', 'cli', 'sweef'), args, {
            stdio: ['pipe', 'pipe', 'pipe'],
        });

        // Set up message handling
        this._setupMessageHandling();

        // Create default context
        const context = new BrowserContext(this, this.nextContextId++);
        this.contexts.set(context.id, context);
        this.defaultContext = context;
    }

    async _connect(options) {
        // For now, just launch a new instance
        // In the future, we'll support connecting to an existing instance
        return this._launch();
    }

    _setupMessageHandling() {
        const stdout = this.process.stdout;
        const stderr = this.process.stderr;

        // Handle stdout messages (JSON-RPC responses)
        let stdoutBuffer = Buffer.from('');
        stdout.on('data', (data) => {
            stdoutBuffer = Buffer.concat([stdoutBuffer, data]);
            this._processMessages(stdoutBuffer);
        });

        // Handle stderr messages (debug logs)
        stderr.on('data', (data) => {
            this.emit('debug', data.toString());
        });

        // Handle process exit
        this.process.on('exit', (code) => {
            this.emit('close');
        });
    }

    _processMessages(buffer) {
        let offset = 0;
        
        while (offset < buffer.length) {
            // Find the end of the next message
            let end = buffer.indexOf('\n', offset);
            if (end === -1) break;

            const messageStr = buffer.toString('utf8', offset, end);
            offset = end + 1;

            try {
                const message = JSON.parse(messageStr);
                this._handleMessage(message);
            } catch (err) {
                this.emit('error', new Error(`Failed to parse message: ${err.message}`));
            }
        }

        // Keep any remaining data in the buffer
        if (offset > 0) {
            this.stdoutBuffer = buffer.slice(offset);
        }
    }

    _handleMessage(message) {
        // Check if this is a response to a pending promise
        if (message.id && this.pendingPromises.has(message.id)) {
            const { resolve, reject } = this.pendingPromises.get(message.id);
            this.pendingPromises.delete(message.id);

            if (message.error) {
                reject(new Error(message.error.message || 'Unknown error')));
            } else {
                resolve(message.result);
            }
            return;
        }

        // Handle events
        if (message.method === 'page.onConsole') {
            const pageId = message.params.pageId;
            const page = this.pages.get(pageId);
            if (page) {
                page.emit('console', message.params.data);
            }
            return;
        }

        if (message.method === 'page.onRequest') {
            const pageId = message.params.pageId;
            const page = this.pages.get(pageId);
            if (page) {
                page.emit('request', message.params.data);
            }
            return;
        }

        if (message.method === 'page.onResponse') {
            const pageId = message.params.pageId;
            const page = this.pages.get(pageId);
            if (page) {
                page.emit('response', message.params.data);
            }
            return;
        }

        if (message.method === 'page.onLoad') {
            const pageId = message.params.pageId;
            const page = this.pages.get(pageId);
            if (page) {
                page.emit('load', message.params.data);
            }
            return;
        }

        if (message.method === 'page.onDOMContentLoaded') {
            const pageId = message.params.pageId;
            const page = this.pages.get(pageId);
            if (page) {
                page.emit('domcontentloaded', message.params.data);
            }
            return;
        }

        if (message.method === 'page.onError') {
            const pageId = message.params.pageId;
            const page = this.pages.get(pageId);
            if (page) {
                page.emit('pageerror', message.params.data);
            }
            return;
        }
    }

    /**
     * Send a message to the browser process
     * @param {Object} message - The message to send
     * @returns {Promise<any>}
     */
    async _sendMessage(message) {
        return new Promise((resolve, reject) => {
            const id = this.messageId++;
            message.id = id;

            this.pendingPromises.set(id, { resolve, reject });

            try {
                this.process.stdin.write(JSON.stringify(message) + '\n');
            } catch (err) {
                reject(err);
            }
        });
    }

    /**
     * Create a new browser context
     * @param {BrowserContextOptions} [options]
     * @returns {Promise<BrowserContext>}
     */
    async newContext(options = {}) {
        const context = new BrowserContext(this, this.nextContextId++, options);
        this.contexts.set(context.id, context);
        return context;
    }

    /**
     * Get all browser contexts
     * @returns {Promise<BrowserContext[]>}
     */
    async contexts() {
        return Array.from(this.contexts.values());
    }

    /**
     * Close the browser
     * @returns {Promise<void>}
     */
    async close() {
        if (this.process) {
            await this._sendMessage({ method: 'Browser.close' });
            this.process.kill();
            this.process = null;
        }

        this.contexts.clear();
        this.pages.clear();
    }

    /**
     * Get browser version
     * @returns {Promise<string>}
     */
    async version() {
        const result = await this._sendMessage({ method: 'Browser.version' });
        return result.version;
    }
}

/**
 * Browser Context
 */
class BrowserContext extends EventEmitter {
    /**
     * @param {Browser} browser - The browser instance
     * @param {number} id - The context ID
     * @param {BrowserContextOptions} [options]
     */
    constructor(browser, id, options = {}) {
        super();
        this.browser = browser;
        this.id = id;
        this.options = options;
        this.pages = new Map();
        this.nextPageId = 1;
    }

    /**
     * Create a new page in this context
     * @returns {Promise<Page>}
     */
    async newPage() {
        const pageId = this.nextPageId++;
        const page = new Page(this.browser, this, pageId);
        this.pages.set(pageId, page);
        this.browser.pages.set(pageId, page);
        return page;
    }

    /**
     * Get all pages in this context
     * @returns {Promise<Page[]>}
     */
    async pages() {
        return Array.from(this.pages.values());
    }

    /**
     * Close this context
     * @returns {Promise<void>}
     */
    async close() {
        for (const page of this.pages.values()) {
            await page.close();
        }
        this.pages.clear();
        this.browser.contexts.delete(this.id);
    }

    /**
     * Add cookies to this context
     * @param {Array<{name: string, value: string, url?: string}>} cookies
     * @returns {Promise<void>}
     */
    async addCookies(cookies) {
        await this.browser._sendMessage({
            method: 'BrowserContext.addCookies',
            params: { cookies }
        });
    }

    /**
     * Get cookies from this context
     * @param {string[]} [urls] - Optional array of URLs to get cookies for
     * @returns {Promise<Array<{name: string, value: string, url: string}>>}
     */
    async cookies(urls) {
        const result = await this.browser._sendMessage({
            method: 'BrowserContext.cookies',
            params: { urls: urls || [] }
        });
        return result.cookies || [];
    }

    /**
     * Clear all cookies in this context
     * @returns {Promise<void>}
     */
    async clearCookies() {
        await this.browser._sendMessage({
            method: 'BrowserContext.clearCookies'
        });
    }

    /**
     * Set offline mode
     * @param {boolean} offline
     * @returns {Promise<void>}
     */
    async setOffline(offline) {
        await this.browser._sendMessage({
            method: 'BrowserContext.setOffline',
            params: { offline }
        });
    }

    /**
     * Set geolocation
     * @param {{latitude: number, longitude: number}} geolocation
     * @returns {Promise<void>}
     */
    async setGeolocation(geolocation) {
        await this.browser._sendMessage({
            method: 'BrowserContext.setGeolocation',
            params: { geolocation }
        });
    }

    /**
     * Set user agent
     * @param {string} userAgent
     * @returns {Promise<void>}
     */
    async setUserAgent(userAgent) {
        await this.browser._sendMessage({
            method: 'BrowserContext.setUserAgent',
            params: { userAgent }
        });
    }

    /**
     * Set viewport dimensions
     * @param {{width: number, height: number}} viewport
     * @returns {Promise<void>}
     */
    async setViewport(viewport) {
        await this.browser._sendMessage({
            method: 'BrowserContext.setViewport',
            params: { viewport }
        });
    }
}

/**
 * Page
 */
class Page extends EventEmitter {
    /**
     * @param {Browser} browser - The browser instance
     * @param {BrowserContext} context - The browser context
     * @param {number} id - The page ID
     */
    constructor(browser, context, id) {
        super();
        this.browser = browser;
        this.context = context;
        this.id = id;
        this.closed = false;
    }

    /**
     * Navigate to URL
     * @param {string} url - The URL to navigate to
     * @param {Object} [options]
     * @param {'load' | 'domcontentloaded' | 'networkidle'} [options.waitUntil='load']
     * @param {number} [options.timeout]
     * @returns {Promise<void>}
     */
    async goto(url, options = {}) {
        const { waitUntil = 'load', timeout } = options;
        
        await this.browser._sendMessage({
            method: 'Page.goto',
            params: { pageId: this.id, url, waitUntil, timeout }
        });
    }

    /**
     * Reload the page
     * @param {Object} [options]
     * @param {'load' | 'domcontentloaded' | 'networkidle'} [options.waitUntil='load']
     * @param {number} [options.timeout]
     * @returns {Promise<void>}
     */
    async reload(options = {}) {
        const { waitUntil = 'load', timeout } = options;
        
        await this.browser._sendMessage({
            method: 'Page.reload',
            params: { pageId: this.id, waitUntil, timeout }
        });
    }

    /**
     * Navigate back in history
     * @param {Object} [options]
     * @param {'load' | 'domcontentloaded' | 'networkidle'} [options.waitUntil='load']
     * @param {number} [options.timeout]
     * @returns {Promise<void>}
     */
    async goBack(options = {}) {
        const { waitUntil = 'load', timeout } = options;
        
        await this.browser._sendMessage({
            method: 'Page.goBack',
            params: { pageId: this.id, waitUntil, timeout }
        });
    }

    /**
     * Navigate forward in history
     * @param {Object} [options]
     * @param {'load' | 'domcontentloaded' | 'networkidle'} [options.waitUntil='load']
     * @param {number} [options.timeout]
     * @returns {Promise<void>}
     */
    async goForward(options = {}) {
        const { waitUntil = 'load', timeout } = options;
        
        await this.browser._sendMessage({
            method: 'Page.goForward',
            params: { pageId: this.id, waitUntil, timeout }
        });
    }

    /**
     * Close the page
     * @returns {Promise<void>}
     */
    async close() {
        if (this.closed) return;
        
        await this.browser._sendMessage({
            method: 'Page.close',
            params: { pageId: this.id }
        });

        this.closed = true;
        this.context.pages.delete(this.id);
        this.browser.pages.delete(this.id);
    }

    /**
     * Get page title
     * @returns {Promise<string>}
     */
    async title() {
        const result = await this.browser._sendMessage({
            method: 'Page.title',
            params: { pageId: this.id }
        });
        return result.title || '';
    }

    /**
     * Get current URL
     * @returns {Promise<string>}
     */
    async url() {
        const result = await this.browser._sendMessage({
            method: 'Page.url',
            params: { pageId: this.id }
        });
        return result.url || '';
    }

    /**
     * Get page HTML content
     * @returns {Promise<string>}
     */
    async content() {
        const result = await this.browser._sendMessage({
            method: 'Page.content',
            params: { pageId: this.id }
        });
        return result.content || '';
    }

    /**
     * Set page HTML content
     * @param {string} html
     * @returns {Promise<void>}
     */
    async setContent(html) {
        await this.browser._sendMessage({
            method: 'Page.setContent',
            params: { pageId: this.id, html }
        });
    }

    /**
     * Click an element
     * @param {string} selector - CSS selector
     * @param {Object} [options]
     * @param {'left' | 'right' | 'middle'} [options.button='left']
     * @param {number} [options.clickCount=1]
     * @returns {Promise<void>}
     */
    async click(selector, options = {}) {
        const { button = 'left', clickCount = 1 } = options;
        
        await this.browser._sendMessage({
            method: 'Page.click',
            params: { pageId: this.id, selector, button, clickCount }
        });
    }

    /**
     * Double click an element
     * @param {string} selector - CSS selector
     * @returns {Promise<void>}
     */
    async dblclick(selector) {
        await this.browser._sendMessage({
            method: 'Page.dblclick',
            params: { pageId: this.id, selector }
        });
    }

    /**
     * Hover over an element
     * @param {string} selector - CSS selector
     * @returns {Promise<void>}
     */
    async hover(selector) {
        await this.browser._sendMessage({
            method: 'Page.hover',
            params: { pageId: this.id, selector }
        });
    }

    /**
     * Focus on an element
     * @param {string} selector - CSS selector
     * @returns {Promise<void>}
     */
    async focus(selector) {
        await this.browser._sendMessage({
            method: 'Page.focus',
            params: { pageId: this.id, selector }
        });
    }

    /**
     * Type text into an element
     * @param {string} selector - CSS selector
     * @param {string} text - Text to type
     * @param {Object} [options]
     * @param {number} [options.delay] - Delay between keystrokes in ms
     * @returns {Promise<void>}
     */
    async type(selector, text, options = {}) {
        const { delay } = options;
        
        await this.browser._sendMessage({
            method: 'Page.type',
            params: { pageId: this.id, selector, text, delay }
        });
    }

    /**
     * Fill an input element
     * @param {string} selector - CSS selector
     * @param {string} value - Value to fill
     * @returns {Promise<void>}
     */
    async fill(selector, value) {
        await this.browser._sendMessage({
            method: 'Page.fill',
            params: { pageId: this.id, selector, value }
        });
    }

    /**
     * Select option(s) in a dropdown
     * @param {string} selector - CSS selector
     * @param {string | string[]} value - Value(s) to select
     * @returns {Promise<void>}
     */
    async select(selector, value) {
        await this.browser._sendMessage({
            method: 'Page.select',
            params: { pageId: this.id, selector, value }
        });
    }

    /**
     * Check a checkbox
     * @param {string} selector - CSS selector
     * @returns {Promise<void>}
     */
    async check(selector) {
        await this.browser._sendMessage({
            method: 'Page.check',
            params: { pageId: this.id, selector }
        });
    }

    /**
     * Uncheck a checkbox
     * @param {string} selector - CSS selector
     * @returns {Promise<void>}
     */
    async uncheck(selector) {
        await this.browser._sendMessage({
            method: 'Page.uncheck',
            params: { pageId: this.id, selector }
        });
    }

    /**
     * Press a key
     * @param {string} key - Key to press (e.g., 'Enter', 'Tab', 'Escape')
     * @returns {Promise<void>}
     */
    async press(key) {
        await this.browser._sendMessage({
            method: 'Page.press',
            params: { pageId: this.id, key }
        });
    }

    /**
     * Set files for file input
     * @param {string} selector - CSS selector
     * @param {string | string[]} files - File path(s)
     * @returns {Promise<void>}
     */
    async setInputFiles(selector, files) {
        await this.browser._sendMessage({
            method: 'Page.setInputFiles',
            params: { pageId: this.id, selector, files }
        });
    }

    /**
     * Wait for an element to appear
     * @param {string} selector - CSS selector
     * @param {Object} [options]
     * @param {'visible' | 'hidden' | 'attached' | 'detached'} [options.state='visible']
     * @param {number} [options.timeout]
     * @returns {Promise<?ElementHandle>}
     */
    async waitForSelector(selector, options = {}) {
        const { state = 'visible', timeout } = options;
        
        const result = await this.browser._sendMessage({
            method: 'Page.waitForSelector',
            params: { pageId: this.id, selector, state, timeout }
        });

        if (result.success) {
            return new ElementHandle(this, result.element);
        }
        return null;
    }

    /**
     * Wait for a JavaScript condition
     * @param {string} js - JavaScript expression to evaluate
     * @param {Object} [options]
     * @param {'raf' | 'mutation' | number} [options.polling='raf']
     * @param {number} [options.timeout]
     * @returns {Promise<any>}
     */
    async waitForFunction(js, options = {}) {
        const { polling = 'raf', timeout } = options;
        
        const result = await this.browser._sendMessage({
            method: 'Page.waitForFunction',
            params: { pageId: this.id, js, polling, timeout }
        });

        return result.value;
    }

    /**
     * Wait for page navigation
     * @param {Object} [options]
     * @param {'load' | 'domcontentloaded' | 'networkidle'} [options.waitUntil='load']
     * @param {number} [options.timeout]
     * @returns {Promise<void>}
     */
    async waitForNavigation(options = {}) {
        const { waitUntil = 'load', timeout } = options;
        
        await this.browser._sendMessage({
            method: 'Page.waitForNavigation',
            params: { pageId: this.id, waitUntil, timeout }
        });
    }

    /**
     * Wait for a specific load state
     * @param {'load' | 'domcontentloaded' | 'networkidle'} state
     * @param {Object} [options]
     * @param {number} [options.timeout]
     * @returns {Promise<void>}
     */
    async waitForLoadState(state, options = {}) {
        const { timeout } = options;
        
        await this.browser._sendMessage({
            method: 'Page.waitForLoadState',
            params: { pageId: this.id, state, timeout }
        });
    }

    /**
     * Wait for a specific request
     * @param {string} url - URL to wait for
     * @param {Object} [options]
     * @param {number} [options.timeout]
     * @returns {Promise<Request>}
     */
    async waitForRequest(url, options = {}) {
        const { timeout } = options;
        
        const result = await this.browser._sendMessage({
            method: 'Page.waitForRequest',
            params: { pageId: this.id, url, timeout }
        });

        return new Request(result);
    }

    /**
     * Wait for a specific response
     * @param {string} url - URL to wait for
     * @param {Object} [options]
     * @param {number} [options.timeout]
     * @returns {Promise<Response>}
     */
    async waitForResponse(url, options = {}) {
        const { timeout } = options;
        
        const result = await this.browser._sendMessage({
            method: 'Page.waitForResponse',
            params: { pageId: this.id, url, timeout }
        });

        return new Response(result);
    }

    /**
     * Wait for a timeout
     * @param {number} ms - Milliseconds to wait
     * @returns {Promise<void>}
     */
    async waitForTimeout(ms) {
        await this.browser._sendMessage({
            method: 'Page.waitForTimeout',
            params: { pageId: this.id, ms }
        });
    }

    /**
     * Execute JavaScript in the page context
     * @param {string} js - JavaScript code to execute
     * @param {any} [arg] - Argument to pass to the JavaScript function
     * @returns {Promise<any>}
     */
    async evaluate(js, arg) {
        const result = await this.browser._sendMessage({
            method: 'Page.evaluate',
            params: { pageId: this.id, js, arg }
        });

        return result.result;
    }

    /**
     * Execute JavaScript and return a handle to the result
     * @param {string} js - JavaScript code to execute
     * @returns {Promise<JSHandle>}
     */
    async evaluateHandle(js) {
        const result = await this.browser._sendMessage({
            method: 'Page.evaluateHandle',
            params: { pageId: this.id, js }
        });

        return new JSHandle(this, result.handle);
    }

    /**
     * Query selector (single element)
     * @param {string} selector - CSS selector
     * @returns {Promise<?ElementHandle>}
     */
    async $(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.querySelector',
            params: { pageId: this.id, selector }
        });

        if (result.element) {
            return new ElementHandle(this, result.element);
        }
        return null;
    }

    /**
     * Query selector (all elements)
     * @param {string} selector - CSS selector
     * @returns {Promise<ElementHandle[]>}
     */
    async $$(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.querySelectorAll',
            params: { pageId: this.id, selector }
        });

        return (result.elements || []).map(el => new ElementHandle(this, el));
    }

    /**
     * XPath selector
     * @param {string} expression - XPath expression
     * @returns {Promise<ElementHandle[]>}
     */
    async $x(expression) {
        const result = await this.browser._sendMessage({
            method: 'Page.xpath',
            params: { pageId: this.id, expression }
        });

        return (result.elements || []).map(el => new ElementHandle(this, el));
    }

    /**
     * Get text content of an element
     * @param {string} selector - CSS selector
     * @returns {Promise<string>}
     */
    async textContent(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.textContent',
            params: { pageId: this.id, selector }
        });

        return result.text || '';
    }

    /**
     * Get inner HTML of an element
     * @param {string} selector - CSS selector
     * @returns {Promise<string>}
     */
    async innerHTML(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.innerHTML',
            params: { pageId: this.id, selector }
        });

        return result.html || '';
    }

    /**
     * Get inner text of an element
     * @param {string} selector - CSS selector
     * @returns {Promise<string>}
     */
    async innerText(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.innerText',
            params: { pageId: this.id, selector }
        });

        return result.text || '';
    }

    /**
     * Get an attribute value
     * @param {string} selector - CSS selector
     * @param {string} attribute - Attribute name
     * @returns {Promise<?string>}
     */
    async getAttribute(selector, attribute) {
        const result = await this.browser._sendMessage({
            method: 'Page.getAttribute',
            params: { pageId: this.id, selector, attribute }
        });

        return result.value || null;
    }

    /**
     * Get element bounding box
     * @param {string} selector - CSS selector
     * @returns {Promise<{x: number, y: number, width: number, height: number}>}
     */
    async boundingBox(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.boundingBox',
            params: { pageId: this.id, selector }
        });

        return result.box || { x: 0, y: 0, width: 0, height: 0 };
    }

    /**
     * Get computed styles for an element
     * @param {string} selector - CSS selector
     * @returns {Promise<Object>}
     */
    async getComputedStyle(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.getComputedStyle',
            params: { pageId: this.id, selector }
        });

        return result.styles || {};
    }

    /**
     * Check if an element is visible
     * @param {string} selector - CSS selector
     * @returns {Promise<boolean>}
     */
    async isVisible(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.isVisible',
            params: { pageId: this.id, selector }
        });

        return result.visible || false;
    }

    /**
     * Check if an element is hidden
     * @param {string} selector - CSS selector
     * @returns {Promise<boolean>}
     */
    async isHidden(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.isHidden',
            params: { pageId: this.id, selector }
        });

        return result.hidden || false;
    }

    /**
     * Check if an element is enabled
     * @param {string} selector - CSS selector
     * @returns {Promise<boolean>}
     */
    async isEnabled(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.isEnabled',
            params: { pageId: this.id, selector }
        });

        return result.enabled || false;
    }

    /**
     * Check if a checkbox is checked
     * @param {string} selector - CSS selector
     * @returns {Promise<boolean>}
     */
    async isChecked(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.isChecked',
            params: { pageId: this.id, selector }
        });

        return result.checked || false;
    }

    /**
     * Check if an option is selected
     * @param {string} selector - CSS selector
     * @returns {Promise<boolean>}
     */
    async isSelected(selector) {
        const result = await this.browser._sendMessage({
            method: 'Page.isSelected',
            params: { pageId: this.id, selector }
        });

        return result.selected || false;
    }

    /**
     * Take a screenshot
     * @param {Object} [options]
     * @param {string} [options.path] - Path to save the screenshot
     * @param {'png' | 'jpeg'} [options.type='png'] - Image type
     * @param {number} [options.quality=100] - Image quality (0-100)
     * @param {boolean} [options.fullPage=false] - Capture full page
     * @returns {Promise<Buffer>}
     */
    async screenshot(options = {}) {
        const { path, type = 'png', quality = 100, fullPage = false } = options;
        
        const result = await this.browser._sendMessage({
            method: 'Page.screenshot',
            params: { pageId: this.id, path, type, quality, fullPage }
        });

        if (result.buffer) {
            return Buffer.from(result.buffer, 'base64');
        }
        return Buffer.from('');
    }

    /**
     * Get all network logs
     * @returns {Promise<Array<{request: Request, response?: Response}>>}
     */
    async getNetworkLogs() {
        const result = await this.browser._sendMessage({
            method: 'Page.getNetworkLogs',
            params: { pageId: this.id }
        });

        return (result.logs || []).map(log => new Request(log.request, log.response));
    }

    /**
     * Clear network logs
     * @returns {Promise<void>}
     */
    async clearNetworkLogs() {
        await this.browser._sendMessage({
            method: 'Page.clearNetworkLogs',
            params: { pageId: this.id }
        });
    }

    /**
     * Get all console logs
     * @returns {Promise<Array<{type: string, text: string, args: any[]}>>}
     */
    async getConsoleLogs() {
        const result = await this.browser._sendMessage({
            method: 'Page.getConsoleLogs',
            params: { pageId: this.id }
        });

        return result.logs || [];
    }

    /**
     * Clear console logs
     * @returns {Promise<void>}
     */
    async clearConsoleLogs() {
        await this.browser._sendMessage({
            method: 'Page.clearConsoleLogs',
            params: { pageId: this.id }
        });
    }

    /**
     * Enable/disable request interception
     * @param {boolean} enabled
     * @returns {Promise<void>}
     */
    async setRequestInterception(enabled) {
        await this.browser._sendMessage({
            method: 'Page.setRequestInterception',
            params: { pageId: this.id, enabled }
        });
    }
}

/**
 * Element Handle
 */
class ElementHandle extends EventEmitter {
    /**
     * @param {Page} page - The page instance
     * @param {Object} element - The element data from the browser
     */
    constructor(page, element) {
        super();
        this.page = page;
        this.element = element;
    }

    /**
     * Click the element
     * @param {Object} [options]
     * @param {'left' | 'right' | 'middle'} [options.button='left']
     * @param {number} [options.clickCount=1]
     * @returns {Promise<void>}
     */
    async click(options = {}) {
        const { button = 'left', clickCount = 1 } = options;
        
        await this.page.browser._sendMessage({
            method: 'ElementHandle.click',
            params: { pageId: this.page.id, elementId: this.element.id, button, clickCount }
        });
    }

    /**
     * Hover over the element
     * @returns {Promise<void>}
     */
    async hover() {
        await this.page.browser._sendMessage({
            method: 'ElementHandle.hover',
            params: { pageId: this.page.id, elementId: this.element.id }
        });
    }

    /**
     * Focus on the element
     * @returns {Promise<void>}
     */
    async focus() {
        await this.page.browser._sendMessage({
            method: 'ElementHandle.focus',
            params: { pageId: this.page.id, elementId: this.element.id }
        });
    }

    /**
     * Type text into the element
     * @param {string} text - Text to type
     * @param {Object} [options]
     * @param {number} [options.delay] - Delay between keystrokes in ms
     * @returns {Promise<void>}
     */
    async type(text, options = {}) {
        const { delay } = options;
        
        await this.page.browser._sendMessage({
            method: 'ElementHandle.type',
            params: { pageId: this.page.id, elementId: this.element.id, text, delay }
        });
    }

    /**
     * Fill the element
     * @param {string} value - Value to fill
     * @returns {Promise<void>}
     */
    async fill(value) {
        await this.page.browser._sendMessage({
            method: 'ElementHandle.fill',
            params: { pageId: this.page.id, elementId: this.element.id, value }
        });
    }

    /**
     * Select option(s) in a dropdown
     * @param {string | string[]} value - Value(s) to select
     * @returns {Promise<void>}
     */
    async select(value) {
        await this.page.browser._sendMessage({
            method: 'ElementHandle.select',
            params: { pageId: this.page.id, elementId: this.element.id, value }
        });
    }

    /**
     * Check the checkbox
     * @returns {Promise<void>}
     */
    async check() {
        await this.page.browser._sendMessage({
            method: 'ElementHandle.check',
            params: { pageId: this.page.id, elementId: this.element.id }
        });
    }

    /**
     * Uncheck the checkbox
     * @returns {Promise<void>}
     */
    async uncheck() {
        await this.page.browser._sendMessage({
            method: 'ElementHandle.uncheck',
            params: { pageId: this.page.id, elementId: this.element.id }
        });
    }

    /**
     * Upload file(s)
     * @param {string | string[]} files - File path(s)
     * @returns {Promise<void>}
     */
    async uploadFile(files) {
        await this.page.browser._sendMessage({
            method: 'ElementHandle.uploadFile',
            params: { pageId: this.page.id, elementId: this.element.id, files }
        });
    }

    /**
     * Get text content
     * @returns {Promise<string>}
     */
    async textContent() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.textContent',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.text || '';
    }

    /**
     * Get inner HTML
     * @returns {Promise<string>}
     */
    async innerHTML() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.innerHTML',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.html || '';
    }

    /**
     * Get inner text
     * @returns {Promise<string>}
     */
    async innerText() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.innerText',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.text || '';
    }

    /**
     * Get an attribute value
     * @param {string} attribute - Attribute name
     * @returns {Promise<?string>}
     */
    async getAttribute(attribute) {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.getAttribute',
            params: { pageId: this.page.id, elementId: this.element.id, attribute }
        });

        return result.value || null;
    }

    /**
     * Get bounding box
     * @returns {Promise<{x: number, y: number, width: number, height: number}>}
     */
    async boundingBox() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.boundingBox',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.box || { x: 0, y: 0, width: 0, height: 0 };
    }

    /**
     * Get computed styles
     * @returns {Promise<Object>}
     */
    async getComputedStyle() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.getComputedStyle',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.styles || {};
    }

    /**
     * Check if visible
     * @returns {Promise<boolean>}
     */
    async isVisible() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.isVisible',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.visible || false;
    }

    /**
     * Check if hidden
     * @returns {Promise<boolean>}
     */
    async isHidden() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.isHidden',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.hidden || false;
    }

    /**
     * Check if enabled
     * @returns {Promise<boolean>}
     */
    async isEnabled() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.isEnabled',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.enabled || false;
    }

    /**
     * Check if checked
     * @returns {Promise<boolean>}
     */
    async isChecked() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.isChecked',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.checked || false;
    }

    /**
     * Check if selected
     * @returns {Promise<boolean>}
     */
    async isSelected() {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.isSelected',
            params: { pageId: this.page.id, elementId: this.element.id }
        });

        return result.selected || false;
    }

    /**
     * Query selector (single element)
     * @param {string} selector - CSS selector
     * @returns {Promise<?ElementHandle>}
     */
    async $(selector) {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.querySelector',
            params: { pageId: this.page.id, elementId: this.element.id, selector }
        });

        if (result.element) {
            return new ElementHandle(this.page, result.element);
        }
        return null;
    }

    /**
     * Query selector (all elements)
     * @param {string} selector - CSS selector
     * @returns {Promise<ElementHandle[]>}
     */
    async $$(selector) {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.querySelectorAll',
            params: { pageId: this.page.id, elementId: this.element.id, selector }
        });

        return (result.elements || []).map(el => new ElementHandle(this.page, el));
    }

    /**
     * XPath selector
     * @param {string} expression - XPath expression
     * @returns {Promise<ElementHandle[]>}
     */
    async $x(expression) {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.xpath',
            params: { pageId: this.page.id, elementId: this.element.id, expression }
        });

        return (result.elements || []).map(el => new ElementHandle(this.page, el));
    }

    /**
     * Execute JavaScript in element context
     * @param {string} js - JavaScript code to execute
     * @param {any} [arg] - Argument to pass to the JavaScript function
     * @returns {Promise<any>}
     */
    async evaluate(js, arg) {
        const result = await this.page.browser._sendMessage({
            method: 'ElementHandle.evaluate',
            params: { pageId: this.page.id, elementId: this.element.id, js, arg }
        });

        return result.value;
    }

    /**
     * Dispose the element handle
     * @returns {Promise<void>}
     */
    async dispose() {
        // Element handles are automatically cleaned up
    }
}

/**
 * JS Handle
 */
class JSHandle {
    /**
     * @param {Page} page - The page instance
     * @param {Object} handle - The handle data from the browser
     */
    constructor(page, handle) {
        this.page = page;
        this.handle = handle;
    }

    /**
     * Execute JavaScript with this handle as `this`
     * @param {string} js - JavaScript code to execute
     * @param {any} [arg] - Argument to pass to the JavaScript function
     * @returns {Promise<any>}
     */
    async evaluate(js, arg) {
        const result = await this.page.browser._sendMessage({
            method: 'JSHandle.evaluate',
            params: { pageId: this.page.id, handleId: this.handle.id, js, arg }
        });

        return result.value;
    }

    /**
     * Get all properties of the object
     * @returns {Promise<Object>}
     */
    async getProperties() {
        const result = await this.page.browser._sendMessage({
            method: 'JSHandle.getProperties',
            params: { pageId: this.page.id, handleId: this.handle.id }
        });

        return result.properties || {};
    }

    /**
     * Get a specific property
     * @param {string} property - Property name
     * @returns {Promise<any>}
     */
    async getProperty(property) {
        const result = await this.page.browser._sendMessage({
            method: 'JSHandle.getProperty',
            params: { pageId: this.page.id, handleId: this.handle.id, property }
        });

        return result.value;
    }

    /**
     * Dispose the JS handle
     * @returns {Promise<void>}
     */
    async dispose() {
        await this.page.browser._sendMessage({
            method: 'JSHandle.dispose',
            params: { pageId: this.page.id, handleId: this.handle.id }
        });
    }
}

/**
 * Request
 */
class Request {
    /**
     * @param {Object} data - Request data
     */
    constructor(data) {
        this.url = data.url || '';
        this.method = data.method || 'GET';
        this.headers = data.headers || {};
        this.postData = data.postData ? Buffer.from(data.postData, 'base64') : null;
    }
}

/**
 * Response
 */
class Response {
    /**
     * @param {Object} data - Response data
     */
    constructor(data) {
        this.url = data.url || '';
        this.status = data.status || 0;
        this.statusText = data.statusText || '';
        this.headers = data.headers || {};
    }
}

// Export main classes
module.exports = {
    Browser,
    BrowserContext,
    Page,
    ElementHandle,
    JSHandle,
    Request,
    Response,
};
