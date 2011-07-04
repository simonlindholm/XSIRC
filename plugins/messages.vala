/*
 * messages.vala
 *
 * Copyright (c) 2010 Eduardo Niehues
 * Distributed under the New BSD License; see ../LICENSE for details.
 */
using Gee;

namespace XSIRC {
	public class MessagesPlugin : Plugin {
		
		private enum MessageID {
			JOIN,
			PART,
			KICK,
			NICK,
			PRIVMSG,
			ACTION,
			CTCPMSG,
			NOTICE,
			QUIT,
			CHANUSERMODE,
			CHANMODE,
			MODE,
			TOPIC,
			SENT_NOTICE,
			SENT_CTCP,
			SENT_PRIVMSG,
			SENT_ACTION
		}
		
		private struct MessageType {
			public MessageID id;
			public string name;
			public string accepted_params;
		}
		
		private struct DefaultMessage {
			public MessageID id;
			public string message;
		}
		
		private const MessageType[] message_types = {
			{MessageID.JOIN,N_("User join"),"$USERNICK, $USERNAME, $USERMASK, $CHANNEL"},
			{MessageID.PART,N_("User part"),"$USERNICK, $USERNAME, $USERMASK, $CHANNEL, $MESSAGE"},
			{MessageID.KICK,N_("User kicked"),"$KICKED, $USERNICK, $USERNAME, $USERMASK, $MESSAGE"},
			{MessageID.NICK,N_("User changed nick"),"$NEWNICK, $USERNICK, $USERNAME, $USERMASK"},
			{MessageID.PRIVMSG,N_("Normal message"),"$USERNICK, $USERNAME, $USERMASK, $MESSAGE, $USERRANK"},
			{MessageID.ACTION,N_("User action (/me)"),"$USERNICK, $USERNAME, $USERMASK, $MESSAGE"},
			{MessageID.CTCPMSG,N_("CTCP request"),"$USERNICK, $USERNAME, $USERMASK, $REQUEST"},
			{MessageID.NOTICE,N_("Notice"),"$USERNICK, $USERNAME, $USERMASK, $MESSAGE"},
			{MessageID.QUIT,N_("User disconnect"),"$USERNICK, $USERNAME, $USERMASK, $MESSAGE"},
			{MessageID.CHANUSERMODE,N_("Channel user mode change"),"$USERNICK, $USERNAME, $USERMASK, $CHANNEL, $MODES, $TARGETS"},
			{MessageID.CHANMODE,N_("Channel mode change"),"$USERNICK, $USERNAME, $USERMASK, $CHANNEL, $MODES"},
			{MessageID.MODE,N_("User mode change"),"$NICK, $MODES"},
			{MessageID.TOPIC,N_("Topic change"),"$USERNICK, $USERNAME, $USERMASK, $CHANNEL, $TOPIC"},
			{MessageID.SENT_NOTICE,N_("Sent NOTICE"),"$NICK, $MESSAGE"},
			{MessageID.SENT_CTCP,N_("Sent CTCP messages"),"$NICK, $MESSAGE"},
			{MessageID.SENT_PRIVMSG,N_("Sent messages"),"$RANK, $NICK, $MESSAGE"},
			{MessageID.SENT_ACTION,N_("Sent actions"),"$NICK, $MESSAGE"}
		};
		
