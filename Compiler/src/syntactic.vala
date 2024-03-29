
/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * syntactic.vala
 * Copyright (C) 2015  <kmsiete@gmail.com>
 *
 * compiler is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * compiler is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gee;
using Compiler.Util;

namespace Compiler{

public class Syntactic : GLib.Object {
    private const string TAG = "SYNTACTIC";
    private Lexicon.Lexical lexical;
	public Semantic semantic { get; private set; }
	private Log log;
	private int start_column;
	private int start_line;
	 
	private int start_class_column;
	private int start_class_line;
	 
	public ArrayList <Token?> lexical_tokens { get; private set; }
	public ArrayList <Sentence?> syntactic_sentences { get; private set; }
	public string lexical_error { get; private set; }
	public SyntacticError error { get; private set; }
	 
	private string last_acces_mode;
	private string last_type;
	private string last_id;
	

	// Constructor
	public Syntactic (bool verbose = false, string transition_table_path, string reserved_words_path){
        this.log = new Log (true);
        error = SyntacticError.NONE;
        this.lexical = new Lexicon.Lexical ();
	    lexical.create_state_machine (transition_table_path);
	    lexical.add_reserved_words (reserved_words_path);
	}
	public void init_lexical (string source_path){
	    this.log.m (TAG,"Creando Lexical");
		lexical.create_source_manager (source_path);
		this.lexical_error = "";
		this.lexical.error = LexicalError.NONE;
	}
	public bool are_error (){
		 
		if (this.lexical.error == LexicalError.NONE 
		    && this.error == SyntacticError.NONE
		    &&  this.semantic.semantic_errors.size == 0)
			return true;
		else 
			return false;
	}
	public void check_syntax (){
		this.log.m (TAG,"CheckSyntax");
		this.lexical_tokens   = new ArrayList<Token?> ();
		this.syntactic_sentences = new ArrayList<Sentence?> ();
		this.semantic = new Semantic ();
		this.error = SyntacticError.NONE;
		this.class (this.next_token ());

		this.lexical_error = @"$(this.lexical.error)";
	}
	private Token next_token (){
		var token = Token ();
		token.type = Util.Type.NO_TYPE;
		token.line = 0;
		token.column = 0;
		token.lexema = "";
		if (this.lexical.has_more_tokens){
			this.lexical.next();
			token = this.lexical.token;
			log.m (TAG, @"$token");
			this.lexical_tokens.add (this.lexical.token);
		}
		return token;
	}

	private bool @class (Token token){
		var _token = token;
		this.start_class_column = _token.column;
		this.start_class_line = _token.line;
		if (this.access_mode (ref _token)){
			this.last_acces_mode = this.semantic.get_acces_mode (this.lexical.token.type);
			var _class_acces_token = this.lexical.token;
			if (this.next_token ().type == Util.Type.RW_CLASS){
				if (this.next_token ().type == Util.Type.ID){
				/// semantic
					var _class_token = this.lexical.token;
					this.semantic.check_length (this.lexical.token);

					/// end semantic
					if(this.heritage (this.next_token (), _class_token, _class_acces_token)){
						log.m (TAG, "herencia");
						_token = this.next_token ();
						this.start_column = _token.column;
						this.start_line   = _token.line;
						
						if (this.body (_token)){
							log.m (TAG, "end Body");
							if (this.lexical.token.type == Util.Type.CURLY_BRACKETS_C){
								this.create_sentence (SentenceFound.CLASS);
								_token = this.next_token ();

								if (this.access_mode (ref _token)){
									this.semantic.reset ();
									this.start_class_column = _token.column;
									this.start_class_line = _token.line;
									return this.class (_token);
								} else if (!this.lexical.has_more_tokens)
									return true;
								else{
									this.sentence_error ();
									this.error = SyntacticError.EXPECTED_ACCESS_MODE;
									return false;
								}
									
							} else {
								if (this.error == SyntacticError.NONE){
									this.sentence_error ();
									this.error = SyntacticError.EXPECTED_CURLY_BRACKETS_C;
								}
								return false;
							}	
						} else return false;
					} else return true;
				}else {
					this.sentence_error ();
					this.error = SyntacticError.EXPECTED_ID;
					return false;
				}
			} else {
				this.sentence_error ();
				this.error = SyntacticError.EXPECTED_RW_CLASS;
				return false;
			}
		} else {
			this.sentence_error ();
			this.error = SyntacticError.EXPECTED_ACCESS_MODE;
			return false;
		}
	}

