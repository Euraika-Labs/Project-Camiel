import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { once } from "node:events";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { setTimeout as sleep } from "node:timers/promises";
import { fileURLToPath } from "node:url";

const [directory, browser, python = "python3"] = process.argv.slice(2);
if (!directory || !browser) {
    throw new Error("Usage: node verify_web_boot.mjs WEB_DIRECTORY CHROME [PYTHON]");
}

function browserPipe(chrome, errors) {
    const input = chrome.stdio[3];
    const output = chrome.stdio[4];
    const pending = new Map();
    let nextId = 0;
    let buffer = "";
    let closed;

    function fail(error) {
        closed = error;
        for (const { reject } of pending.values()) reject(error);
    }

    chrome.on("error", fail);
    chrome.on("close", code => fail(new Error("Chrome closed with exit code " + code)));
    input.on("error", fail);
    output.on("error", fail);
    output.setEncoding("utf8");
    output.on("data", chunk => {
        buffer += chunk;
        let end = buffer.indexOf("\0");
        while (end !== -1) {
            const message = JSON.parse(buffer.slice(0, end));
            buffer = buffer.slice(end + 1);
            if (message.method === "Runtime.exceptionThrown") {
                const detail = message.params.exceptionDetails;
                errors.push(detail.exception?.description ?? detail.text);
            }
            const request = pending.get(message.id);
            if (request) {
                if (message.error) request.reject(new Error(message.error.message));
                else request.resolve(message.result);
            }
            end = buffer.indexOf("\0");
        }
    });

    return (method, params = {}, sessionId) => new Promise((resolve, reject) => {
        if (closed) {
            reject(closed);
            return;
        }
        const id = ++nextId;
        function settle(callback, result) {
            clearTimeout(timer);
            pending.delete(id);
            callback(result);
        }
        const timer = setTimeout(() => settle(reject, new Error("Chrome did not answer " + method)), 8000);
        pending.set(id, {
            resolve: result => settle(resolve, result),
            reject: error => settle(reject, error),
        });
        input.write(JSON.stringify({ id, method, params, sessionId }) + "\0");
    });
}

async function stop(child) {
    if (!child?.pid || child.exitCode !== null || child.signalCode !== null) return;
    const closed = once(child, "close");
    child.kill();
    await closed;
}

async function bootUrl(server) {
    const lines = createInterface({ input: server.stdout });
    try {
        const [line] = await Promise.race([
            once(lines, "line", { signal: AbortSignal.timeout(8000) }),
            once(server, "close").then(([code]) => { throw new Error("Web server exited with code " + code); }),
        ]);
        const url = /^Camiel: (http:\/\/127\.0\.0\.1:\d+\/index\.html)$/.exec(line)?.[1];
        if (!url) throw new Error("Web server did not announce a loopback URL");
        return url;
    } finally {
        lines.close();
    }
}

function titleScreen() {
    const canvas = document.querySelector("canvas");
    const loading = document.getElementById("status") !== null;
    return {
        drewFrame: globalThis.camielSmokeDrewFrame === true,
        loading,
        inert: canvas?.inert,
        failure: document.getElementById("status-notice")?.textContent.trim(),
        width: canvas?.width,
        height: canvas?.height,
    };
}

async function waitForTitle(page, errors) {
    const expression = "(" + titleScreen.toString() + ")()";
    const deadline = Date.now() + 45000;
    let last;
    while (Date.now() < deadline) {
        const evaluated = await page("Runtime.evaluate", { expression, returnByValue: true });
        last = evaluated.result.value;
        if (errors.length) throw new Error(errors[0]);
        if (last?.failure) throw new Error(last.failure);
        if (last?.drewFrame && !last.loading && last.inert === false && last.width > 0 && last.height > 0) return last;
        await sleep(100);
    }
    throw new Error("Camiel did not draw and uncover the title screen. " + JSON.stringify(last));
}

const pack = createHash("sha256").update(await readFile(join(directory, "index.pck"))).digest("hex");
const profile = await mkdtemp(join(tmpdir(), "camiel-web-"));
const server = spawn(python, [fileURLToPath(new URL("./serve_web.py", import.meta.url)), directory, "--port", "0"], {
    stdio: ["ignore", "pipe", "inherit"],
    windowsHide: true,
});
let chrome;
let send;
const errors = [];
try {
    const url = await bootUrl(server);
    chrome = spawn(browser, [
        "--headless", "--no-first-run", "--disable-background-networking", "--no-proxy-server",
        "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
        "--user-data-dir=" + profile, "--remote-debugging-pipe", "about:blank",
    ], { stdio: ["ignore", "ignore", "ignore", "pipe", "pipe"], windowsHide: true });
    send = browserPipe(chrome, errors);
    const { product } = await send("Browser.getVersion");
    const { targetId } = await send("Target.createTarget", { url: "about:blank" });
    const { sessionId } = await send("Target.attachToTarget", { targetId, flatten: true });
    const page = (method, params) => send(method, params, sessionId);
    await page("Page.enable");
    await page("Runtime.enable");
    await page("Page.addScriptToEvaluateOnNewDocument", {
        source: 'addEventListener("camiel-first-frame", () => { globalThis.camielSmokeDrewFrame = true }, { once: true })',
    });
    const navigation = await page("Page.navigate", { url });
    if (navigation.errorText) throw new Error(navigation.errorText);
    const { width, height } = await waitForTitle(page, errors);
    console.log("Camiel drew the title screen in " + product + " at " + width + "x" + height);
    console.log("index.pck SHA256 " + pack);
} finally {
    if (send) await send("Browser.close").catch(() => undefined);
    await stop(chrome);
    await stop(server);
    await rm(profile, { recursive: true, force: true, maxRetries: 6, retryDelay: 100 });
}
