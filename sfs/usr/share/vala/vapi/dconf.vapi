/* dconf.vapi generated by valac 0.9.7, do not modify. */

[CCode (cprefix = "DConf", lower_case_cprefix = "dconf_")]
namespace DConf {
	[CCode (cheader_filename = "dconf.h")]
	public class Client : GLib.Object {
		public Client (string? profile = null, owned DConf.WatchFunc? watch_func = null);
		public bool is_writable (string key);
		public string[] list (string dir);
		public GLib.Variant? read (string key);
		public GLib.Variant? read_default (string key);
		public GLib.Variant? read_no_default (string key);
		public bool set_locked (string path, bool locked, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public async bool set_locked_async (string key, bool locked, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public bool unwatch (string name, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public async bool unwatch_async (string name, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public bool watch (string path, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public async bool watch_async (string name, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public bool write (string key, GLib.Variant? value, out string tag = null, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public async bool write_async (string key, GLib.Variant? value, out string tag = null, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public bool write_many (string dir, [CCode (array_length = false)] string[] rels, GLib.Variant?[] values, out string? tag = null, GLib.Cancellable? cancellable = null) throws GLib.Error;
	}
	[CCode (cheader_filename = "dconf.h")]
	public delegate void WatchFunc (DConf.Client client, string path, string[] items, string tag);
	[CCode (cheader_filename = "dconf.h")]
	public static bool is_dir (string str, GLib.Error* error = null);
	[CCode (cheader_filename = "dconf.h")]
	public static bool is_key (string str, GLib.Error* error = null);
	[CCode (cheader_filename = "dconf.h")]
	public static bool is_path (string str, GLib.Error* error = null);
	[CCode (cheader_filename = "dconf.h")]
	public static bool is_rel_dir (string str, GLib.Error* error = null);
	[CCode (cheader_filename = "dconf.h")]
	public static bool is_rel_key (string str, GLib.Error* error = null);
	[CCode (cheader_filename = "dconf.h")]
	public static bool is_rel_path (string str, GLib.Error* error = null);
	[CCode (cname = "dconf_is_dir", cheader_filename = "dconf.h")]
	public static bool verify_dir (string str) throws GLib.Error;
	[CCode (cname = "dconf_is_key", cheader_filename = "dconf.h")]
	public static bool verify_key (string str) throws GLib.Error;
	[CCode (cname = "dconf_is_path", cheader_filename = "dconf.h")]
	public static bool verify_path (string str) throws GLib.Error;
	[CCode (cname = "dconf_is_rel_dir", cheader_filename = "dconf.h")]
	public static bool verify_rel_dir (string str) throws GLib.Error;
	[CCode (cname = "dconf_is_rel_key", cheader_filename = "dconf.h")]
	public static bool verify_rel_key (string str) throws GLib.Error;
	[CCode (cname = "dconf_is_rel_path", cheader_filename = "dconf.h")]
	public static bool verify_rel_path (string str) throws GLib.Error;
}