	private bool heritage (Token token, Token class_token, Token _class_acces_token){
		if (token.type == Util.Type.RW_EXTENDS){
			if (this.next_token ().type == Util.Type.ID){
				log.m (TAG, @"visibility class $(this.last_acces_mode)");
				if (!this.semantic.symbols.has_key (class_token.lexema))
					this.semantic.add_class (class_token,
											 this.lexical.token.lexema,
											 _class_acces_token);
				else
					this.semantic.add_error (class_token,
					                         SemanticError.CLASS_SYMBOL_ALREADY_DEFINED);
				
				this.semantic.check_length (this.lexical.token);

				if (!this.semantic.symbols.has_key (this.lexical.token.lexema))
					this.semantic.add_error (this.lexical.token,
					                         SemanticError.CLASS_SYMBOL_NOT_FOUND);

				if (this.semantic.current_class == this.lexical.token.lexema)
					this.semantic.add_error (this.lexical.token,
					                         SemanticError.HERITAGE_OVER_SAME_CLASS);

				if (this.next_token ().type == Util.Type.CURLY_BRACKETS_O)
					return true;
				else return false;
			} else {
				this.sentence_error ();
				this.error = SyntacticError.EXPECTED_ID;
				return false;
			}
		} else if (token.type == Util.Type.CURLY_BRACKETS_O){
			if (!this.semantic.symbols.has_key (class_token.lexema))
				this.semantic.add_class (class_token,
										 "",
				                         _class_acces_token);
			else
				this.semantic.add_error (class_token,
				                         SemanticError.CLASS_SYMBOL_ALREADY_DEFINED);
			return true;
		}
		else{
			this.sentence_error ();
			this.error = SyntacticError.EXPECTED_CURLY_BRACKETS_O;
			return false;
		}
	}
	private bool body (Token token){
		var _token = token;
		if (this.access_mode (ref _token)){
			var _acces_mode = this.semantic.get_acces_mode (this.lexical.token.type);
			if (this.complement (this.next_token (), _acces_mode)){
				return true;
			} else return false;
		} else if (_token.type == Util.Type.CURLY_BRACKETS_C)
			return true;
		else return false;
	}

	private bool complement (Token token, string _acces_mode) {
		var _token = token;
		if (this.constant (_token, _acces_mode)){
			if (this.lexical.token.type == Util.Type.CURLY_BRACKETS_C){
				return true;
			}
			this.last_acces_mode = _acces_mode;
			log.m (TAG, "Ahora checamos propiedades");
			_token = this.lexical.token;
			if (this.type (ref _token)){ 
				this.last_type = this.lexical.token.lexema;
				if (this.next_token ().type == Util.Type.ID){
					this.semantic.check_length (this.lexical.token);
					this.semantic.check_symbol ( this.lexical.token);
					this.last_id = this.lexical.token.lexema;
					log.m (TAG, @"resto de atributos $(this.last_acces_mode)" );
					if (this.attribute (this.next_token (), this.last_acces_mode, this.last_type, this.last_id)){
						log.m (TAG, @"Ahora checamos metodos $(this.last_type)");
						if (this.method (this.lexical.token, this.last_acces_mode, this.last_type, this.last_id)){
							return true;
						} else return false;
					} else return true;
				} else {
					this.error = SyntacticError.EXPECTED_ID;
					this.sentence_error ();
					return false;
				}
			} return false;
		} else return false;
	}