		private const DefaultMessage[] default_messages = {
			{MessageID.JOIN,N_("$USERNICK [$USERNAME@$USERMASK] has joined $CHANNEL")},
			{MessageID.PART,N_("$USERNICK [$USERNAME@$USERMASK] has left $CHANNEL [$MESSAGE]")},
			{MessageID.KICK,N_("$USERNICK has kicked $KICKED from $CHANNEL [$MESSAGE]")},
			{MessageID.NICK,N_("$USERNICK is now known as $NEWNICK.")},
			{MessageID.PRIVMSG,"<$USERRANK$USERNICK> $MESSAGE"},
			{MessageID.ACTION,"*  $USERNICK $MESSAGE"},
			{MessageID.CTCPMSG,N_("Got CTCP $REQUEST from $USERNICK")},
			{MessageID.NOTICE,"-$USERNICK- $MESSAGE"},
			{MessageID.QUIT,N_("$USERNICK [$USERNAME@$USERMASK] has disconnected [$MESSAGE]")},
			{MessageID.CHANUSERMODE,N_("$USERNICK sets mode $MODES on $TARGETS")},
			{MessageID.CHANMODE,N_("$USERNICK sets $CHANNEL's mode: $MODES")},
			{MessageID.MODE,N_("Changing mode: $MODES")},
			{MessageID.TOPIC,N_("$USERNICK sets the topic to $TOPIC")},
			{MessageID.SENT_NOTICE,"-$BOLD$NICK$BOLD- $MESSAGE"},
			{MessageID.SENT_CTCP,">> $BOLD$CTCP $MESSAGE$BOLD"},
			{MessageID.SENT_PRIVMSG,"<$BOLD$RANK$NICK$BOLD> $MESSAGE"},
			{MessageID.SENT_ACTION,"$BOLD*  $NICK$BOLD $MESSAGE"}
		};
		
		private HashMap<MessageID,string> messages = new HashMap<MessageID,string>();
		
		public MessagesPlugin() {
			Object();
		}
		
		construct {
			name = _("Messages");
			description = _("Customizable messages.");
			author = "NieXS";
			version = "0.1";
			priority = int.MAX;
			prefs_widget = null;
			load_default_messages();
			load_messages();
			set_up_prefs();
		}
		
		private void set_up_prefs() {
			Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null,null);
			Gtk.VBox box = new Gtk.VBox(false,0);
			scroll.add_with_viewport(box);
			LinkedList<Gtk.Entry> entries = new LinkedList<Gtk.Entry>();
			prefs_widget = scroll;
			foreach(MessageType message_type in message_types) {
				Gtk.Label label = new Gtk.Label(_(message_type.name));
				Gtk.Entry entry = new Gtk.Entry();
				box.pack_start(label,false,false,0);
				entry.text = messages[message_type.id];
				entry.tooltip_text = message_type.accepted_params;
				entries.add(entry);
				box.pack_start(entry,false,false,0);
			}
			// Saving
			Gtk.Button button = new Gtk.Button.from_stock(Gtk.Stock.SAVE);
			button.clicked.connect(() => {
				int i = 0;
				foreach(Gtk.Entry entry in entries) {
					messages[(MessageID)i] = entry.text;
					i++;
				}
				save_messages();
			});
			box.pack_start(button,false,false,0);
		}
		
		private void load_default_messages() {
			foreach(DefaultMessage message in default_messages) {
				messages[message.id] = _(message.message);
			}
		}
		
		private void load_messages() {
			string[] names = {"JOIN","PART","KICK","PRIVMSG","ACTION","CTCPMSG","NOTICE","QUIT","CHANUSERMODE","CHANMODE","MODE","TOPIC","SENT_NOTICE","SENT_CTCP","SENT_PRIVMSG","SENT_ACTION"};
			try {
				KeyFile conf = new KeyFile();
				conf.load_from_file(Environment.get_user_config_dir()+"/xsirc/messages.conf",0);
				int i = 0;
				foreach(string name in names) {
					if(conf.has_key("messages",name)) {
						messages[(MessageID)i] = conf.get_string("messages",name);
					}
					i++;
				}
			} catch(Error e) {
				
			}
		}
		
		private void save_messages() {
			string[] names = {"JOIN","PART","KICK","PRIVMSG","ACTION","CTCPMSG","NOTICE","QUIT","CHANUSERMODE","CHANMODE","MODE","TOPIC","SENT_NOTICE","SENT_CTCP","SENT_PRIVMSG","SENT_ACTION"};
			try {
				KeyFile conf = new KeyFile();
				int i = 0;
				foreach(string name in names) {
					if(messages[(MessageID)i] != null) {
						conf.set_string("messages",name,messages[(MessageID)i]);
					}
					i++;
				}
				FileUtils.set_contents(Environment.get_user_config_dir()+"/xsirc/messages.conf",conf.to_data());
			} catch(Error e) {
				
			}
		}
		
