import upstream from "opencode-wakelock";

// V2 owns subscriptions and cleanup. The pinned upstream package owns the
// cross-process inhibitor, session files, and stale-PID checks.
export default {
  id: "opencode-wakelock",
  async setup(ctx) {
    const legacy = await upstream.server({
      client: {
        app: {
          async log({ body: { level, message, extra } }) {
            console[level === "warn" ? "warn" : level](
              `[opencode-wakelock] ${message}`,
              extra ?? "",
            );
          },
        },
      },
    });
    if (!legacy.event) return;

    const controller = new AbortController();
    const active = new Set();
    let closed = false;

    async function busy(sessionID) {
      if (closed) return;
      active.add(sessionID);
      await legacy.event({
        event: {
          type: "session.status",
          properties: { sessionID, status: { type: "busy" } },
        },
      });
    }

    async function idle(sessionID) {
      if (!active.delete(sessionID)) return;
      await legacy.event({
        event: { type: "session.idle", properties: { sessionID } },
      });
    }

    async function releaseAll() {
      for (const sessionID of [...active]) await idle(sessionID);
    }

    // A config reload can happen during an active turn. The next model request
    // reacquires its lock even if the original busy event preceded setup.
    await ctx.session.hook("context", ({ sessionID }) => busy(sessionID));

    const listening = (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (closed) break;
          if (event.type === "session.status") {
            const { sessionID, status } = event.data;
            if (status.type === "idle") {
              await idle(sessionID);
            } else if (
              status.type === "busy" &&
              event.location?.directory === ctx.location.directory &&
              event.location?.workspaceID === ctx.location.workspaceID
            ) {
              await busy(sessionID);
            }
          } else if (event.type === "session.idle") {
            await idle(event.data.sessionID);
          }
        }
      } catch (error) {
        if (!controller.signal.aborted) {
          console.error("[opencode-wakelock] Event subscription failed", error);
        }
      } finally {
        await releaseAll();
      }
    })();

    return async () => {
      closed = true;
      controller.abort();
      await listening;
      await releaseAll();
    };
  },
};