	private bool constant (Token token, string _acces_mode){
		log.m (TAG, "constant -");
		var constants = new TreeMap <string,string> ();
		var _token = token;
		if (_token.type == Util.Type.RW_CONST){
			_token = this.next_token ();
			if (this.number_type (ref _token)){
				var _number_type = this.lexical.token.lexema;
				this.semantic.current_constant_type = this.lexical.token.type;
				if (this.next_token ().type == Util.Type.ID){
					///sematic
						this.semantic.check_length (this.lexical.token);
						this.semantic.check_symbol (this.lexical.token);

						var _id = this.lexical.token.lexema;
					//end semantic
					if (this.next_token ().type == Util.Type.EQUAL){
						_token = this.next_token ();
						if (this.number (ref _token)){
							
							constants.set (_id, this.lexical.token.lexema);
							this.semantic.check_constant_type (this.lexical.token);
							
							_token = this.next_token ();
							log.m (TAG, @"comma $(_token)");
							if (_token.type == Util.Type.COMMA)
								if (!this.type_value (_token, ref constants))
									return false;

							if (this.lexical.token.type == Util.Type.SEMICOLON){
								log.m (TAG, @"constente detectada $(lexical.token)");
								this.semantic.constant_count ++;
								if (this.semantic.constant_count > Semantic.MAX_NUM_CONSTANTS)
									this.semantic.add_error (lexical.token, SemanticError.CONSTANT_OVER_FLOW);
								
								this.create_sentence (SentenceFound.CONSTANT);
								this.semantic.add_constant (_number_type, _acces_mode, constants);

								_token = this.next_token ();
								if (this.access_mode (ref _token)){
									
									this.last_acces_mode = this.semantic.get_acces_mode (_token.type); 
										
									this.start_column = _token.column;  
									this.start_line   = _token.line;
									var _visibility = this.semantic.get_acces_mode (this.lexical.token.type);
									log.m (TAG, @"probalbe constante $(lexical.token)");
									if (this.next_token ().type == Util.Type.RW_CONST){
										return this.complement (this.lexical.token, _visibility);
									} else {
										log.m (TAG, @"No es constante $(lexical.token)");
										return true;
									}
								} else if (_token.type == Util.Type.CURLY_BRACKETS_C){
									return true;
								}
								else return false;
							} else {
								this.error = SyntacticError.EXPECTED_SEMICOLON;
								this.sentence_error ();
								return false;
							}
						} else return false;
					} else {
						this.error = SyntacticError.EXPECTED_EQUAL;
						this.sentence_error ();
						return false;
					}
				} else {
					this.error = SyntacticError.EXPECTED_ID;
					this.sentence_error ();
					return false;
				}
			} else return false;
		} else return true;
	}
	private bool attribute (Token token, string _acces_mode, string _type, string id){
		var _token = token;
		var _id = new ArrayList <string> ();
		_id.add (id);
		if (_token.type == Util.Type.SEMICOLON){
			log.m (TAG,"attributo detectado" );
			this.semantic.attibute_count ++;
			if (this.semantic.attibute_count > Semantic.MAX_NUM_ATTRIBUTES)
				this.semantic.add_error (lexical.token, SemanticError.ATTRIBUTE_OVER_FLOW);
			
			this.semantic.add_attribute (_type, _acces_mode, _id);
			this.create_sentence (SentenceFound.ATTRIBUTE);
			return this.attribute_way (this.next_token ());
		} else if (_token.type == Util.Type.COMMA){
			if (this.next_id (_token, ref _id)){
				if (this.lexical.token.type == Util.Type.SEMICOLON){
					this.semantic.attibute_count ++;
					if (this.semantic.attibute_count > Semantic.MAX_NUM_ATTRIBUTES)
						this.semantic.add_error (lexical.token, SemanticError.ATTRIBUTE_OVER_FLOW);
					
					this.semantic.add_attribute (_type, _acces_mode, _id);
					
					log.m (TAG,"attributo detectado" );
					this.create_sentence (SentenceFound.ATTRIBUTE);
					return this.attribute_way (this.next_token ());
				} else if (this.lexical.token.type == Util.Type.PARENTHESIS_O){
					log.m (TAG, "no es attributo");
					return true;
				}
				else return false;
			}else {
				log.m (TAG,"" );
				this.error = SyntacticError.EXPECTED_SEMICOLON;
				this.sentence_error ();
				return false;
			}
		} else if (_token.type == Util.Type.PARENTHESIS_O){
			log.m (TAG, "no es attributo");
			return true;
		}else if (_token.type == Util.Type.CURLY_BRACKETS_C){
			log.m (TAG, "finclas");
			return true;
		} else {
			this.error = SyntacticError.EXPECTED_SEMICOLON;
			this.sentence_error ();
			return false;
		}
		
	}
	private bool attribute_way (Token token){
		var _token = token;
		log.m (TAG,@"otro atributo $_token" );
		if (this.access_mode (ref _token)){
			this.last_acces_mode = this.semantic.get_acces_mode (_token.type);
			this.start_column = _token.column;
			this.start_line   = _token.line;
			_token = this.next_token ();
			if (this.type (ref _token)){
				this.last_type = _token.lexema;
				if (this.next_token ().type == Util.Type.ID){
					this.semantic.check_length (this.lexical.token);
					this.semantic.check_symbol ( this.lexical.token);

					this.last_id = this.lexical.token.lexema; 
					return this.attribute (this.next_token (), 
					                       this.last_acces_mode, 
					                       this.last_type,
					                       this.last_id);
				} else {
					this.error = SyntacticError.EXPECTED_ID;
					this.sentence_error ();
					return false;
				}
			} else return false;
		} else return false;
	}
	private bool method (Token token, string _acces_mode, string _type, string name){
		log.m (TAG,@"metodo $token" );
		 var args = new TreeMap <string, string> ();
		if (token.type == Util.Type.PARENTHESIS_O){
			
			this.semantic.method_args.clear ();
			if (this.argument (this.next_token (), ref args)){
				log.m (TAG,@"metodo $(lexical.token)" );
				if (this.lexical.token.type == Util.Type.PARENTHESIS_C){
					
					if (this.next_token ().type == Util.Type.SEMICOLON){
						this.semantic.method_count ++;
						if (this.semantic.method_count > Semantic.MAX_NUM_METHODS)
							this.semantic.add_error (this.lexical.token, SemanticError.METHOD_OVER_FLOW);

						this.semantic.add_method (name, _type, _acces_mode, args);
						
						log.m (TAG,@"metodo encontrado");
						this.create_sentence (SentenceFound.METHOD);
						return this.method_way (this.next_token ());
					} else {
						log.m (TAG,@"falto semicolon $(lexical.token)");
						this.error = SyntacticError.EXPECTED_SEMICOLON;
						this.sentence_error ();
						return false;
					}
				} else {
					this.error = SyntacticError.EXPECTED_PARENTHESIS_C;
					this.sentence_error ();
					return false;
				}
			} else {
				if (this.error == SyntacticError.NONE){
					this.error = SyntacticError.EXPECTED_PARENTHESIS_C;
					this.sentence_error ();
				}
				return false;
			}
		} else {
			this.error = SyntacticError.EXPECTED_PARENTHESIS_O;
			this.sentence_error ();
			return false;
		}
	}
	private bool method_way (Token token){
		var _token = token;
		if (this.access_mode (ref _token)){
			this.start_line = _token.line;
			this.start_column = _token.column;
			this.last_acces_mode = this.semantic.get_acces_mode (_token.type);
			
			_token = this.next_token ();
			
			if (this.type (ref _token)){
				this.last_type = _token.lexema;
				if (this.next_token ().type == Util.Type.ID){
					this.semantic.check_length (this.lexical.token);
					this.semantic.check_symbol ( this.lexical.token);
					this.last_id = this.lexical.token.lexema;
					_token = this.next_token ();
					if (_token.type == Util.Type.PARENTHESIS_O)
						return this.method (_token, this.last_acces_mode, this.last_type, this.last_id);
					else if (_token.type == Util.Type.CURLY_BRACKETS_C)
						return true;
					else {
						this.error = SyntacticError.EXPECTED_PARENTHESIS_O;
						this.sentence_error ();
						return false;
					}
				} else {
					this.error = SyntacticError.EXPECTED_ID;
					this.sentence_error ();
					return false;
				}
			} else return false;
		}else return true;
	}
	