		public override bool on_join(Server server,string usernick,string username,string usermask,string channel) {
			string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$CHANNEL"};
			string[] replacements = {usernick,username,usermask,channel};
			string result = apply_message_style(MessageID.JOIN,replaced,replacements);
			server.add_to_view(channel,result);
			return true;
		}
		
		public override bool on_part(Server server,string usernick,string username,string usermask,string channel,string message) {
			string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$CHANNEL","$MESSAGE"};
			string[] replacements = {usernick,username,usermask,channel,message};
			string result = apply_message_style(MessageID.PART,replaced,replacements);
			server.add_to_view(channel,result);
			return true;
		}
		
		public override bool on_kick(Server server,string kicked,string usernick,string username,string usermask,string channel,string message) {
			string[] replaced = {"$KICKED","$USERNICK","$USERNAME","$USERMASK","$CHANNEL","$MESSAGE"};
			string[] replacements = {kicked,usernick,username,usermask,channel,message};
			string result = apply_message_style(MessageID.KICK,replaced,replacements);
			server.add_to_view(channel,result);
			return true;
		}
		
		public override bool on_nick(Server server,string new_nick,string usernick,string username,string usermask) {
			string[] replaced = {"$NEWNICK","$USERNICK","$USERNAME","$USERMASK"};
			string[] replacements = {new_nick,usernick,username,usermask};
			string result = apply_message_style(MessageID.NICK,replaced,replacements);
			foreach(Server.Channel channel in server.channels) {
				if(usernick.down() in channel.users) {
					server.add_to_view(channel.name,result);
				}
			}
			foreach(GUI.View view in server.views) {
				if(view.name.down() == usernick.down()) {
					server.add_to_view(view.name,result);
				}
			}
			return true;
		}
		
		public override bool on_privmsg(Server server,string usernick,string username,string usermask,string target,string message) {
			// Finding the rank.
			string userrank = " ";
			if(server.find_channel(target) != null) {
				foreach(string user in server.find_channel(target).raw_users) {
					if(user.substring(1) == usernick) {
						userrank = user[0:1];
						break;
					}
				}
			}
			string my_target = target.down() == server.nick.down() ? usernick : target;
			if(message.has_prefix("\001ACTION") && message.has_suffix("\x01")) { // ACTION
				string my_message = message.replace("\x01","").substring(7);
				string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$MESSAGE"};
				string[] replacements = {usernick,username,usermask,my_message};
				string result = apply_message_style(MessageID.ACTION,replaced,replacements);
				server.add_to_view(my_target,result);
			} else if(message.has_prefix("\x01") && message.has_suffix("\x01")) { // CTCPMSG
				string my_message = message.replace("\x01","");
				string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$REQUEST"};
				string[] replacements = {usernick,username,usermask,my_message};
				string result = apply_message_style(MessageID.CTCPMSG,replaced,replacements);
				server.add_to_view(_("<server>"),result);
			} else { // PRIVMSG
				string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$MESSAGE","$USERRANK"};
				string[] replacements = {usernick,username,usermask,message,userrank};
				string result = apply_message_style(MessageID.PRIVMSG,replaced,replacements);
				server.add_to_view(my_target,result);
			}
			return true;
		}
		
		public override bool on_notice(Server server,string usernick,string username,string usermask,string target,string message) {
			// This isn't the place for CTCP replies, they should be handled by someone else
			if(message.has_prefix("\001")) {
				return true;
			}
			string my_target = target.down() == server.nick.down() ? usernick : target;
			string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$MESSAGE"};
			string[] replacements = {usernick,username,usermask,message};
			string result = apply_message_style(MessageID.NOTICE,replaced,replacements);
			if(server.find_view(my_target) != null) {
				server.add_to_view(my_target,result);
			} else {
				server.add_to_view(_("<server>"),result);
			}
			return true;
		}
		
		public override bool on_quit(Server server,string usernick,string username,string usermask,string message) {
			string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$MESSAGE"};
			string[] replacements = {usernick,username,usermask,message};
			string result = apply_message_style(MessageID.QUIT,replaced,replacements);
			foreach(Server.Channel channel in server.channels) {
				if(usernick.down() in channel.users) {
					server.add_to_view(channel.name,result);
				}
			}
			foreach(GUI.View view in server.views) {
				if(usernick.down() == view.name.down()) {
					server.add_to_view(view.name,result);
				}
			}
			return true;
		}
		
