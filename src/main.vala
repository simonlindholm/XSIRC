using Gee;
namespace XSIRC {
	bool irc_user_is_privileged(string user) {
		return /^(&|@|%|\+|~)/.match(user);
	}
	public static class Main {
		public static GUI gui;
		public static ConfigManager config_manager;
		public static ConfigManager.ConfigAccessor config;
		public static unowned KeyFile config_file;
		public static ServerManager server_manager;
		public static MacroManager macro_manager;
		public static PluginManager plugin_manager;
	}
	
	void main_loop() {
		Main.plugin_manager.on_startup();
		Gtk.main();
		Main.plugin_manager.on_shutdown();
	}
	
	int main(string[] args) {
		Gtk.init(ref args);
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bindtextdomain(GETTEXT_PACKAGE,LOCALE_DIR);
		Environment.set_application_name(GETTEXT_PACKAGE);
		try {
#if WINDOWS
			Gtk.Window.set_default_icon(new Gdk.Pixbuf.from_file("resources\\xsirc.png"));
#else
			Gtk.Window.set_default_icon(new Gdk.Pixbuf.from_file(PREFIX+"/share/pixmaps/xsirc.png"));
#endif
		} catch(Error e) {
			
		}
		// Setting up some folder structure for stuff
		if(!FileUtils.test(Environment.get_user_config_dir()+"/xsirc",FileTest.EXISTS)) {
			DirUtils.create(Environment.get_user_config_dir()+"/xsirc",0755);
			DirUtils.create(Environment.get_user_config_dir()+"/xsirc/plugins",0755);
			//DirUtils.create(Environment.get_user_config_dir()+"/xsirc/irclogs",0755);
		}
		// Starting up!
		Main.config_manager = new ConfigManager();
		Main.config_file = Main.config_manager.config;
		Main.config = new ConfigManager.ConfigAccessor();
		// Log folder
		if(!FileUtils.test(Main.config.string["log_folder"],FileTest.EXISTS)) {
			DirUtils.create(Main.config.string["log_folder"],0755);
		}
		Main.server_manager = new ServerManager();
		Main.macro_manager = new MacroManager();
		Main.plugin_manager = new PluginManager();
		Main.gui = new XSIRC.GUI();
		Main.gui.startup();
		Main.plugin_manager.startup();
		Main.server_manager.startup();

		main_loop();
		Main.server_manager.shutdown();
		return 0;
	}
}