	private bool next_id (Token token, ref ArrayList <string> _id){
		var _token = token;
		log.m (TAG, @"nextid $token");
		if (_token.type == Util.Type.COMMA){
			
			if (this.next_token ().type == Util.Type.ID ){
				this.semantic.attibute_count ++;
				if (this.semantic.attibute_count > Semantic.MAX_NUM_ATTRIBUTES)
					this.semantic.add_error (lexical.token, SemanticError.ATTRIBUTE_OVER_FLOW);
				
				_id.add (this.lexical.token.lexema);
				this.semantic.check_length (this.lexical.token);
				this.semantic.check_symbol ( this.lexical.token);
			
				_token = this.next_token ();
				if (_token.type == Util.Type.COMMA)
					return this.next_id (_token, ref _id);
				else if (_token.type == Util.Type.SEMICOLON)
					return true;
				else
					return false;
			} else {
				this.error = SyntacticError.EXPECTED_ID;
				this.sentence_error ();
				return false;
			}
		} else return false;
	}

	private bool type_value (Token token, ref TreeMap <string,string> constants){
		var _token = token;
		log.m (TAG, "type value way");
		if (_token.type == Util.Type.COMMA){
			if (this.next_token ().type == Util.Type.ID){
				
				this.semantic.check_length (this.lexical.token);
				this.semantic.check_symbol ( this.lexical.token);
				var _id = this.lexical.token.lexema;
				
				if (this.next_token ().type == Util.Type.EQUAL){
					_token = this.next_token ();
					if (this.number (ref _token)){
						this.semantic.check_constant_type (this.lexical.token);
						
						this.semantic.constant_count ++;
						if (this.semantic.constant_count > Semantic.MAX_NUM_CONSTANTS)
							this.semantic.add_error (lexical.token, SemanticError.CONSTANT_OVER_FLOW);

						constants.set (_id, _token.lexema);
						
						_token = this.next_token ();
						if (_token.type == Util.Type.COMMA)
							return this.type_value ( token,ref constants);
						else if (_token.type == Util.Type.SEMICOLON)
							return true;
						else return false;
					}else return false;
				}else {
					this.sentence_error ();
					this.error = SyntacticError.EXPECTED_EQUAL;
					return false;
				}
			}else {
				this.sentence_error ();
				this.error = SyntacticError.EXPECTED_ID;
				return false;
			}
		} else
			return false;
	}

