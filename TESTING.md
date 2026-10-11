# Sweef Browser - Testing Guide

This guide shows you how to test Sweef Browser on your local machine.

---

## 🚀 Quick Start

### 1. Install Zig

Sweef Browser requires **Zig 0.11.0 or later**. Install it from the [official downloads page](https://ziglang.org/download/):

**Linux/macOS:**
```bash
# Download and install Zig 0.11.0
curl -L https://ziglang.org/builds/zig-linux-x86_64-0.11.0.tar.xz -o zig.tar.xz
tar -xf zig.tar.xz
sudo mv zig-linux-x86_64-0.11.0 /usr/local/zig
echo 'export PATH="/usr/local/zig:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
zig version
```

**Windows:**
Download the `.zip` file from [Zig downloads](https://ziglang.org/download/) and add it to your PATH.

---

## 🔨 Build the Core Engine

```bash
# Navigate to the core directory
cd sweef/core

# Build in development mode (faster, no optimizations)
zig build

# Build in release mode (optimized)
zig build -Doptimize=ReleaseSafe

# Build with debugging
zig build -Doptimize=Debug
```

Expected output:
```
info: Installing sweef to /path/to/sweef/core/zig-out/bin
```

---

## 🧪 Run Tests

```bash
# Run the test suite
cd sweef/core
zig build test

# Or run tests directly
zig test src/test.zig
```

Expected output:
```
Test 1: DOM Parser
✅ DOM Parser: Parsed HTML successfully
Test 2: DOM Query Selector
✅ DOM Query Selector: Found title element
Test 3: DOM to JSON
✅ DOM to JSON: Serialized successfully
Test 4: Logger
✅ Logger: All log levels work
All tests completed!
```

---

## ▶️ Run the Browser

### Headless Mode (for AI agents)
```bash
# Run MCP server (for AI agents)
./zig-out/bin/sweef --headless --mcp

# Run with custom port
./zig-out/bin/sweef --headless --mcp --mcp-port 3000

# Run with debug logging
./zig-out/bin/sweef --headless --debug
```

### GUI Mode (for humans)
```bash
# Run with SDL2 GUI
./zig-out/bin/sweef --gui
```

### REPL Mode (interactive)
```bash
# Start interactive REPL
./zig-out/bin/sweef --repl

# In REPL, try these commands:
goto https://example.com
click button#submit
type input[name=q] hello world
evaluate () => document.title
get_dom
get_network_logs
exit
```

### Open a URL
```bash
./zig-out/bin/sweef --url https://example.com
```

### Run a Script
```bash
# Create a test script (test.js)
const { Browser } = require('./sdks/nodejs');

(async () => {
  const browser = await Browser.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('https://example.com');
  console.log('Title:', await page.title());
  await browser.close();
})();

# Run the script
./zig-out/bin/sweef --script test.js
```

---

## 📦 Install SDKs

### Node.js SDK

```bash
# Navigate to Node.js SDK
cd sdks/nodejs

# Install dependencies
npm install

# Run a test
node -e "
const { Browser } = require('./index');
(async () => {
  const browser = await Browser.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('https://example.com');
  console.log('Title:', await page.title());
  await browser.close();
})();
"
```

### Python SDK

```bash
# Navigate to Python SDK
cd sdks/python

# Install in development mode
pip install -e .

# Run a test
python3 -c "
import asyncio
from sweef import Browser

async def main():
    browser = await Browser.launch(headless=True)
    page = await browser.new_page()
    await page.goto('https://example.com')
    print('Title:', await page.title())
    await browser.close()

asyncio.run(main())
"
```

---

## 🐳 Use Docker

If you don't want to install Zig locally, use Docker:

```bash
# Build the Docker image
docker build -t sweef-browser .

# Run the browser in Docker
docker run -it --rm sweef-browser

# Or run with ports exposed for MCP
docker run -it --rm -p 3000:3000 sweef-browser --headless --mcp
```

---

## 🐛 Debugging

### Enable Debug Logging
```bash
./zig-out/bin/sweef --debug
```

### Check Memory Usage
```bash
# Run with memory profiling
zig build -Doptimize=Debug && ./zig-out/bin/sweef --headless --mcp

# Use system tools to monitor
ps aux | grep sweef
```

### Common Issues

#### 1. Zig not found
```
Error: zig: command not found
```
**Solution:** Install Zig and add it to your PATH.

#### 2. Missing QuickJS
```
Error: Cannot find QuickJS headers
```
**Solution:** Initialize git submodules:
```bash
git submodule update --init --recursive
```

#### 3. Missing SDL2 (for GUI mode)
```
Error: Cannot find SDL2
```
**Solution:** Install SDL2:
```bash
# Ubuntu/Debian
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev

# macOS
brew install sdl2 sdl2_image sdl2_ttf
```

#### 4. Missing mbedTLS (for HTTPS)
```
Error: Cannot find mbedtls
```
**Solution:** Install mbedTLS:
```bash
# Ubuntu/Debian
sudo apt-get install libmbedtls-dev

# macOS
brew install mbed-tls
```

---

## 📊 Performance Testing

### Memory Usage Test
```bash
# Run and monitor memory
/usr/bin/time -v ./zig-out/bin/sweef --headless --url https://example.com
```

### Speed Test
```bash
# Time page load
TIMESTART=$(date +%s.%N)
./zig-out/bin/sweef --headless --url https://example.com
TIMEEND=$(date +%s.%N)
echo "Time: $(echo "$TIMEEND - $TIMESTART" | bc) seconds"
```

---

## 🤖 Test MCP Integration

### Connect with an AI Agent
```python
# test_mcp.py
import asyncio
import websockets
import json

async def test_mcp():
    uri = "ws://localhost:3000"
    async with websockets.connect(uri) as websocket:
        # Send a request
        request = {
            "id": 1,
            "method": "page.goto",
            "params": {"pageId": 1, "url": "https://example.com"}
        }
        await websocket.send(json.dumps(request))
        
        # Receive response
        response = await websocket.recv()
        print(f"Response: {response}")

asyncio.get_event_loop().run_until_complete(test_mcp())
```

---

## 📝 Expected Results

| Test | Expected Output |
|------|----------------|
| Build | `info: Installing sweef to /path/to/sweef/core/zig-out/bin` |
| Test Suite | All tests pass with ✅ |
| Headless Mode | `Sweef MCP Server running on port 3000` |
| GUI Mode | SDL2 window opens |
| REPL Mode | Interactive prompt appears |
| Node.js SDK | Successfully connects and runs commands |
| Python SDK | Successfully connects and runs commands |

---

## 🙌 Contributing

If you find any issues or want to add features:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make test`
5. Submit a pull request

---

## 📚 Additional Resources

- [Zig Documentation](https://ziglang.org/documentation/master/)
- [QuickJS Documentation](https://bellard.org/quickjs/)
- [MCP Protocol](https://github.com/modelcontextprotocol)
- [Playwright Documentation](https://playwright.dev/)
