const vscode = require("vscode");
const cp = require("child_process");
const fs = require("fs");
const net = require("net");
const path = require("path");

let serverProcess = null;
let serverWorkspaceFolder = null;
let serverPort = null;
let webviewProvider = null;
let output = null;
const PORT_SCAN_LIMIT = 100;

function activate(context) {
  output = vscode.window.createOutputChannel("Markplane");
  webviewProvider = new MarkplaneWebviewProvider(context);

  context.subscriptions.push(output);
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider("markplane.workspace", webviewProvider, {
      webviewOptions: { retainContextWhenHidden: true }
    })
  );

  context.subscriptions.push(vscode.commands.registerCommand("markplane.initializeProject", initializeProject));
  context.subscriptions.push(vscode.commands.registerCommand("markplane.openFullView", openFullView));
  context.subscriptions.push(vscode.commands.registerCommand("markplane.restartServer", restartServer));
  context.subscriptions.push(vscode.commands.registerCommand("markplane.sync", () => runMarkplaneCommand(["sync"], true)));
  context.subscriptions.push(vscode.commands.registerCommand("markplane.check", () => runMarkplaneCommand(["check"], true)));

  const startup = getConfig().get("autoStart", true)
    ? ensureProjectAndServer(false)
    : Promise.resolve(false);

  startup
    .catch(showError)
    .finally(() => {
      if (getConfig().get("showOnStartup", true)) {
        vscode.commands.executeCommand("markplane.workspace.focus").then(undefined, showError);
      }
    });
}

function deactivate() {
  stopServer();
}

class MarkplaneWebviewProvider {
  constructor(context) {
    this.context = context;
    this.view = null;
  }

  resolveWebviewView(webviewView) {
    this.view = webviewView;
    webviewView.webview.options = {
      enableScripts: true,
      localResourceRoots: [this.context.extensionUri]
    };

    webviewView.webview.onDidReceiveMessage(async (message) => {
      try {
        if (message.command === "initialize") await initializeProject();
        if (message.command === "openFull") await openFullView();
        if (message.command === "start") await ensureProjectAndServer(true);
        if (message.command === "restart") await restartServer();
        if (message.command === "sync") await runMarkplaneCommand(["sync"], true);
        if (message.command === "check") await runMarkplaneCommand(["check"], true);
        this.refresh();
      } catch (error) {
        showError(error);
      }
    });

    this.refresh();
  }

  refresh() {
    if (!this.view) return;
    this.view.webview.html = renderSidebarHtml(this.view.webview);
  }
}

function getConfig() {
  return vscode.workspace.getConfiguration("markplane");
}

function getWorkspaceFolder() {
  const folders = vscode.workspace.workspaceFolders;
  if (!folders || folders.length === 0) return null;
  return folders[0].uri.fsPath;
}

function normalizeFsPath(fsPath) {
  const resolved = path.resolve(fsPath);
  return process.platform === "win32" ? resolved.toLowerCase() : resolved;
}

function getProjectName(workspaceFolder) {
  return path.basename(workspaceFolder || "Project");
}

function hasMarkplaneProject(workspaceFolder) {
  return !!workspaceFolder && fs.existsSync(path.join(workspaceFolder, ".markplane"));
}

function getMarkplaneExecutable() {
  return getConfig().get("executable", "markplane");
}

function getPort() {
  return getConfig().get("port", 4200);
}

function isServerRunningForWorkspace(workspaceFolder) {
  return !!serverProcess
    && !serverProcess.killed
    && !!serverPort
    && !!serverWorkspaceFolder
    && normalizeFsPath(serverWorkspaceFolder) === normalizeFsPath(workspaceFolder);
}

