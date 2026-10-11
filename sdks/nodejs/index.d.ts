// Sweef Browser - Node.js SDK Type Definitions
// Ultra-lightweight browser for AI agents and humans

export interface BrowserLaunchOptions {
    headless?: boolean;
    debug?: boolean;
    timeout?: number;
    slowMo?: number;
    userAgent?: string;
    viewport?: {
        width: number;
        height: number;
    };
    args?: string[];
}

export interface BrowserContextOptions {
    userAgent?: string;
    viewport?: {
        width: number;
        height: number;
    };
    javaScriptEnabled?: boolean;
    bypassCSP?: boolean;
}

export interface Browser {
    on(event: 'close', listener: () => void): this;
    on(event: 'debug', listener: (message: string) => void): this;
    on(event: 'error', listener: (error: Error) => void): this;

    newContext(options?: BrowserContextOptions): Promise<BrowserContext>;
    contexts(): Promise<BrowserContext[]>;
    close(): Promise<void>;
    version(): Promise<string>;
}

export interface BrowserContext {
    on(event: string, listener: (...args: any[]) => void): this;

    id: number;
    browser: Browser;
    options: BrowserContextOptions;

    newPage(): Promise<Page>;
    pages(): Promise<Page[]>;
    close(): Promise<void>;
    addCookies(cookies: Array<{ name: string; value: string; url?: string }>): Promise<void>;
    cookies(urls?: string[]): Promise<Array<{ name: string; value: string; url: string }>>;
    clearCookies(): Promise<void>;
    setOffline(offline: boolean): Promise<void>;
    setGeolocation(geolocation: { latitude: number; longitude: number }): Promise<void>;
    setUserAgent(userAgent: string): Promise<void>;
    setViewport(viewport: { width: number; height: number }): Promise<void>;
}

export interface Page {
    on(event: 'console', listener: (message: any) => void): this;
    on(event: 'request', listener: (request: Request) => void): this;
    on(event: 'response', listener: (response: Response) => void): this;
    on(event: 'load', listener: () => void): this;
    on(event: 'domcontentloaded', listener: () => void): this;
    on(event: 'pageerror', listener: (error: Error) => void): this;
    on(event: string, listener: (...args: any[]) => void): this;

    id: number;
    browser: Browser;
    context: BrowserContext;
    closed: boolean;

