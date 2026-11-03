/// Lets an LLM agent read and drive a menu: the `menu` (state and output)
/// and `menu_line` (a line typed by a user) commands, over the VM service
/// ([menuAgentVmRegister], done by the io console) or another json
/// transport ([MenuAgent.describe], [MenuAgent.run]).
///
/// The VM service extensions are the ones of tekartik_app_agent: the
/// `app-agent` MCP server (tekartik_app_agent_mcp) connects with
/// `app_connect` to the VM service uri and lists the commands as tools.
library;

export 'package:dev_build/src/menu/menu_agent.dart'
    show
        MenuAgent,
        menuAgent,
        menuAgentOrNull,
        menuAgentVmRegister,
        menuAgentVmCommandsExtension,
        menuAgentVmRunExtension;
export 'package:dev_build/src/menu/menu_presenter.dart' show MenuLineProcessor;