async function ensureProjectAndServer(interactive) {
  const workspaceFolder = getWorkspaceFolder();
  if (!workspaceFolder) {
    if (interactive) vscode.window.showInformationMessage("Open a workspace folder before using Markplane.");
    return false;
  }

  if (!hasMarkplaneProject(workspaceFolder)) {
    if (getConfig().get("autoInitialize", false)) {
      await initializeProject();
    } else if (interactive) {
      const choice = await vscode.window.showInformationMessage(
        "This workspace is not initialized for Markplane.",
        "Initialize Markplane"
      );
      if (choice === "Initialize Markplane") {
        await initializeProject();
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  await startServer();
  return true;
}

async function initializeProject() {
  const workspaceFolder = getWorkspaceFolder();
  if (!workspaceFolder) {
    vscode.window.showInformationMessage("Open a workspace folder before initializing Markplane.");
    return;
  }

  if (hasMarkplaneProject(workspaceFolder)) {
    vscode.window.showInformationMessage("Markplane is already initialized for this workspace.");
    await startServer();
    return;
  }

  const projectName = getProjectName(workspaceFolder);
  await runMarkplaneCommand(["init", "--name", projectName, "--empty"], true);
  await runMarkplaneCommand(["sync"], false);
  await startServer();
  vscode.window.showInformationMessage(`Initialized Markplane for ${projectName}.`);
}

async function openFullView() {
  const ready = await ensureProjectAndServer(true);
  if (!ready || !serverPort) return;

  const panel = vscode.window.createWebviewPanel(
    "markplaneFullView",
    `Markplane: ${getProjectName(getWorkspaceFolder())}`,
    vscode.ViewColumn.Beside,
    { enableScripts: true, retainContextWhenHidden: true }
  );
  panel.webview.html = renderFullHtml(panel.webview);
}

async function restartServer() {
  stopServer();
  await startServer();
  if (webviewProvider) webviewProvider.refresh();
}

async function startServer() {
  const workspaceFolder = getWorkspaceFolder();
  if (!workspaceFolder || !hasMarkplaneProject(workspaceFolder)) return;
  if (isServerRunningForWorkspace(workspaceFolder)) return;
  if (serverProcess && !serverProcess.killed) stopServer();

  const executable = getMarkplaneExecutable();
  const port = await findProjectPort(workspaceFolder);
  const portText = String(port);

  output.appendLine(`Starting Markplane web UI for ${workspaceFolder} on http://127.0.0.1:${portText}/graph`);
  serverWorkspaceFolder = workspaceFolder;
  serverPort = port;
  serverProcess = cp.spawn(executable, ["serve", "--port", portText], {
    cwd: workspaceFolder,
    shell: process.platform === "win32",
    windowsHide: true
  });

  serverProcess.stdout.on("data", (data) => output.append(data.toString()));
  serverProcess.stderr.on("data", (data) => output.append(data.toString()));
  serverProcess.on("exit", (code) => {
    output.appendLine(`Markplane server exited with code ${code}`);
    serverProcess = null;
    serverWorkspaceFolder = null;
    serverPort = null;
    if (webviewProvider) webviewProvider.refresh();
  });

  await wait(800);
  if (webviewProvider) webviewProvider.refresh();
}

function stopServer() {
  if (serverProcess && !serverProcess.killed) {
    output.appendLine("Stopping Markplane web UI.");
    serverProcess.kill();
  }
  serverProcess = null;
  serverWorkspaceFolder = null;
  serverPort = null;
}

function runMarkplaneCommand(args, showOutput) {
  const workspaceFolder = getWorkspaceFolder();
  if (!workspaceFolder) {
    return Promise.reject(new Error("Open a workspace folder before using Markplane."));
  }

  const executable = getMarkplaneExecutable();
  output.appendLine(`> ${executable} ${args.join(" ")}`);

  return new Promise((resolve, reject) => {
    const child = cp.spawn(executable, args, {
      cwd: workspaceFolder,
      shell: process.platform === "win32",
      windowsHide: true
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (data) => {
      stdout += data.toString();
      output.append(data.toString());
    });
    child.stderr.on("data", (data) => {
      stderr += data.toString();
      output.append(data.toString());
    });

    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) {
        if (showOutput && stdout.trim()) vscode.window.showInformationMessage(stdout.trim().split(/\r?\n/)[0]);
        resolve(stdout);
      } else {
        reject(new Error(stderr.trim() || `markplane exited with code ${code}`));
      }
    });
  });
}

function renderSidebarHtml(webview) {
  const nonce = getNonce();
  const workspaceFolder = getWorkspaceFolder();
  const initialized = hasMarkplaneProject(workspaceFolder);
  const running = workspaceFolder && isServerRunningForWorkspace(workspaceFolder);
  const port = running ? serverPort : getPort();
  const frameUrl = running ? `http://127.0.0.1:${serverPort}/graph` : null;
  const csp = getCsp(webview, nonce, port);

  if (!workspaceFolder) {
    return renderShell(csp, nonce, "No Workspace", "Open a workspace folder to use Markplane.", []);
  }

  if (!initialized) {
    return renderShell(csp, nonce, "Markplane", "This workspace is not initialized yet.", [
      ["initialize", "Initialize"]
    ]);
  }

  if (!frameUrl) {
    return renderShell(csp, nonce, "Markplane", "The project graph is starting.", [
      ["start", "Start"],
      ["restart", "Restart"]
    ]);
  }

  return `<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Security-Policy" content="${csp}">
  <style>${style()}</style>
</head>
<body>
  <div class="toolbar">
    <button data-command="openFull">Open</button>
    <button data-command="sync">Sync</button>
    <button data-command="check">Check</button>
    <button data-command="restart">Restart</button>
  </div>
  <iframe src="${frameUrl}" title="Markplane"></iframe>
  <script nonce="${nonce}">${script()}</script>
</body>
</html>`;
}

function renderFullHtml(webview) {
  const nonce = getNonce();
  const port = serverPort || getPort();
  const frameUrl = serverPort ? `http://127.0.0.1:${serverPort}/graph` : null;
  const csp = getCsp(webview, nonce, port);
  if (!frameUrl) {
    return renderShell(csp, nonce, "Markplane", "The project graph is not running yet.", [
      ["start", "Start"]
    ]);
  }
  return `<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Security-Policy" content="${csp}">
  <style>${style()}</style>
</head>
<body>
  <iframe class="full" src="${frameUrl}" title="Markplane"></iframe>
</body>
</html>`;
}

function renderShell(csp, nonce, title, message, buttons) {
  const buttonHtml = buttons.map(([command, label]) => `<button data-command="${command}">${label}</button>`).join("");
  return `<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Security-Policy" content="${csp}">
  <style>${style()}</style>
</head>
<body>
  <main class="empty">
    <h2>${escapeHtml(title)}</h2>
    <p>${escapeHtml(message)}</p>
    <div class="actions">${buttonHtml}</div>
  </main>
  <script nonce="${nonce}">${script()}</script>
</body>
</html>`;
}

function getCsp(webview, nonce, port) {
  return [
    "default-src 'none'",
    `style-src ${webview.cspSource} 'unsafe-inline'`,
    `script-src 'nonce-${nonce}'`,
    `frame-src http://127.0.0.1:${port} http://localhost:${port}`
  ].join("; ");
}

function style() {
  return `
    html, body { width: 100%; height: 100%; padding: 0; margin: 0; overflow: hidden; font-family: var(--vscode-font-family); color: var(--vscode-foreground); background: var(--vscode-editor-background); }
    .toolbar { display: flex; gap: 4px; padding: 6px; border-bottom: 1px solid var(--vscode-panel-border); background: var(--vscode-sideBar-background); }
    button { border: 1px solid var(--vscode-button-border, transparent); color: var(--vscode-button-foreground); background: var(--vscode-button-background); padding: 4px 8px; cursor: pointer; }
    button:hover { background: var(--vscode-button-hoverBackground); }
    iframe { width: 100%; height: calc(100vh - 36px); border: 0; background: white; }
    iframe.full { height: 100vh; }
    .empty { padding: 16px; }
    .empty h2 { font-size: 16px; margin: 0 0 8px; }
    .empty p { margin: 0 0 12px; line-height: 1.4; }
    .actions { display: flex; gap: 8px; flex-wrap: wrap; }
  `;
}

function script() {
  return `
    const vscode = acquireVsCodeApi();
    document.addEventListener('click', (event) => {
      const target = event.target.closest('[data-command]');
      if (!target) return;
      vscode.postMessage({ command: target.getAttribute('data-command') });
    });
  `;
}

function getNonce() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let nonce = "";
  for (let i = 0; i < 32; i++) nonce += chars.charAt(Math.floor(Math.random() * chars.length));
  return nonce;
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#39;"
  })[char]);
}

async function findProjectPort(workspaceFolder) {
  const basePort = getPort();
  const startOffset = stableHash(normalizeFsPath(workspaceFolder)) % PORT_SCAN_LIMIT;

  for (let i = 0; i < PORT_SCAN_LIMIT; i++) {
    const offset = (startOffset + i) % PORT_SCAN_LIMIT;
    const port = basePort + offset;
    if (await isPortAvailable(port)) return port;
  }

  throw new Error(`No available Markplane port found from ${basePort} to ${basePort + PORT_SCAN_LIMIT - 1}.`);
}

function stableHash(value) {
  let hash = 2166136261;
  for (let i = 0; i < value.length; i++) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function isPortAvailable(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.once("error", () => resolve(false));
    server.once("listening", () => {
      server.close(() => resolve(true));
    });
    server.listen(port, "127.0.0.1");
  });
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function showError(error) {
  const message = error && error.message ? error.message : String(error);
  output.appendLine(message);
  vscode.window.showErrorMessage(`Markplane: ${message}`);
}

module.exports = { activate, deactivate };
