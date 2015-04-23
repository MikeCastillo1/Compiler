/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * source-code.vala
 * Copyright (C) 2015 Miguel Angel Castillo Sanchez <kmsiete@gmail.com>
 *
 * Compiler is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Compiler is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using Compiler.Util;

namespace Compiler.UI{
	public class SourceCode : Box{
		private ScrolledWindow scrolled_window;
		private SourceView source_view;
		private File file;
		private bool saved;
		private string title;
		private Log log;


		public SourceBuffer source_buffer { get; private set; }
		public string text {
			owned get {
				return this.source_buffer.text;
			}

		}
		// Constructor

		public SourceCode (bool verbose = false) {
			this.log = new Log (verbose);
			this.scrolled_window = new ScrolledWindow (null, null);
			this.scrolled_window.kinetic_scrolling = true;
			this.scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

			this.source_view = new SourceView ();
			this.source_view.hexpand = true;
			this.source_view.vexpand = true;

			this.source_view.show_line_numbers = true;
			this.source_view.highlight_current_line = true;
			this.source_view.indent_width = 4;
			this.source_view.auto_indent  = true;
			this.source_view.editable     = true;
			this.source_view.cursor_visible = true;
			this.scrolled_window.add (this.source_view);

			var fontdec = new Pango.FontDescription();
			fontdec.set_family("Monospace");
			this.source_view.override_font(fontdec);

			this.source_buffer = new SourceBuffer (null);
			this.source_buffer.highlight_matching_brackets = true;
			this.source_buffer.highlight_syntax = true;
			this.load_saved_source ();

			var style_code =  Gtk.SourceStyleSchemeManager.get_default ();

			this.source_buffer.set_style_scheme (style_code.get_scheme ("builder-dark"));
			this.source_view.buffer = source_buffer;
			this.add (scrolled_window);

			this.set_syntax_highlighting ();
		}

		private void set_syntax_highlighting() {
			FileInfo? info = null;
			File file = File.new_for_path (FILE_PATH);
			try {
				info = file.query_info("standard::*", FileQueryInfoFlags.NONE, null);
			} catch (GLib.Error e) {}

			string mime_type = ContentType.get_mime_type (info.get_attribute_as_string (FileAttribute.STANDARD_CONTENT_TYPE));
			Gtk.SourceLanguageManager language_manager = new Gtk.SourceLanguageManager();
			this.source_buffer.set_language(language_manager.guess_language(FILE_PATH, mime_type));
		}

		private void load_saved_source (){
			string text;
			try {
				FileUtils.get_contents(FILE_PATH, out text);
			} catch (GLib.Error e) {
				text = "";
				stderr.printf("Error: %s\n", e.message);
			}

			this.source_buffer.text = text;

		}

	}
}
