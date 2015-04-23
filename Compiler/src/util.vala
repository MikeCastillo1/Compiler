/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * util.vala
 * Copyright (C) 2015 Miguel Ange Castillo S??nchez <kmsiete@gmail.com>
 *
 */
using Gee;

namespace Compiler.Util{

	public const string LEXICAL_TAG = "LEXICAL_TAG";
	public const string SYNTACTIC_TAG = "SYNTACTIC_TAG";
	public const string SEMANTIC_TAG = "SEMANTIC_TAG";
	static const string RESERVED_WORD = "RW";
	public const string TRANSITION_PATH = "conf/transition_table4.tt";
	public const string FILE_PATH = "conf/source.java";
	public const string RW_PATH = "conf/reserved_words.rw";
	public const string LOG_ICON  = "res/icon/log.png";
	public const string PLAY_ICON = "res/icon/play.png";
	public const string DEBUGGER_ICON = "res/icon/debugger.png";

	//checa que el archivo exista
	static bool file_exists (File file){
		if (!file.query_exists ()) {
		    stderr.printf ("File '%s' doesn't exist.\n", file.get_path ());
		    return false;
		}
		return true;
	}
	//all type errors
	public enum SyntacticError{
		EXPECTED_ACCESS_MODE,
		EXPECTED_TYPE,
		EXPECTED_NUMBER_TYPE,
		EXPECTED_NUMBER,
		EXPECTED_ID,
		EXPECTED_COMMA,
		EXPECTED_RW_CLASS,
		EXPECTED_PARENTHESIS_C,
		EXPECTED_PARENTHESIS_O,
		EXPECTED_EQUAL,
		EXPECTED_SEMICOLON,
		EXPECTED_CURLY_BRACKETS_O,
		EXPECTED_CURLY_BRACKETS_C,
		NONE
	}
	public enum LexicalError{
		NO_IN_ALPHABET,
		NO_GENERATE_PATTERN,
		INCOMPLETE_PATTERN,
		NONE
	}
	public enum Error{
		FILE_NOT_EXIST,
		CAN_NOT_READ_FILE,
		TRANSITION_FILE,
		CORRUPT_FILE,
		NO_STATE_MACHINE,
		NO_SOURCE,
		OK
	}
	public enum SemanticError {
		EXPECTED_INT,
		EXPECTED_FLOAT,

		HERITAGE_OVER_SAME_CLASS,

		CLASS_SYMBOL_NOT_FOUND,
		ID_SYMBOL_NOT_FOUND,
		
		CLASS_SYMBOL_ALREADY_DEFINED,
		ID_SYMBOL_ALREADY_DEFINED,
		CLASS_NAME_CAN_NOT_BE_USED_AS_ID_NAME,

		ARGUMENT_ALREADY_DEFINED,
		
		NUMBER_TOO_LARGE,
		ID_TOO_LARGE,

		CONSTANT_OVER_FLOW,
		ATTRIBUTE_OVER_FLOW,
		METHOD_OVER_FLOW,
			
		INCORRECT_ELEMENTS_ORDER,
		OK
	}
	//
	public enum Type{
		RW_VOID,
		RW_FLOAT,
		RW_INT,
		RW_CHAR,
		RW_STRING,

		RW_PUBLIC,
		RW_PRIVATE,
		RW_PROTECTED,
		RW_CONST,

		RW_EXTENDS,
		RW_CLASS,

		ID,
		INTEGER,
		REAL,
		CLASS,
		SEMICOLON,
		COMMA,
		PARENTHESIS_O,
		PARENTHESIS_C,
		CURLY_BRACKETS_O,
		CURLY_BRACKETS_C,
		EQUAL,
		NO_TYPE;

		public static Type parse_type (string name) {
		    EnumClass enumc = (EnumClass) typeof (Type).class_ref ();
		    unowned EnumValue? eval = enumc.get_value_by_name (name);
		    return (Type) eval.value;
		}
	}

