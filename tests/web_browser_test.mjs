// Punto 3: prueba la exportacion web en un Chrome real (sin dependencias:
// usa el protocolo DevTools con el WebSocket que ya trae Node 22+).
//
//   node tests/web_browser_test.mjs <fase> <carpeta_capturas> <carpeta_perfil>
//
// fases:
//   nueva   -> menu, COMENZAR JUEGO, NORMAL, 3x SIGUIENTE, nivel 1 (guarda)
//   cargar  -> NUEVO navegador con el mismo perfil (como cerrar la pestaña y
//              volver): CARGAR PARTIDA tiene que estar activo y cargar el nivel
//   celular -> 844x390 tactil: menu + empezar a jugar con toques
//   itch    -> como "nueva" pero con el juego ADENTRO de un iframe de otro
//              origen (igual que itch.io: allow="autoplay; fullscreen *")
//   iphone  -> 844x390 tactil con el user agent de Safari de iPhone: el boton
//              de pantalla completa NO tiene que aparecer
// En nueva/itch/celular se aprieta PANTALLA COMPLETA y se mira que el
// navegador realmente entre (y en compu, que vuelva a salir).
// Todas arrancan por "TOCA PARA EMPEZAR" y miden el audio que REALMENTE
// sale (un AnalyserNode metido antes de la salida de cada AudioContext):
// antes del toque tiene que estar en silencio/suspendido, despues tiene que
// sonar la musica, y en el nivel un salto tiene que sonar (efecto).
// Chrome corre SIN --autoplay-policy=no-user-gesture-required: bloquea el
// audio hasta el primer gesto, como en un navegador de verdad.
// El servidor local tiene que estar sirviendo export_web/ en el puerto 8060.

import { spawn } from "node:child_process";
import { writeFileSync, mkdirSync } from "node:fs";
import { createServer } from "node:http";

const [phase, shotDir, profile] = process.argv.slice(2);
const CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe";
const PORT = 9333;
const URL = "http://localhost:8060/index.html";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
mkdirSync(shotDir, { recursive: true });

// Pagina "tipo itch.io": otro origen (127.0.0.1:8061) con el juego en un
// iframe de 960x540, con los mismos permisos que pone itch.
const IFRAME = { x: 160, y: 90, w: 960, h: 540 };
const itchServer = createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(`<!DOCTYPE html><html><body style="margin:0;background:#333">
<iframe id="game" src="${"http://localhost:8060/index.html"}" allow="autoplay; fullscreen *; gamepad" allowfullscreen
 style="position:absolute;left:${IFRAME.x}px;top:${IFRAME.y}px;width:${IFRAME.w}px;height:${IFRAME.h}px;border:0"></iframe>
</body></html>`);
});
if (phase === "itch") await new Promise((r) => itchServer.listen(8061, r));

const chrome = spawn(CHROME, [
  "--headless=new", `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`,
  "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist",
  "--window-size=1280,720",
  // itch: el iframe de otro origen en el mismo proceso, para poder evaluar
  // adentro (no cambia permisos ni la regla de pantalla completa).
  ...(phase === "itch" ? ["--disable-site-isolation-trials", "--disable-features=IsolateOrigins,site-per-process"] : []),
  "--no-first-run", "--no-default-browser-check", "about:blank",
], { stdio: "ignore" });