	private bool argument (Token token, ref TreeMap <string, string> args){
		var _token = token;
		if (this.type (ref _token, false)){
			var _type = _token.lexema;
			if (this.next_token ().type == Util.Type.ID){
				args.set (this.lexical.token.lexema, _type);
				
				this.semantic.check_length (this.lexical.token);
				this.semantic.check_argument (this.lexical.token);
				
				_token = this.next_token ();
				log.m (TAG, @"argument $_token");
				if (_token.type == Util.Type.COMMA)
					return this.argument_way (_token, ref args);
				else if (_token.type == Util.Type.PARENTHESIS_C)
					return true;
				else return false;
			} else {
				this.error = SyntacticError.EXPECTED_ID;
				this.sentence_error ();
				return false;
			}
		} else
			return true;
	}

	private bool argument_way (Token token, ref TreeMap <string, string> args){
		var _token = token;
		if (_token.type == Util.Type.COMMA){
			_token = this.next_token ();
			if (this.type (ref _token)){
				var _type = _token.lexema;
				if (this.next_token ().type == Util.Type.ID){
					args.set (this.lexical.token.lexema, _type);
					
					this.semantic.check_argument (this.lexical.token);
					this.semantic.check_length (this.lexical.token);
					
					_token = this.next_token ();
					if (_token.type == Util.Type.COMMA)
						return this.argument_way (_token, ref args);
					else if (_token.type == Util.Type.PARENTHESIS_C)
						return true;
					else return false;
				} else {
					this.error = SyntacticError.EXPECTED_ID;
					this.sentence_error ();
					return false;
				}
			} else return false;
		} else return false;
	}
	//terminales

	private bool number (ref Token token){
		if (token.type == Util.Type.INTEGER || token.type == Util.Type.REAL){
			this.semantic.check_length (token);
			return true;
		}
		else{
			this.sentence_error ();
			this.error = SyntacticError.EXPECTED_NUMBER;
			return false;
		}
	}

	private bool number_type (ref Token token){
		if (token.type == Util.Type.RW_INT ||token.type == Util.Type.RW_FLOAT)
			return true;
		else {
			this.sentence_error ();
			this.error = SyntacticError.EXPECTED_NUMBER_TYPE;
			return false;
		}
	}

	private bool type (ref Token token, bool set_error = true){
		if (token.type == Util.Type.RW_CHAR ||
		    token.type == Util.Type.RW_INT ||
		    token.type == Util.Type.RW_FLOAT ||
		    token.type == Util.Type.RW_STRING ||
		    token.type == Util.Type.RW_VOID ||
		    token.type == Util.Type.ID){
			if (token.type == Util.Type.ID){
				this.semantic.check_length (token);
				this.semantic.check_type ( this.lexical.token);
			}
			return true;
		}
		
		else {
			if (set_error){
				this.sentence_error ();
				this.error = SyntacticError.EXPECTED_TYPE;
				return false;
			}
			else return false;
		}
	}
	private bool access_mode (ref Token token){
		if (token.type == Util.Type.RW_PUBLIC || token.type == Util.Type.RW_PROTECTED || token.type == Util.Type.RW_PRIVATE)
			return true;
		else
			return false;
	}
	private void create_sentence (SentenceFound sentence_found){
		var column   = this.lexical.token.column + this.lexical.token.lexema.char_count ();
		Sentence sentence;
		if (sentence_found == SentenceFound.CLASS){
			sentence = Sentence (this.start_class_line,
								 this.start_class_column,
								 this.lexical.token.line,
								 column,
								 sentence_found);
		} else{
			sentence = Sentence (this.start_line,
								 this.start_column,
								 this.lexical.token.line,
								 column,
								 sentence_found);
		}
		this.syntactic_sentences.add (sentence);
	}
	private void sentence_error (){
		var column   = this.lexical.token.column + this.lexical.token.lexema.char_count ();
		var sentence = Sentence (this.start_line,
								 this.start_column,
								 this.lexical.token.line,
								 column,
								 SentenceFound.NONE);
		this.syntactic_sentences.add (sentence);
	}
}

}//namespace Compiler
 
