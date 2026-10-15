# Wakelock for OpenCode V2

This local V2 plugin adapts `opencode-wakelock@0.2.3`, whose published entrypoint
supports only V1. The dependency is pinned because this adapter calls its
`server()` implementation.

The V2 `setup` function subscribes to native events, reads `event.data`, and
passes busy/idle transitions to the upstream lock manager. It filters busy
events by location because V2 subscriptions receive events across the server.
Retries retain an existing lock. Idle transitions, including failed and
interrupted turns, release it. Unloading the plugin aborts the subscription and
releases its sessions. A context hook reacquires a lock after a mid-turn reload.

The upstream package retains ownership of macOS `caffeinate -i`, Linux
`systemd-inhibit`, cross-process session tracking, and stale-process cleanup.

Install dependencies with `npm ci` in this directory. Run `npm test` to exercise
the adapter with real session files and the platform inhibitor. The tests use
unique session IDs and release their locks afterward.

Once upstream publishes a native V2 release, replace the local plugin entry in
`opencode.jsonc` with that release and remove the local adapter.