let target;
for (let i = 0; i < 60 && !target; i++) {
  await sleep(500);
  try {
    const list = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
    target = list.find((t) => t.type === "page");
  } catch {}
}
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener("open", r));
let nextId = 1;
const pending = new Map();
const logs = [];
ws.addEventListener("message", (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) {
    pending.get(msg.id)(msg);
    pending.delete(msg.id);
  } else if (msg.method === "Runtime.consoleAPICalled") {
    logs.push(msg.params.type + ": " + msg.params.args.map((a) => a.value ?? a.description).join(" "));
  } else if (msg.method === "Runtime.executionContextCreated") {
    contexts.push(msg.params.context);
  } else if (msg.method === "Runtime.exceptionThrown") {
    logs.push("EXCEPTION: " + JSON.stringify(msg.params.exceptionDetails.text));
  }
});
const send = (method, params = {}) => new Promise((resolve) => {
  const id = nextId++;
  pending.set(id, resolve);
  ws.send(JSON.stringify({ id, method, params }));
});
// En la fase itch el juego vive en el iframe: se evalua en SU contexto.
const contexts = [];
let gameCtx;
const evaluate = async (expr, ctx = gameCtx) => (await send("Runtime.evaluate", { expression: expr, awaitPromise: true, returnByValue: true, ...(ctx ? { contextId: ctx } : {}) })).result?.result?.value;
const evaluateTop = (expr) => evaluate(expr, null);
const canvasInfo = () => evaluate("(() => { const c = document.getElementById('canvas'); return `inner=${innerWidth}x${innerHeight} canvas=${c.width}x${c.height} css=${c.style.width}x${c.style.height} client=${c.clientWidth}x${c.clientHeight}`; })()");
const shot = async (name) => {
  console.log("CANVAS", name, await canvasInfo());
  const r = await send("Page.captureScreenshot", { format: "png" });
  writeFileSync(`${shotDir}/shot3_web_${name}.png`, Buffer.from(r.result.data, "base64"));
  console.log("GUARDADA shot3_web_" + name);
};
// Coordenadas de diseño 1280x720 -> pagina (en itch, adentro del iframe).
const P = (x, y) => phase === "itch" ? [IFRAME.x + x * IFRAME.w / 1280, IFRAME.y + y * IFRAME.h / 720] : [x, y];
const click = async (x, y) => {
  [x, y] = P(x, y);
  for (const type of ["mousePressed", "mouseReleased"]) {
    await send("Input.dispatchMouseEvent", { type, x, y, button: "left", clickCount: 1 });
    await sleep(80);
  }
};
const tap = async (x, y) => {
  await send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [{ x, y }] });
  await sleep(120);
  await send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
};

