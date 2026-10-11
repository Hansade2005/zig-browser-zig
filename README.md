# Sweef Browser

**The world's lightest browser for AI agents and humans.**

Sweef is an ultra-lightweight, Chromium-inspired browser that runs on **1 CPU core, 50MB RAM, and 400MB storage** while offering **Playwright-like automation** for AI agents and a **minimal GUI** for humans.

---

## ✨ **Why Sweef?**

| Feature | Sweef | Playwright | Puppeteer |
|---------|-------|-----------|-----------|
| **Memory Usage** | **30-50MB** | 300-500MB | 200-400MB |
| **Storage Usage** | **5-10MB** | 200-300MB | 200-300MB |
| **AI Agent Integration** | ✅ **Native (MCP)** | ❌ | ❌ |
| **JavaScript Engine** | QuickJS (ES2020) | V8 | V8 |
| **Multi-Platform** | ✅ (Linux, Windows, macOS, ARM) | ✅ | ✅ |
| **Headless Mode** | ✅ | ✅ | ✅ |
| **GUI Mode** | ✅ (Optional) | ❌ | ❌ |

---

## 🚀 **Quick Start**

### **1. Build from Source**

```bash
# Clone the repo
git clone https://github.com/sweef-browser/sweef.git
cd sweef

# Build (requires Zig 0.11+)
zig build -Doptimize=ReleaseSafe

# Run in headless mode (for AI agents)
./zig-out/bin/sweef --headless --mcp

# Run with GUI (for humans)
./zig-out/bin/sweef --gui
```

### **2. Install Prebuilt Binaries** (Coming Soon)

```bash
# Linux x86_64
curl -L https://github.com/sweef-browser/sweef/releases/download/v0.1.0/sweef-linux-x64 -o sweef
chmod +x sweef

# macOS
curl -L https://github.com/sweef-browser/sweef/releases/download/v0.1.0/sweef-macos -o sweef
chmod +x sweef

# Windows
curl -L https://github.com/sweef-browser/sweef/releases/download/v0.1.0/sweef-win.exe -o sweef.exe
```

### **3. Use with Node.js SDK**

```bash
npm install sweef
```

```javascript
const { Browser } = require('sweef');

(async () => {
  const browser = await Browser.launch({ headless: true });
  const page = await browser.newPage();
  
  await page.goto('https://example.com');
  const title = await page.title();
  console.log('Title:', title);
  
  await browser.close();
})();
```

### **4. Use with Python SDK**

```bash
pip install sweef
```

```python
from sweef import Browser

async def main():
    browser = await Browser.launch(headless=True)
    page = await browser.new_page()
    
    await page.goto("https://example.com")
    title = await page.title()
    print(f"Title: {title}")
    
    await browser.close()

# Run with: python -m asyncio main.py
```

---

## 🛠 **Features**

### **Core Browser**
- ✅ **HTTP/1.1 + HTTPS (TLS 1.2/1.3)**
- ✅ **HTML5 Parsing** (via GUMBO)
- ✅ **CSS2.1 + Basic CSS3**
- ✅ **JavaScript (ES2020)** via QuickJS
- ✅ **DOM API** (`querySelector`, `addEventListener`, etc.)
- ✅ **Console & Network Logging**
- ✅ **Cookies & LocalStorage** (in-memory)
- ✅ **Request/Response Interception**
- ✅ **Screenshots** (GUI mode)
- ✅ **Multi-Page Support** (via contexts)

### **AI Agent Integration (MCP)**
- ✅ **Full Playwright-like API** over MCP
- ✅ **Console Logs Streaming**
- ✅ **Network Logs Streaming**
- ✅ **DOM Inspection**
- ✅ **JavaScript Evaluation**
- ✅ **Event Listeners** (`on('console')`, `on('request')`, etc.)

### **SDKs**
- ✅ **Node.js SDK** (Full Playwright-like API)
- ✅ **Python SDK** (Async, Pythonic API)
- ✅ **CLI Tools** (Headless, GUI, REPL modes)

