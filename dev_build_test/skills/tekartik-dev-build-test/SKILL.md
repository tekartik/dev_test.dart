---
name: tekartik-dev-build-test
description: >-
  Use when testing dev_build code that needs more than dev_build itself, in
  dev_test.dart/dev_build_test (tekartik_dev_build_test): the menu agent
  (menu, menu_line) in process on the VM and in Chrome (js, wasm), a console
  menu run with --agent driven over its VM service, the test presenters
  MenuLineTestPresenter / MenuBasicTestPresenter, menuAgentRunOk,
  menuAgentRunError, menuAgentWaitState, and the minimal VM service client
  VmServiceJsonRpc (json-rpc over a dart:io web socket, no vm_service).
---

# dev_build tests (tekartik_dev_build_test)

The test package of `dev_build`, in the same repo, not published. It holds
the tests that need what the published package should not bring: Chrome
(`build_web_compilers` marks it as a web package for `run_ci`, so its tests
also run in Chrome), process spawning, a VM service client.

## Guidelines

* It always uses the `dev_build` of the repo (`dependency_overrides` path in
  `pubspec.yaml`), so a test here can cover an unreleased dev_build change.
* `dart test` runs the VM and Chrome (dart2js); add
  `dart test -p chrome -c dart2wasm` for wasm. `run_ci` runs it with the
  repo (`repo_support/tool/run_ci.dart`, recursive).
* Platform agnostic tests (no `@TestOn`) run on both; `@TestOn('vm')` for
  process or `dart:io` tests, `@TestOn('browser')` for web only behavior.
* `package:tekartik_dev_build_test/menu_agent_testing.dart`:
  * `MenuLineTestPresenter()` becomes the menu presenter (new manager): a
    `MenuLineProcessor` like the console (prompt answered by the next line,
    item key or `cmd`, command handler); `written` holds its writes.
  * `MenuBasicTestPresenter()`: no line processing, prompts never answered
    (the agent fallback path).
  * Declare with `menu`/`item`/`command`, `await menuRun()`, then drive with
    `menuAgentRunOk('menu_line', {'line': '0'})`,
    `menuAgentRunError(...)`, `menuAgentWaitState((state) => ...)`,
    `menuAgentStateItems(state)` (`key name`, ` >` for a sub menu).
* `package:tekartik_dev_build_test/vm_service_json_rpc.dart` (io):
  `VmServiceJsonRpc.connect(uri)` (the `http://.../token=/` uri printed by
  the VM or by `--agent`), `call(method, params)`,
  `findIsolateWithExtension(name)`, `close()`.
* A menu script spawned by a test lives in `test/data/` (not ending in
  `_test.dart`), run with `dart run test/data/<script>.dart --agent`; read
  the `agent: VM service <uri>` stdout line, close stdin, kill the process
  in a `finally`.
