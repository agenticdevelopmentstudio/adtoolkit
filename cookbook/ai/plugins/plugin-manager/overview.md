
The plugin manager discovers, describes, and loads provider plugins shipped as
plugin bundles. A plugin bundle declares a principal type that conforms to the
plugin protocol. Discovery reads each bundle's descriptor — a plain JSON
resource describing the plugin's identity, models, settings fields, and
provider templates — without loading the plugin's code, so a settings UI can
list and configure a plugin from its descriptor alone. Loading a plugin
(mapping its code into the running process and instantiating its principal
type) only happens on demand, the first time a caller asks for that plugin's
instance, and the resulting instance is cached for the manager's lifetime. The
manager owns no networking, no UI, and no secret storage — those belong to the
loaded plugin, the settings UI built from the descriptor, and the
secret-storage component respectively.