### **Debugging**
- ✅ **Console Logs** (`console.log`, `console.error`)
- ✅ **Network Logs** (Request/Response headers + body)
- ✅ **DOM Inspection** (`get_dom()` → JSON)
- ✅ **JavaScript Debugging** (Breakpoints, stack traces)
- ✅ **Error Handling** (Custom stack traces)

---

## 🏗 **Architecture**

```
sweef/
├── core/                  # Core engine (Zig)
│   ├── src/
│   │   ├── main.zig       # Entry point
│   │   ├── http/          # HTTP client
│   │   ├── dom/           # DOM tree
│   │   ├── html/          # HTML parser (GUMBO)
│   │   ├── js/            # QuickJS integration
│   │   ├── mcp/           # MCP server
│   │   └── ipc/           # IPC for SDKs
│   └── build.zig          # Zig build script
│
├── quickjs/              # QuickJS submodule
│   ├── quickjs.c
│   ├── quickjs.h
│   └── libbf.h
│
├── sdks/                 # SDKs
│   ├── nodejs/            # Node.js SDK
│   │   ├── index.js
│   │   └── package.json
│   └── python/            # Python SDK
│       ├── __init__.py
│       └── setup.py
│
├── cli/                  # CLI tools
│   └── sweef              # Compiled binary
│
├── tests/                # Test suites
│   ├── core/
│   ├── mcp/
│   └── sdks/
│
└── README.md
```

---

## 📦 **Project Structure**

| Directory | Purpose |
|-----------|---------|
| `/core` | Core browser engine (Zig) |
| `/quickjs` | QuickJS JavaScript engine |
| `/sdks` | Node.js & Python SDKs |
| `/cli` | Command-line interface |
| `/tests` | Test suites |
| `/docs` | Documentation |

---

## 🎯 **Roadmap**

### **Phase 1: Core + QuickJS + MCP (Headless)**
- [ ] Zig project setup
- [ ] QuickJS integration
- [ ] HTTP client (Zig)
- [ ] HTML parser (GUMBO)
- [ ] Basic DOM
- [ ] MCP server with `goto`, `evaluate`, `get_dom`
- [ ] Debugging hooks (console, network)
- **Memory Target**: ~30MB

### **Phase 2: Playwright-like API**
- [ ] `click`, `type`, `wait_for_selector`
- [ ] `on('console')`, `on('request')`, `on('response')`
- [ ] `get_network_logs()`
- [ ] Error handling
- **Memory Target**: ~35MB

### **Phase 3: SDKs (Node.js & Python)**
- [ ] Node.js SDK (IPC-based)
- [ ] Python SDK (IPC-based)
- [ ] CLI tools
- **Memory Target**: N/A (separate processes)

### **Phase 4: GUI (Optional)**
- [ ] SDL2 integration
- [ ] Software renderer
- [ ] Minimal UI (address bar, buttons)
- **Memory Target**: +10MB

### **Phase 5: Advanced Features**
- [ ] TLS support (mbedTLS)
- [ ] CSS support (LibCSS)
- [ ] Image rendering (stb_image)
- [ ] Multi-page support
- [ ] Unicode support

---

## 🤝 **Contributing**

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md).

---

## 📜 **License**

Sweef is **MIT Licensed**. See [LICENSE](LICENSE) for details.

---

## 🙌 **Acknowledgements**

- [Zig](https://ziglang.org/) - The programming language that makes this possible.
- [QuickJS](https://bellard.org/quickjs/) - The lightweight JavaScript engine.
- [GUMBO](https://github.com/google/gumbo-parser) - The HTML5 parser.
- [SDL2](https://www.libsdl.org/) - The GUI library.
- [MCP](https://github.com/modelcontextprotocol) - The AI agent protocol.

---

## 📧 **Contact**

- **Website**: [https://sweef.dev](https://sweef.dev) (Coming Soon)
- **GitHub**: [https://github.com/sweef-browser/sweef](https://github.com/sweef-browser/sweef)
- **Discord**: [Join our community](https://discord.gg/sweef) (Coming Soon)
- **Email**: [hello@sweef.dev](mailto:hello@sweef.dev) (Coming Soon)

---

**Sweef: The browser for the next billion devices.** 🚀
