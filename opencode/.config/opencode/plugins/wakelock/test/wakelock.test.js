import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { setImmediate } from "node:timers/promises";
import test from "node:test";
import plugin from "../index.js";

function context(directory) {
  const queue = [];
  let wake;
  const hooks = new Map();
  let aborted = false;
  return {
    location: { directory },
    session: { async hook(name, callback) { hooks.set(name, callback); } },
    event: {
      async *subscribe({ signal }) {
        const abort = () => { aborted = true; wake?.(); };
        signal.addEventListener("abort", abort, { once: true });
        try {
          while (!signal.aborted) {
            if (!queue.length) await new Promise((resolve) => { wake = resolve; });
            while (!signal.aborted && queue.length) yield queue.shift();
          }
        } finally {
          signal.removeEventListener("abort", abort);
        }
      },
    },
    async send(event) {
      queue.push(event);
      wake?.();
      await setImmediate();
    },
    hooks,
    get aborted() { return aborted; },
  };
}

const sessionFile = (id) => `/tmp/opencode-wakelock/sessions/${id}`;
const status = (ctx, sessionID, type) => ({
  type: "session.status",
  location: ctx.location,
  data: { sessionID, status: { type } },
});

test("V2 events preserve shared locking and release on idle and unload", {
  skip: process.platform !== "darwin",
}, async () => {
  assert.equal(plugin.id, "opencode-wakelock");
  assert.equal(typeof plugin.setup, "function");
  const first = context("/wakelock-test/first");
  const second = context("/wakelock-test/second");
  const a = `ses_wakelock_test_${process.pid}_a`;
  const b = `ses_wakelock_test_${process.pid}_b`;
  const cleanupFirst = await plugin.setup(first);
  const cleanupSecond = await plugin.setup(second);
  try {
    await first.send(status(second, b, "busy"));
    assert.equal(existsSync(sessionFile(b)), false, "ignore other locations");

    await first.send(status(first, a, "busy"));
    assert.equal(existsSync(sessionFile(a)), true);
    const lock = JSON.parse(readFileSync("/tmp/opencode-wakelock/lock.pid", "utf8"));
    assert.doesNotThrow(() => process.kill(lock.pid, 0));

    await second.send(status(second, b, "busy"));
    assert.equal(JSON.parse(readFileSync("/tmp/opencode-wakelock/lock.pid", "utf8")).pid, lock.pid);
    await first.send(status(first, a, "retry"));
    assert.equal(existsSync(sessionFile(a)), true, "keep lock during retries");

    await first.send(status(first, a, "idle"));
    assert.equal(existsSync(sessionFile(a)), false);
    assert.equal(existsSync(sessionFile(b)), true);
    assert.doesNotThrow(() => process.kill(lock.pid, 0), "other busy session retains inhibitor");

    await second.send({ type: "session.idle", data: { sessionID: b } });
    assert.equal(existsSync(sessionFile(b)), false);

    await first.hooks.get("context")({ sessionID: a });
    assert.equal(existsSync(sessionFile(a)), true, "recover mid-turn reload");
    await cleanupFirst();
    assert.equal(first.aborted, true);
    assert.equal(existsSync(sessionFile(a)), false, "unload releases active session");
  } finally {
    await cleanupFirst();
    await cleanupSecond();
  }
});
