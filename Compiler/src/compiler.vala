/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main.c
 * Copyright (C) 2015 Miguel Angel Castillo Sanchez, Marlene Espinosa Chavez <kmsiete@gmail.com>
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

using GLib;
using Gtk;
using Compiler.Util;
using Gee;

namespace Compiler.UI{

	public class Main : ApplicationWindow {

	/*
	 * Uncomment this line when you are done testing and building a tarball
	 * or installing
	 */
	//const string UI_FILE = Config.PACKAGE_DATA_DIR + "/ui/" + "compiler.ui";
	const string SOURCE  = "conf/test.txt";


	protected HeaderBar header_bar;
	private Revealer log_revealer;
	private Revealer source_revealer;
	private Overlay log_overlay;
	private Box main_box;
	private Box draw_box;
	private ToggleButton log_button;
	private Button debugger_button;
	private Button play_button;
	private Button next_button;
	private Button prev_button;
	private LogOut log_out;
	private SourceCode source_code;
	private Compiler.Syntactic syntactic;
	private Blueprint blueprint;
	private Stack main_stack;
	private bool saved;
	private MenuButton config_button;
	private bool are_there_error;
	

	public Main ()
	{
		this.main_stack = new Stack ();
		this.main_stack.transition_duration = 700;
		this.main_stack.transition_type = StackTransitionType.SLIDE_LEFT_RIGHT;
		this.add (main_stack);
		//test syntactic
		this.set_default_size (1200, 700);
		this.main_box = new Box (Gtk.Orientation.HORIZONTAL, 0);
		this.main_box.homogeneous  = false;
		this.main_stack.add_named (main_box, "SOURCE");

		this.draw_box = new Box (Gtk.Orientation.HORIZONTAL, 0);
		this.draw_box.expand = true;
		this.main_stack.add_named (this.draw_box, "DRAW");

		this.source_revealer = new Revealer ();
		this.source_revealer.transition_type = RevealerTransitionType.SLIDE_RIGHT;
		this.source_revealer.hexpand = true;
		this.source_revealer.transition_duration = 350;
		this.source_revealer.reveal_child = true;

		this.source_code = new SourceCode ();
		this.source_code.source_buffer.changed.connect (on_source_buffer_changed);
		this.source_revealer.add (source_code);

		this.log_revealer = new Revealer ();
		this.log_revealer.transition_type = RevealerTransitionType.SLIDE_RIGHT;
		this.log_revealer.transition_duration = 350;
		this.log_revealer.halign  = Gtk.Align.END;

		this.log_out = new LogOut ();
		this.log_out.source_buffer = this.source_code.source_buffer;
		this.log_out.init_iters ();
		this.log_revealer.add (log_out);

		this.log_overlay = new Overlay ();
		this.log_overlay.add (source_revealer);
		this.log_overlay.add_overlay (log_revealer);
		this.main_box.add (log_overlay);

		this.play_button = new Button ();
		this.play_button.image = new Image.from_file (PLAY_ICON);
		this.play_button.clicked.connect (on_play_button_clicked);
		this.play_button.relief = ReliefStyle.NONE;

		this.log_button = new ToggleButton ();
		this.log_button.image = new Image.from_file (LOG_ICON);
		this.log_button.toggled.connect (on_log_button_toggle);
		this.log_button.relief = ReliefStyle.NONE;

		this.debugger_button = new Button ();
		this.debugger_button.image = new Image.from_file (DEBUGGER_ICON);
		this.debugger_button.relief = ReliefStyle.NONE;
		this.debugger_button.clicked.connect (on_debugger_button_clicked);

		this.syntactic = new Compiler.Syntactic (false,TRANSITION_PATH, RW_PATH);

		this.next_button = new Button ();
		this.next_button.clicked.connect (()=>{
			this.main_stack.set_visible_child_name ("SOURCE");
		});
		this.next_button.relief = ReliefStyle.NONE;
		this.next_button.add (new Arrow (ArrowType.LEFT,  Gtk.ShadowType.ETCHED_IN));

		this.prev_button = new Button ();
		this.prev_button.clicked.connect (()=>{
			this.main_stack.set_visible_child_name ("DRAW");
		});
		this.prev_button.relief = ReliefStyle.NONE;
		this.prev_button.add (new Arrow (ArrowType.RIGHT,  Gtk.ShadowType.ETCHED_IN));

		/** Menu */
		this.config_button = new MenuButton ();

		this.title = "source.java";

		this.saved = true;
		this.are_there_error = false;

		this.header_bar = new Gtk.HeaderBar ();
		this.header_bar.set_show_close_button (true);
		this.header_bar.title = this.title;
		this.header_bar.pack_start (this.play_button);
		this.header_bar.pack_start (this.debugger_button);
		this.header_bar.pack_end (this.log_button);
		this.header_bar.pack_end (this.prev_button);
		this.header_bar.pack_end (this.next_button);
		this.set_titlebar (this.header_bar);

		this.key_press_event.connect(on_key_pressed);
		//moviemiento del cursor
		this.source_code.source_buffer.notify.connect ( (s,p) =>{
			var offset = this.source_code.source_buffer.cursor_position;
			TextIter text_iter;
			this.source_code.source_buffer.get_iter_at_offset (out text_iter, offset);
			//text_iter.get_chars_in_line ()
			this.header_bar.subtitle = @"<$(text_iter.get_line()+1),$(text_iter.get_line_offset ()+1)>";
		});

		this.show_all ();
	}
	private void on_log_button_toggle (){
		//this.main_box.add (log_revealer);
		if (!this.log_revealer.reveal_child)
			this.log_revealer.reveal_child = true;
		else{
			this.log_revealer.reveal_child = false;
			this.log_out.clean_tags ();
			this.log_out.unselect_rows ();
		}
	}
	private void save (){
		if (!this.saved){
			try {
				FileUtils.set_contents(FILE_PATH, this.source_code.text);
			} catch (GLib.Error error) {
				stderr.printf("Error: %s\n", error.message);
			}
			this.saved = true;
			this.header_bar.title = "source.java";
		}
	}
	
