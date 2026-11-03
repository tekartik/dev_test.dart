# tekartik_dev_build_test

Tests of `dev_build` that need more than `dev_build` itself, kept out of the
published package: the menu agent (`package:dev_build/menu/menu_agent.dart`)
driven in process, over the VM service of a `dart run --agent` menu, and in
Chrome (js and wasm).

* `package:tekartik_dev_build_test/menu_agent_testing.dart`: test presenters
  and helpers to drive a menu through `menuAgent`.
* `package:tekartik_dev_build_test/vm_service_json_rpc.dart` (io): a minimal
  VM service client (json-rpc over a `dart:io` web socket).

Not published, it always uses the `dev_build` of this repo
(`dependency_overrides`).

```bash
dart test            # vm and chrome
dart test -p chrome -c dart2wasm
```