	public enum SentenceFound {
		CLASS,
		CONSTANT,
		ATTRIBUTE,
		METHOD,
		NONE
	}
	public struct ClassDefinition{
		public string name;
		public string heritage;
		public string acces_mode;

		public ArrayList <Constant?> constants; 
		public ArrayList <Attribute?> attributes; 
		public ArrayList <Method?> methods;
		
		public string header (){
			if (heritage.char_count() == 0)
				return @"$acces_mode $name";
			else
				return @"$acces_mode $name : $heritage";
		}
		public string to_string (){
			string result = this.header ();
				
			foreach (var c in constants)
				result += @"$c";

			foreach (var a in attributes)
				result += @"$a";

			foreach (var m in methods)
				result += @"$m";
			
			return result; 
		}
	}
	public struct Constant {
		public string acces_mode;
		public string type;
		public TreeMap <string,string> constants; //name : value

		public Constant (string type, string acces_mode, TreeMap <string,string> constants){
			this.type = type;
			this.acces_mode = acces_mode;
			this.constants = constants;
		}
		public string to_string (){
			string entries = "";
			foreach (var @value in constants.entries)
				entries += @"$acces_mode $(@value.key.up()) : $type = $(@value.value)"; 
				
			return entries;
		}
	}
	public struct Attribute {
		public string acces_mode;
		public string type;		
		public ArrayList <string> id;

		public Attribute (string type, string acces_mode, ArrayList <string> id){
			this.type = type;
			this.acces_mode = acces_mode;
			this.id = id;
		}
		public string to_string (){
			string entries = "";
			foreach (var item in id)
				entries += @"$acces_mode $item : $type";
			return entries;
		}
	}
	public struct Method {
		public string name;
		public string return_type;
		public string acces_mode;

		public TreeMap <string, string> args;

		public Method (string acces_mode, string name, string return_type, TreeMap <string, string> args){
			this.name = name;
			this.return_type = return_type;
			this.acces_mode = acces_mode;
			this.args = args;
		}
		public string to_string (){
			string _args = "";
			
			foreach (var items in args.entries)
				_args += @"$(items.key) : $(items.value),";
			if (_args.char_count () > 3)
				_args = _args.splice (_args.char_count()-1, _args.char_count());
			return @"$acces_mode $name($_args): $return_type";
		}
	}
	public struct SemanticErrorLocalization{
		public Token? token;
		public SemanticError error;
		public SemanticErrorLocalization (Token token, SemanticError error){
			this.token = token;
			this.error = error;
		}
	}
	 
	public struct Sentence {
		public int start_line;
		public int start_column;
		public int end_line;
		public int end_column;
		public SentenceFound sentence_found;
		public string to_string (){
			var _s = @"$sentence_found".splice (0,23);
			return @"[$_s]::[<$(this.start_line+1),$(this.start_column)>,<$(this.end_line)-$(this.end_column)>]";
		}
		public Sentence (int start_line,
						 int start_column,
						 int end_line,
						 int end_column,
						 SentenceFound sentence_found){
			this.start_line   = start_line;
			this.start_column = start_column;
			this.end_line     = end_line;
			this.end_column   = end_column;
			this.sentence_found = sentence_found;
		}
	}

	public struct MapType{
		string key;
		string? @value;
		public MapType (string key, string? @value){
		    this.key = key;
		    this.value = @value;
		}
		public string to_string (){
		    return "<"+key+","+@value+">";
		}
	}

	public struct Token{
		public Type type;
		public int line;
		public int column;
		public string lexema;
		public string to_string (){
			string stype = @"$type".splice (0,19,null);
			return @"[$stype]::{$lexema}::<$(line+1),$(column+1)>";
		}
	 }

	public struct State {
		//id del estado inicial
		public int state_id;
		// alfabeto, edo puede ser null si no lleva a ningun lado, puede ser un tipo
		// si es un estado final
		public ArrayList <MapType?> transition_state;

		public string to_string (){
			string result = @"$state_id\n";
			foreach (var item in transition_state)
			    result += @"$item\n";
			return result;
		}
	}

}//namespace Compiler
