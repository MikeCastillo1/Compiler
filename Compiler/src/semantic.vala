/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * semantic.vala
 * Copyright (C) 2015 Miguel Angel Castillo Sanchez <kmsiete@gmail.com>
 *
 */
using Compiler.Util;
using Gee;

namespace Compiler {

	public class Semantic : GLib.Object {
		private const string TAG = "SEMANTIC";
		private Log log;

		public static const int MAX_ID_LENGTH      = 7;
		public static const int MAX_NUM_LENGTH     = 7;
		public static const int MAX_NUM_CONSTANTS  = 3;
		public static const int MAX_NUM_ATTRIBUTES = 3;
		public static const int MAX_NUM_METHODS    = 3;
		public static const int MAX_NUM_CLASSES    = 10;
		private const string PUBLIC_CLASS_NAME = "Source";
	 
		public bool has_attribute { get; set; }
		public bool has_method { get; set; }
		public TreeMap<string, TreeSet<string> > symbols { get; set; }
		public TreeMap<string,ClassDefinition?> classes { get; private set; }
		public ArrayList <string> current_definition { get; set; }
		public LinkedList <string> method_args { get; set; }
		
		public string current_class { get; private set; }
	 
		public int constant_count { get; set; }
		public int attibute_count { get; set; }
		public int method_count   { get; set; }
		public Util.Type current_constant_type { get; set; }
		private int8 public_cass_count;
	 
	 
		public ArrayList <SemanticErrorLocalization?> semantic_errors {get; private set;}
	 
		public Semantic (bool verbose = false) {
			this.log = new Log (verbose);
			this.has_attribute = false;
			this.has_method = false;
			this.has_attribute = false;
			
			this.constant_count = 0;
			this.attibute_count = 0;
			this.method_count   = 0;
			this.public_cass_count = 0;
			this.symbols = new TreeMap < string, TreeSet <string> > ();
			this.classes = new TreeMap <string, ClassDefinition?> (); 
			this.semantic_errors = new ArrayList<SemanticErrorLocalization?> ();
			this.method_args = new LinkedList<string> ();
		}
		public void reset (){   
			this.constant_count = 0;
			this.attibute_count = 0;
			this.method_count   = 0;
			this.has_attribute = false;
			this.has_method = false;
		}
		public void add_class (Token class_token,string heritage, Token visibility){
			var _visibility = this.get_acces_mode (visibility.type);
			if (_visibility == "+"){
				
				this.public_cass_count ++;
				if (this.public_cass_count == 1 && class_token.lexema != PUBLIC_CLASS_NAME)
					this.add_error (class_token, SemanticError.PUBLIC_CLASS_MUST_BE_NAMED_LIKE_FILE);
				
					
				if (this.public_cass_count > 1)
					this.add_error (visibility, SemanticError.PUBLIC_CLASS_OVERFLOW);
			}

			this.current_class = class_token.lexema;
			this.symbols.set (class_token.lexema, new TreeSet<string> ());
			var new_class = ClassDefinition ();
			new_class.name = class_token.lexema;
			new_class.acces_mode = _visibility;
			new_class.heritage = heritage;
			new_class.constants  = new ArrayList <Constant?> ();
			new_class.attributes = new ArrayList <Attribute?> ();
			new_class.methods    = new ArrayList <Method?> ();
			this.classes.set (class_token.lexema, new_class);
		}
		public void add_constant (string type, string acces_mode, TreeMap <string,string> constants){
			var @class = this.classes.get (this.current_class);
			var new_constant = Constant (type, acces_mode, constants);
			@class.constants.add (new_constant);
			
			log.m (TAG, @"$(@class)");
		}
		public void add_attribute (string type, string acces_mode, ArrayList <string> _id){
			var @class = this.classes.get (this.current_class);
			var new_attribute = Attribute (type, acces_mode, _id);
			@class.attributes.add (new_attribute);
			log.m (TAG, @"$(@class)");
		}
		public void add_method (string name, string type, string acces_mode, TreeMap <string, string> args){
			var @class = this.classes.get (this.current_class);
			var new_method = Method (acces_mode, name, type, args);
			@class.methods.add (new_method);
			log.m (TAG, @"$(@class)");
		}
		public void add_error (Token token, SemanticError error){
			log.m (TAG, @"add_error: $error, $token");
			var semantic_error = SemanticErrorLocalization (token, error);
			this.semantic_errors.add (semantic_error);
		}
		public void check_length (Token token){
			if (token.type == Util.Type.ID){
				log.m (TAG, @"$token");
				if (token.lexema.char_count () >= MAX_ID_LENGTH ){
					this.add_error (token, 
									SemanticError.ID_TOO_LARGE);
				} 
			} else if (token.type == Util.Type.INTEGER || token.type == Util.Type.REAL){
				log.m (TAG, @" $token");
				if (token.lexema.char_count () >= MAX_NUM_LENGTH){
					this.add_error (token, 
								    SemanticError.NUMBER_TOO_LARGE);
				}
			}
		}   

		public void check_symbol (Token token){
			if (this.symbols.has_key (token.lexema)){
				this.add_error (token, SemanticError.CLASS_NAME_CAN_NOT_BE_USED_AS_ID_NAME);
			} else {
				log.m (TAG, @"otro caso name: $token");
				var class_symbols = this.symbols.get (this.current_class) as TreeSet<string> ;
				if (class_symbols.contains (token.lexema)){
					this.add_error (token, SemanticError.ID_SYMBOL_ALREADY_DEFINED);
				} else {
					class_symbols.add (token.lexema);
				}
			}
		}
		public void check_type (Token token){
			if (!this.symbols.has_key (token.lexema))
				this.add_error (token, 
				                SemanticError.CLASS_SYMBOL_NOT_FOUND);
		}
		public void check_argument (Token token){
			if (this.symbols.has_key (token.lexema)){
				this.add_error (token, SemanticError.CLASS_NAME_CAN_NOT_BE_USED_AS_ID_NAME);
			} else if (this.method_args.contains (token.lexema))
				this.add_error (token, 
				                SemanticError.ARGUMENT_ALREADY_DEFINED);
			else 
				this.method_args.add (token.lexema);
		}
		public void check_constant_type (Token token){
			switch (token.type){
				case Util.Type.INTEGER:
					if (this.current_constant_type != Util.Type.RW_INT)
						this.add_error (token, SemanticError.EXPECTED_FLOAT);
					break;
				case Util.Type.REAL:
					if (this.current_constant_type != Util.Type.RW_FLOAT)
						this.add_error (token, SemanticError.EXPECTED_INT);
					break;
				default: break;
			}
		}
	 
		 public string get_acces_mode (Util.Type acces_mode){
			 string access = "";

			 switch (acces_mode){
				case Util.Type.RW_PUBLIC:
					access = "+";
					break;
				case Util.Type.RW_PRIVATE:
					access = "-";
					break;
				case Util.Type.RW_PROTECTED:
					 access = "#";
					 break;
				default: break;
			 }
			 return access;
		 }
	}
}