		public override bool on_chan_user_mode(Server server,string usernick,string username,string usermask,string channel,string modes,string targets) {
			string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$CHANNEL","$MODES","$TARGETS"};
			string[] replacements = {usernick,username,usermask,channel,modes,targets};
			string result = apply_message_style(MessageID.CHANUSERMODE,replaced,replacements);;
			server.add_to_view(channel,result);
			return true;
		}
		
		public override bool on_chan_mode(Server server,string usernick,string username,string usermask,string channel,string modes) {
			string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$CHANNEL","$MODES"};
			string[] replacements = {usernick,username,usermask,channel,modes};
			string result = apply_message_style(MessageID.CHANMODE,replaced,replacements);
			server.add_to_view(channel,result);
			return true;
		}
		
		public override bool on_mode(Server server,string usernick,string mode) {
			string[] replaced = {"$NICK","$MODES"};
			string[] replacements = {usernick,mode};
			string result = apply_message_style(MessageID.MODE,replaced,replacements);
			server.add_to_view(_("<server>"),result);
			return true;
		}
		
		public override bool on_topic(Server server,string usernick,string username,string usermask,string channel,string topic) {
			string[] replaced = {"$USERNICK","$USERNAME","$USERMASK","$CHANNEL","$TOPIC"};
			string[] replacements = {usernick,username,usermask,channel,topic};
			string result = apply_message_style(MessageID.TOPIC,replaced,replacements);
			server.add_to_view(channel,result);
			return true;
		}
		
		public override bool on_sent_message(Server server,string nick,string target,string message,string raw_msg) {
			// Finding our rank
			string userrank = " ";
			if(server.find_channel(target) != null) {
				foreach(string user in server.find_channel(target).raw_users) {
					if(user.substring(1).down() == nick.down()) {
						userrank = user[0:1];
						break;
					}
				}
			}
			if(raw_msg.down().has_prefix("notice")) {
				string[] replaced = {"$NICK","$MESSAGE"};
				string[] replacements = {nick,message};
				string result = apply_message_style(MessageID.SENT_NOTICE,replaced,replacements);
				server.add_to_view(target,result);
			} else if(message.has_prefix("ACTION")) {
				string[] replaced = {"$NICK","$MESSAGE"};
				string[] replacements = {nick,message.replace("\x01","").substring(7)};
				string result = apply_message_style(MessageID.SENT_ACTION,replaced,replacements);
				server.add_to_view(target,result);
			} else if(message.has_prefix("")) { // CTCP
				string[] replaced = {"$NICK","$MESSAGE"};
				string[] replacements = {nick,message.replace("\x01","")};
				string result = apply_message_style(MessageID.SENT_CTCP,replaced,replacements);
				server.add_to_view(target,result);
			} else { // Normal messages
				string[] replaced = {"$RANK","$NICK","$MESSAGE"};
				string[] replacements = {userrank,nick,message};
				string result = apply_message_style(MessageID.SENT_PRIVMSG,replaced,replacements);
				server.add_to_view(target,result);
			}
			return true;
		}
		
		private string apply_message_style(MessageID id,string[] replaced,string[] replacements) {
			// We have to apply the formatting before adding the content, otherwise
			// weird things are going to happen when someone says $COLOR in a channel
			string[] format = {"$BOLD","$ITALIC","$UNDERLINE","$COLOR","$NORMAL"};
			string[] codes  = {"\x02","\x16","\x1F","\x03","\x0F"};
			string result = messages[id];
			int i = 0;
			foreach(string s in format) {
				if(s in result) {
					result = result.replace(s,codes[i]);
				}
				i++;
			}
			i = 0;
			foreach(string s in replaced) {
				if(s in result) {
					result = result.replace(s,replacements[i]);
				}
				i++;
			}
			return result;
		}
	}
}

#if !WINDOWS
//[ModuleInit]
Type register_plugin(TypeModule module) {
	return typeof(XSIRC.MessagesPlugin);
}
#endif