    goto(url: string, options?: { waitUntil?: 'load' | 'domcontentloaded' | 'networkidle'; timeout?: number }): Promise<void>;
    reload(options?: { waitUntil?: 'load' | 'domcontentloaded' | 'networkidle'; timeout?: number }): Promise<void>;
    goBack(options?: { waitUntil?: 'load' | 'domcontentloaded' | 'networkidle'; timeout?: number }): Promise<void>;
    goForward(options?: { waitUntil?: 'load' | 'domcontentloaded' | 'networkidle'; timeout?: number }): Promise<void>;
    close(): Promise<void>;
    title(): Promise<string>;
    url(): Promise<string>;
    content(): Promise<string>;
    setContent(html: string): Promise<void>;
    click(selector: string, options?: { button?: 'left' | 'right' | 'middle'; clickCount?: number }): Promise<void>;
    dblclick(selector: string): Promise<void>;
    hover(selector: string): Promise<void>;
    focus(selector: string): Promise<void>;
    type(selector: string, text: string, options?: { delay?: number }): Promise<void>;
    fill(selector: string, value: string): Promise<void>;
    select(selector: string, value: string | string[]): Promise<void>;
    check(selector: string): Promise<void>;
    uncheck(selector: string): Promise<void>;
    press(key: string): Promise<void>;
    setInputFiles(selector: string, files: string | string[]): Promise<void>;
    waitForSelector(selector: string, options?: { state?: 'visible' | 'hidden' | 'attached' | 'detached'; timeout?: number }): Promise<ElementHandle | null>;
    waitForFunction(js: string, options?: { timeout?: number; polling?: 'raf' | 'mutation' | number }): Promise<any>;
    waitForNavigation(options?: { waitUntil?: 'load' | 'domcontentloaded' | 'networkidle'; timeout?: number }): Promise<void>;
    waitForLoadState(state: 'load' | 'domcontentloaded' | 'networkidle', options?: { timeout?: number }): Promise<void>;
    waitForRequest(url: string, options?: { timeout?: number }): Promise<Request>;
    waitForResponse(url: string, options?: { timeout?: number }): Promise<Response>;
    waitForTimeout(ms: number): Promise<void>;
    evaluate(js: string, arg?: any): Promise<any>;
    evaluateHandle(js: string): Promise<JSHandle>;
    $(selector: string): Promise<ElementHandle | null>;
    $$(selector: string): Promise<ElementHandle[]>;
    $x(expression: string): Promise<ElementHandle[]>;
    textContent(selector: string): Promise<string>;
    innerHTML(selector: string): Promise<string>;
    innerText(selector: string): Promise<string>;
    getAttribute(selector: string, attribute: string): Promise<string | null>;
    boundingBox(selector: string): Promise<{ x: number; y: number; width: number; height: number }>;
    getComputedStyle(selector: string): Promise<Record<string, string>>;
    isVisible(selector: string): Promise<boolean>;
    isHidden(selector: string): Promise<boolean>;
    isEnabled(selector: string): Promise<boolean>;
    isChecked(selector: string): Promise<boolean>;
    isSelected(selector: string): Promise<boolean>;
    screenshot(options?: { path?: string; type?: 'png' | 'jpeg'; quality?: number; fullPage?: boolean }): Promise<Buffer>;
    getNetworkLogs(): Promise<Array<{ request: Request; response?: Response }>>;
    clearNetworkLogs(): Promise<void>;
    getConsoleLogs(): Promise<Array<{ type: string; text: string; args: any[] }>>;
    clearConsoleLogs(): Promise<void>;
    setRequestInterception(enabled: boolean): Promise<void>;
}

export interface ElementHandle {
    on(event: string, listener: (...args: any[]) => void): this;

    page: Page;
    element: any;

    click(options?: { button?: 'left' | 'right' | 'middle'; clickCount?: number }): Promise<void>;
    hover(): Promise<void>;
    focus(): Promise<void>;
    type(text: string, options?: { delay?: number }): Promise<void>;
    fill(value: string): Promise<void>;
    select(value: string | string[]): Promise<void>;
    check(): Promise<void>;
    uncheck(): Promise<void>;
    uploadFile(files: string | string[]): Promise<void>;
    textContent(): Promise<string>;
    innerHTML(): Promise<string>;
    innerText(): Promise<string>;
    getAttribute(attribute: string): Promise<string | null>;
    boundingBox(): Promise<{ x: number; y: number; width: number; height: number }>;
    getComputedStyle(): Promise<Record<string, string>>;
    isVisible(): Promise<boolean>;
    isHidden(): Promise<boolean>;
    isEnabled(): Promise<boolean>;
    isChecked(): Promise<boolean>;
    isSelected(): Promise<boolean>;
    $(selector: string): Promise<ElementHandle | null>;
    $$(selector: string): Promise<ElementHandle[]>;
    $x(expression: string): Promise<ElementHandle[]>;
    evaluate(js: string, arg?: any): Promise<any>;
    dispose(): Promise<void>;
}

export interface JSHandle {
    page: Page;
    handle: any;

    evaluate(js: string, arg?: any): Promise<any>;
    getProperties(): Promise<Record<string, any>>;
    getProperty(property: string): Promise<any>;
    dispose(): Promise<void>;
}

export interface Request {
    url: string;
    method: string;
    headers: Record<string, string>;
    postData: Buffer | null;
}

export interface Response {
    url: string;
    status: number;
    statusText: string;
    headers: Record<string, string>;
}

export interface Sweef {
    Browser: typeof import('./index').Browser;
    BrowserContext: typeof import('./index').BrowserContext;
    Page: typeof import('./index').Page;
    ElementHandle: typeof import('./index').ElementHandle;
    JSHandle: typeof import('./index').JSHandle;
    Request: typeof import('./index').Request;
    Response: typeof import('./index').Response;
}

declare const sweef: Sweef;
export = sweef;
export default sweef;