	private void on_play_button_clicked (){
		this.save ();
		on_debugger_button_clicked ();		
		if (this.are_there_error){
			var class_array = new ArrayList <ClassDefinition?> ();
			class_array.add_all (this.syntactic.semantic.classes.values);
			this.draw_box.remove (this.blueprint);
			this.blueprint = new Blueprint (class_array);
			this.draw_box.add (blueprint);
			this.draw_box.show_all ();
			this.main_stack.set_visible_child_name ("DRAW");
		}
	}
	private void on_debugger_button_clicked (){
		this.syntactic.init_lexical (FILE_PATH);
		this.syntactic.check_syntax ();
		this.log_out.unselect_rows ();
		this.log_out.remove_rows ();
		
		this.log_out.lexical_tokens = this.syntactic.lexical_tokens;
		this.log_out.lexical_error  = this.syntactic.lexical_error;

		this.log_out.syntactic_sentences = this.syntactic.syntactic_sentences;
		this.log_out.syntactic_error  = @"$(this.syntactic.error)";

		this.log_out.semantic_errors = this.syntactic.semantic.semantic_errors;

		this.log_out.update ();
		this.log_revealer.reveal_child = true;

		this.are_there_error = this.syntactic.are_error();
	}
	private void on_source_buffer_changed (){
		this.saved = false;
		this.header_bar.title = "*source.java";
		this.log_revealer.reveal_child = false;
		this.log_out.clean_tags ();
		this.log_out.unselect_rows ();
	}
	private bool on_key_pressed (Gdk.EventKey key){
		if (key.keyval == Gdk.Key.@s){
			this.save ();
		}
		return false;
	}
	[CCode (instance_pos = -1)]
	public void on_destroy (Widget window)
	{
		Gtk.main_quit();
	}

	static int main (string[] args)
	{
		Gtk.init (ref args);
		var app = new Main ();

		Gtk.main ();

		return 0;
	}
	}
}
