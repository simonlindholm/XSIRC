/*
 * servermanager.vala
 *
 * Copyright (c) 2010 Eduardo Niehues
 * Distributed under the New BSD License; see ../LICENSE for details.
 */
using Gee;
namespace XSIRC {
	public class ServerManager : Object {
		public class Network {
			public class ServerData {
				public string  address;
				public int     port;
				public bool    ssl;
				public string? password;
			}
			
			public string name;
			public LinkedList<ServerData> servers = new LinkedList<ServerData>();
			public LinkedList<string> commands    = new LinkedList<string>();
			public bool auto_connect;
			
		}
		
		public LinkedList<Network> networks = new LinkedList<Network>();
		public KeyFile raw_conf = new KeyFile();
		public bool loaded_networks = false;
		
		public ServerManager() {
			stdout.printf("Loading networks\n");
			// Checking if networks.conf exists, and trying to load it
			if(FileUtils.test(Environment.get_user_config_dir()+"/xsirc/networks.conf",FileTest.EXISTS)) {
				try {
					raw_conf.load_from_file(Environment.get_user_config_dir()+"/xsirc/networks.conf",KeyFileFlags.KEEP_COMMENTS);
				} catch(KeyFileError e) {
					stderr.printf("Could not parse networks.conf\n");
				} catch(FileError e) {
					stderr.printf("Could not open networks.conf\n");
				}
			} else {
				stderr.printf("No networks.conf file found\n");
			}
			
			// Loading all networks
			foreach(string net_name in raw_conf.get_groups()) {
				loaded_networks = true;
				bool skip = false;
				string[] needed_keys = {"server0","autoconnect"};
				try {
					foreach(string key in needed_keys) {
						if(!raw_conf.has_key(net_name,key)) {
							stderr.printf("Could not parse network %s!\n",net_name);
							skip = true;
							break;
						}
					}
					if(skip) { continue; }
					Network network = new Network();
					network.name = net_name;
					for(int curr_server = 0;raw_conf.has_key(net_name,"server%d".printf(curr_server));curr_server++) {
						Network.ServerData server = new Network.ServerData();
						if(!Regex.match_simple("^(irc|sirc):\\/\\/[a-zA-Z0-9-_.]+:\\d+",raw_conf.get_string(net_name,"server%d".printf(curr_server)))) {
							stderr.printf("Could not parse server #%d in network %s!\n",curr_server,net_name);
							continue;
						}
						string[] split_server = raw_conf.get_string(net_name,"server%d".printf(curr_server)).split(" ");
						string server_data = split_server[0];
						if(split_server.length > 1) {
							server.password = split_server[1];
						} else {
							server.password = null;
						}
						string[] split_server_data = Regex.split_simple("(:\\/\\/|:)",server_data);
						server.ssl     = split_server_data[0] == "ircs";
						server.port    = split_server_data[4].to_int();
						server.address = split_server_data[2];
						network.servers.add(server);
					}
					network.auto_connect = raw_conf.get_boolean(net_name,"autoconnect");
					for(int curr_cmd = 0;raw_conf.has_key(net_name,"command%d".printf(curr_cmd));curr_cmd++) {
						network.commands.add(raw_conf.get_string(net_name,"command%d".printf(curr_cmd)));
					}
					networks.add(network);
				} catch(KeyFileError e) {
					stderr.printf("Error loading network: %s\n",e.message);
				}
			}
		}
		
		public void save_networks() {
			raw_conf = new KeyFile();
			foreach(Network network in networks) {
				raw_conf.set_boolean(network.name,"autoconnect",network.auto_connect);
				for(int i = 0;i < network.servers.size; i++) {
					StringBuilder s = new StringBuilder("irc");
					if(network.servers[i].ssl) {
						s.append("s");
					}
					s.append("://").append(network.servers[i].address).append(":").append(network.servers[i].port.to_string());
					if(network.servers[i].password != null) {
						s.append(" ").append(network.servers[i].password);
					}
					raw_conf.set_string(network.name,"server%d".printf(i),s.str);
				}
				for(int i = 0;i < network.commands.size; i++) {
					raw_conf.set_string(network.name,"command%d".printf(i),network.commands[i]);
				}
			}
			try {
				FileUtils.set_contents(Environment.get_user_config_dir()+"/xsirc/networks.conf",raw_conf.to_data());
			} catch(Error e) {
				
			}
		}
		
		public Network? find_network(string name) {
			foreach(Network network in networks) {
				if(network.name == name) {
					return network;
				}
			}
			return null;
		}
		
		public void startup() {
			foreach(Network network in networks) {
				stdout.printf("Iterating through network %s\n",network.name);
				if(!network.auto_connect) {
					continue;
				}
				Network.ServerData server = network.servers[0];
				Main.gui.open_server(server.address,server.port,server.ssl,(server.password ?? ""),network);
			}
		}
		
		public void on_connect(Server server) requires (server.network != null) {
			foreach(string command in server.network.commands) {
				server.send(command.replace("$nick",server.nick));
			}
		}
	}
}