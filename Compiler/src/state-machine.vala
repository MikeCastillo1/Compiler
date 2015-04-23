/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * state-machine.vala
 * Copyright (C) 2015 Miguel Angel Castillo S??nchez <kmsiete@gmail.com>
 *
 */
using Gee;
using Compiler.Util;

namespace Compiler.Lexicon{

public class StateMachine : GLib.Object {

    private const string TAG = "STATE_MACHINE";
    
    public Compiler.Util.Error error { get; private set; }
    public string? token_type { get; set; }
    private State state;
    private ArrayList<string> alphabet;
    
    private ArrayList<State?> transition_array;
    private ArrayList<MapType?> pattern;
	private Log log;
	 
    public int state_id { 
		get { return state.state_id; }
		private set {}
	}
    
	// Constructor
    public StateMachine (string transition_table_path, bool verbose = false) {
		this.log = new Log (verbose);
		
        var preprocess_transition_table = new ArrayList<string> ();
        File transition_table_file      = File.new_for_path (transition_table_path);
        
        if (!file_exists ( transition_table_file ))
            this.error = Compiler.Util.Error.FILE_NOT_EXIST;
            
        try{
        
            var transition_table_dis = new DataInputStream (transition_table_file.read ());
            string transition_state_line;
            
			while ((transition_state_line = transition_table_dis.read_line (null)) != null )
				preprocess_transition_table.add (transition_state_line);
				
		    this.error = Compiler.Util.Error.OK;
		    
        } catch (GLib.Error e){
        
		    stderr.printf ("error %s\n", e.message);
		    this.error = Compiler.Util.Error.CAN_NOT_READ_FILE;
		    
		}
		
		if (this.error == Compiler.Util.Error.OK){
		
		    //Log.m (TAG, "Creando la maquina de estados");
            if (!create_state_machine (ref preprocess_transition_table))
                error = Compiler.Util.Error.TRANSITION_FILE;
            
            this.state = transition_array [0];
            this.pattern = new ArrayList<MapType?> ();
        }
        this.token_type  = null;
	}

	public bool is_in_alphabet (unichar @unichar){
	
	    if ("letter" in alphabet && @unichar.isalpha ())
	        return true;
	    else if ("digit" in alphabet && @unichar.isdigit ())
	        return true;
	    else if (@unichar.to_string () in alphabet)
	        return true;
	        
	    return false;
	}
	public bool generate_pattern (unichar @unichar){
		var first_state = this.transition_array [0];
		foreach (var item in first_state.transition_state){
			if (item.value != null){
				if (item.key == @"$unichar")
					return true;
				if (@unichar.isalpha () && item.key == "letter")
					return true;
				if (item.key == "digit" && @unichar.isdigit ())
					return true;
				
			}
		}
		return false;
	}
	
	public bool go_to_next_state (unichar @unichar){
	   // Log.m (TAG, @"Estoy en el edo: $(state.state_id)");

	    foreach (var item in state.transition_state){
	        if (item.value != null){
	        
	            if (@unichar.isspace () && item.key == "other") {
	            
	               // Log.m (TAG, "vamos a other");
	                //Log.m (TAG, item.value);
	                state = transition_array [int.parse(item.value)];
	                return true;
	                
	            }
	            
	            if (item.key == @"$unichar"){
					log.m (TAG, @"voy al estado $(item.value)");
	                state = transition_array [int.parse(item.value)];
	                log.m (TAG, @"voy al estado $(item.value)");
	                this.pattern.add (MapType (item.key, item.value));
	                return true;
	                
	            }
	            
	            if (item.key == "letter" && @unichar.isalpha ()){
	                
	                state = transition_array [int.parse(item.value)];
	                log.m (TAG, @"voy al estado $(item.value)");
	                this.pattern.add (MapType (item.key, item.value));
	                return true;    
	                
	            }
	            
	            if (item.key == "digit" && @unichar.isdigit ()){
	                
	                state = transition_array [int.parse(item.value)];
	                log.m (TAG, @"voy al estado $(item.value)");
	                this.pattern.add (MapType (item.key, item.value));
	                return true;;    
	                
	            }
	        }
	    }
	    
	    return false;
	}
	
	public bool is_end_state (){
	    foreach (var item in this.state.transition_state){
            if (item.key == "type" && item.value != null){
            
                token_type = item.value;
                return true;
                
            }
	    }
	    return false;
	}
	

	public bool is_in_current_pattern (unichar @unichar){
		if (@unichar.isalpha () || @unichar.isdigit ())
			return false; 
			
		var first_state = this.transition_array [int.parse (this.pattern [0].value)];
		
		string first_item, second_item;
		first_item  = "nada";
	    second_item = "nada2";
		foreach (var item in first_state.transition_state){
            if (item.key == @"$unichar" || item.key == "other"){
				
        		if (item.value == null)
		            return false;
				else if (item.key == @"$unichar")
					first_item = item.value;
				else if (item.key == "other")
					second_item = item.value;
				
            }
		 }
		
		if (first_item == second_item)
			return false;
		else
			return true;
	}
		
	public string pattern_to_string (){
	    string pattern_string = "";
	    foreach (var item in this.pattern)
	        pattern_string += @"\n$item";
	        
	    return pattern_string;
	}
	public void reset_pattern (bool flag = false){
		this.pattern = new ArrayList<MapType?> ();
	}
	
    public void go_to_init_state (){
        state = transition_array [0];
	}
	/**
	    crea la maquina de estados, apartir de la tabla de transicion 
	*/
	private bool create_state_machine (ref ArrayList<string> preprocess_transition_table){
	
        this.transition_array = new ArrayList<State?> ();
        this.alphabet = new ArrayList<string> ();
        
        //debe de haber almenos un estado y el alfabeto 
        if (preprocess_transition_table.size < 2)
            return false;
        
        string [] temp = preprocess_transition_table[0].split ("\t");
        
        //debe de haber almenos cuatro elementos en el alphabeto
        if (temp.length < 4)
            return false;
            
        //llenamos alphabeto
        for (var i = 1; i < temp.length; i++)
            this.alphabet.add (temp[i]);
        
        var iterator_transition = preprocess_transition_table.iterator ();
        string[] transition_tokens;
        
        //saltamos la primera linea
        iterator_transition.next ();
        //creamos los estados
        var j = 0;
        while (iterator_transition.has_next ()){
        
            j = 0;
            var temp_state = State ();
            iterator_transition.next ();
            transition_tokens = iterator_transition.get ().split ("\t");
            //obtenemos el estado inicial
            temp_state.state_id = int.parse(transition_tokens [0]);
            //llenamos las transiciones
            temp_state.transition_state = new ArrayList <MapType?> ();
            
            for ( int i = 1; i < transition_tokens.length ; i++  ){
            
                //si es - colocamos null
                if (transition_tokens[i] == "-"){
                
                    var map = MapType(alphabet[j], null);
                    temp_state.transition_state.add ( map );
                    
                } else{
                 
                    temp_state.transition_state.add (MapType(alphabet[j], transition_tokens[i]));
                    
                }
                
                j++;
                
            }
            
            this.transition_array.add (temp_state);
            
        } 
        
        return true; 
	}

}//class Lexicon

}//namespace Compiler.Lexicon

