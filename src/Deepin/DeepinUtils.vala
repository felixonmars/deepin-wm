//
//  Copyright (C) 2014 Deepin, Inc.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Gala
{
	public class DeepinUtils
	{
		const string deepin_wm_css_file = Config.PKGDATADIR + "/deepin-wm.css";
		static Gtk.CssProvider default_css_provider;

		const string KEY_WORKSPACE_NAMES = "workspace-names";
		const string SCHEMA_GENERAL = "com.deepin.wrap.gnome.desktop.wm.preferences";
		static GLib.Settings general_gsettings;

		/* WM functions */

		struct DebugRule {
			public string keyword;
			public Meta.DebugTopic topic;
		}

		public static void init_debug_topics ()
		{
			string debug_env = GLib.Environment.get_variable ("MUTTER_DEBUG");
			if (debug_env != null) {
				const DebugRule[] rules = {
					{ "VERBOSE", Meta.DebugTopic.VERBOSE },
					{ "FOCUS", Meta.DebugTopic.FOCUS },
					{ "WORKAREA", Meta.DebugTopic.WORKAREA },
					{ "STACK", Meta.DebugTopic.STACK },
					{ "THEMES", Meta.DebugTopic.THEMES },
					{ "SM", Meta.DebugTopic.SM },
					{ "EVENTS", Meta.DebugTopic.EVENTS },
					{ "STATE", Meta.DebugTopic.WINDOW_STATE },
					{ "OPS", Meta.DebugTopic.WINDOW_OPS },
					{ "GEOMETRY", Meta.DebugTopic.GEOMETRY },
					{ "PLACEMENT", Meta.DebugTopic.PLACEMENT },
					{ "PING", Meta.DebugTopic.PING },
					{ "XINERAMA", Meta.DebugTopic.XINERAMA },
					{ "KEYBINDINGS", Meta.DebugTopic.KEYBINDINGS },
					{ "SYNC", Meta.DebugTopic.SYNC },
					{ "ERRORS", Meta.DebugTopic.ERRORS },
					{ "STARTUP", Meta.DebugTopic.STARTUP },
					{ "PREFS", Meta.DebugTopic.PREFS },
					{ "GROUPS", Meta.DebugTopic.GROUPS },
					{ "RESIZING", Meta.DebugTopic.RESIZING },
					{ "SHAPES", Meta.DebugTopic.SHAPES },
					{ "COMPOSITOR", Meta.DebugTopic.COMPOSITOR },
#if HAS_MUTTER310
					{ "RESISTANCE", Meta.DebugTopic.EDGE_RESISTANCE },
					{ "DBUS", Meta.DebugTopic.DBUS }
#else
					{ "RESISTANCE", Meta.DebugTopic.EDGE_RESISTANCE }
#endif
				};

				bool matched = false;
				foreach (var rule in rules) {
					if (rule.keyword.match_string (debug_env, true)) {
						matched =true;
						Meta.Util.add_verbose_topic (rule.topic);
					}
				}
				if (!matched) {
					Meta.Util.add_verbose_topic (Meta.DebugTopic.VERBOSE);
				}
			}
		}

		// TODO: use gsettings instead
		public static bool is_show_desktop_in_tab_list ()
		{
			return true;
		}

		/**
		 * Show desktop by minimizing all windows.
		 */
		public static void show_desktop (Meta.Workspace workspace)
		{
			// TODO: this is a temporary solution, use interface in mutter
			// instead

			var screen = workspace.get_screen ();
			var display = screen.get_display ();

#if HAS_MUTTER314
			var windows = display.get_tab_list (Meta.TabList.NORMAL, workspace);
#else
			var windows = display.get_tab_list (Meta.TabList.NORMAL, screen, workspace);
#endif
			foreach (var w in windows) {
				w.minimize ();
			}
		}

		public static bool is_window_in_tab_list (Meta.Window window)
		{
			var workspace = window.get_screen ().get_active_workspace ();
			var display = window.get_screen ().get_display ();
#if HAS_MUTTER314
			var windows = display.get_tab_list (Meta.TabList.NORMAL, workspace);
#else
			var windows = display.get_tab_list (Meta.TabList.NORMAL, screen, workspace);
#endif
			foreach (var w in windows) {
				if (w == window) {
					return true;
				}
			}
			return false;
		}

		/**
		 * Overide Meta.Prefs.get_workspace_name () to ignore the default
		 * workspace name in format "Workspace %d".
		 */
		public static string get_workspace_name (int i)
		{
			var names = get_workspace_names ();
			if (names.length < i) {
				return "";
			}
			return names[i];
		}

		public static string[] get_workspace_names ()
		{
			return get_general_gsettings ().get_strv (KEY_WORKSPACE_NAMES);
		}

		public static Meta.Rectangle get_primary_monitor_geometry (Meta.Screen screen)
		{
			return screen.get_monitor_geometry (screen.get_primary_monitor ());
		}

		/* CSS functions */

		public static Gtk.CssProvider get_default_css_provider ()
		{
			if (default_css_provider != null) {
				return default_css_provider;
			}

			default_css_provider = new Gtk.CssProvider ();
			try {
				default_css_provider.load_from_path (deepin_wm_css_file);
			} catch (Error e) {warning (e.message);}

			return default_css_provider;
		}

		public static Gtk.StyleContext new_css_style_context (string class_name)
		{
			var css_provider = get_default_css_provider ();

			var style_path = new Gtk.WidgetPath ();
			style_path.append_type (typeof (Gtk.Window));

			var style_context = new Gtk.StyleContext ();
			style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			style_context.add_class (class_name);
			style_context.set_path (style_path);

			return style_context;
		}

		public static Clutter.Color get_css_background_color (string class_name, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL)
		{
			return gdkrgba2color (get_css_background_color_gdk_rgba (class_name, flags));
		}
		public static Gdk.RGBA get_css_background_color_gdk_rgba (string class_name, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL)
		{
			var style_context = new_css_style_context (class_name);
			var value = style_context.get_property (Gtk.STYLE_PROPERTY_BACKGROUND_COLOR, flags);
			return (Gdk.RGBA) value;
		}

		public static Clutter.Color get_css_color (string class_name, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL)
		{
			return gdkrgba2color (get_css_color_gdk_rgba (class_name, flags));
		}
		public static Gdk.RGBA get_css_color_gdk_rgba (string class_name, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL)
		{
			var style_context = new_css_style_context (class_name);
			var value = style_context.get_property (Gtk.STYLE_PROPERTY_COLOR, flags);
			return (Gdk.RGBA) value;
		}

		public static int get_css_border_radius (string class_name, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL)
		{
			var style_context = new_css_style_context (class_name);
			var value = style_context.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, flags);
			return (int) value;
		}

		public static Pango.FontDescription get_css_font (string class_name, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL)
		{
			var style_context = new_css_style_context (class_name);
			var value = style_context.get_property (Gtk.STYLE_PROPERTY_FONT, flags);
			return (Pango.FontDescription) value;
		}
		public static int get_css_font_size (string class_name, Gtk.StateFlags flags = Gtk.StateFlags.NORMAL)
		{
			var fontdsc = get_css_font (class_name, flags);
			return (int) ((float) fontdsc.get_size () / Pango.SCALE);
		}

		/* Other */
		public static GLib.Settings get_general_gsettings ()
		{
			if (general_gsettings == null) {
				general_gsettings = new GLib.Settings (SCHEMA_GENERAL);
			}
			return general_gsettings;
		}

		/**
		 * Convert Gdk.RGBA to Clutter.Color.
		 */
		public static Clutter.Color gdkrgba2color (Gdk.RGBA rgba)
		{
			return {
				(uint8) (rgba.red * 255),
				(uint8) (rgba.green * 255),
				(uint8) (rgba.blue * 255),
				(uint8) (rgba.alpha * 255)
			};
		}

		/**
		 * Shrink a MetaRectangle on all sides for the given size.
		 * Negative amounts will scale it instead.
		 */
		public static void shrink_rectangle (ref Meta.Rectangle rect, int size)
		{
			rect.x += size;
			rect.y += size;
			rect.width -= size * 2;
			rect.height -= size * 2;
		}

		/**
		 * Scale a MetaRectangle on size and position.
		 */
		public static void scale_rectangle (ref Meta.Rectangle rect, float scale)
		{
			rect.x = (int) (rect.x * scale);
			rect.y = (int) (rect.y * scale);
			rect.width = (int) (rect.width * scale);
			rect.height = (int) (rect.height * scale);
		}

		/**
		 * Scale a MetaRectangle on allsides and keep center point not changed.
		 */
		public static void scale_rectangle_in_center (ref Meta.Rectangle rect, float scale)
		{
			int distance_x = (int) ((scale - 1) / 2 * rect.width);
			int distance_y = (int) ((scale - 1) / 2 * rect.height);
			rect.x -= distance_x;
			rect.y -= distance_y;
			rect.width += distance_x * 2;
			rect.height += distance_y * 2;
		}
	}
}