await send("Page.enable");
await send("Runtime.enable");
await send("Page.addScriptToEvaluateOnNewDocument", { source: `(() => {
  const list = window.__peaks = [];
  const connect = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function (dest, ...rest) {
    if (dest instanceof AudioDestinationNode) {
      const ctx = this.context;
      if (!ctx.__an) {
        ctx.__an = ctx.createAnalyser();
        ctx.__an.fftSize = 2048;
        connect.call(ctx.__an, dest);
        list.push({ ctx, an: ctx.__an, peak: 0 });
      }
      return connect.call(this, ctx.__an, ...rest);
    }
    return connect.call(this, dest, ...rest);
  };
  const buf = new Float32Array(2048);
  setInterval(() => {
    for (const p of list) {
      p.an.getFloatTimeDomainData(buf);
      for (const v of buf) p.peak = Math.max(p.peak, Math.abs(v));
    }
  }, 40);
  window.__readPeaks = () => {
    const r = list.map((p, i) => i + ":" + p.ctx.state + ":pico=" + p.peak.toFixed(4)).join("  ");
    for (const p of list) p.peak = 0;
    return r || "(ningun AudioContext conectado a la salida)";
  };
})();` });
const mobile = phase === "celular" || phase === "iphone";
if (phase === "iphone") await send("Emulation.setUserAgentOverride", { userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1" });
await send("Emulation.setDeviceMetricsOverride", mobile
  ? { width: 844, height: 390, deviceScaleFactor: 1, mobile: true, screenOrientation: { type: "landscapePrimary", angle: 90 } }
  : { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
if (mobile) await send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 });
await send("Page.navigate", { url: phase === "itch" ? "http://127.0.0.1:8061/" : URL });
if (phase === "itch") {
  await sleep(3000);
  const tree = (await send("Page.getFrameTree")).result.frameTree;
  const child = tree.childFrames[0].frame.id;
  gameCtx = contexts.find((c) => c.auxData?.frameId === child && c.auxData?.isDefault)?.id;
  console.log("IFRAME de otro origen:", tree.childFrames[0].frame.url, "contexto", gameCtx);
}

// Espera a que Godot termine de cargar (el shell oculta #status).
let loaded = false;
for (let i = 0; i < 240 && !loaded; i++) {
  await sleep(500);
  loaded = await evaluate("(() => { const s = document.getElementById('status'); return !!document.querySelector('canvas') && (!s || s.style.display === 'none' || s.style.visibility === 'hidden' || getComputedStyle(s).display === 'none'); })()");
}
console.log("CARGADO", loaded, "fullscreenEnabled=", await evaluate("document.fullscreenEnabled"));
await sleep(6000);
const press = mobile ? tap : click;
const audio = async (label) => {
  console.log("AUDIO", label, await evaluate("window.__readPeaks && window.__readPeaks()"),
    "| musica:", await evaluate("window.LukeWeb && LukeWeb.musicState()"));
};

// "TOCA PARA EMPEZAR": nada suena hasta el primer toque/clic.
await shot(phase + "_toca_para_empezar");
await sleep(1500);
await audio("antes del toque");
await press(mobile ? 422 : 640, mobile ? 195 : 360);
await sleep(4000);
await audio("despues del toque (menu)");

const fsState = () => evaluateTop("document.fullscreenElement ? document.fullscreenElement.tagName : 'no'");
if (phase === "nueva" || phase === "celular" || phase === "itch") {
  const c = mobile
    ? { nuevo: [422, 219], normal: [422, 159], siguiente: [422, 369] }
    : { nuevo: [640, 402], normal: [640, 308], siguiente: [640, 682] };
  await shot(phase + "_menu");
  await sleep(4000);
  await shot(phase + "_menu2");
  console.log("PANTALLA COMPLETA antes:", await fsState(), "| boton visible:", await evaluate("JSON.stringify(LukeWeb.fsRect)"));
  if (mobile) {
    await tap(753, 23);
  } else {
    await click(1113, 43);
  }
  await sleep(1500);
  console.log("PANTALLA COMPLETA despues de apretar el boton:", await fsState());
  await shot(phase + "_pantalla_completa");
  if (!mobile) {
    // Ya en pantalla completa el juego ocupa toda la ventana (1280x720).
    for (const type of ["mousePressed", "mouseReleased"]) {
      await send("Input.dispatchMouseEvent", { type, x: 1113, y: 43, button: "left", clickCount: 1 });
      await sleep(80);
    }
    await sleep(1500);
    console.log("PANTALLA COMPLETA despues de apretar SALIR:", await fsState());
  }
  await press(...c.nuevo);
  await sleep(1500);
  await press(...c.normal);
  await sleep(4000);
  await shot(phase + "_cinematica");
  for (let i = 0; i < 3; i++) {
    await press(...c.siguiente);
    await sleep(2000);
  }
  await sleep(6000);
  await shot(phase + "_nivel");
  await audio("nivel, quieto (musica del nivel)");
  await sleep(1000);
  await evaluate("window.__readPeaks()");
  if (mobile) {
    await tap(775, 307);
  } else {
    for (const type of ["keyDown", "keyUp"]) {
      await send("Input.dispatchKeyEvent", { type, key: " ", code: "Space", windowsVirtualKeyCode: 32 });
      await sleep(150);
    }
  }
  await sleep(300);
  await audio("nivel, justo despues de SALTAR (efecto)");
  console.log("INDEXEDDB", JSON.stringify(await evaluate("indexedDB.databases().then(d => d.map(x => x.name))")));
} else if (phase === "iphone") {
  await sleep(2000);
  await shot("iphone_menu");
  console.log("IPHONE: fsSupported =", await evaluate("LukeWeb.fsSupported()"), "| boton en pantalla (fsRect) =", await evaluate("JSON.stringify(LukeWeb.fsRect)"));
} else if (phase === "cargar") {
  await shot("cargar_menu");
  await press(640, 454);
  await sleep(8000);
  await shot("cargar_nivel");
}
console.log("CONSOLA:\n" + logs.filter((l) => /error|exception|warn/i.test(l)).slice(0, 20).join("\n"));
await send("Browser.close").catch(() => {});
await sleep(1500);
chrome.kill();
process.exit(0);
