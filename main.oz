functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    OS
    Browser

    Reader
define
%%% Easier macros for imported functions
    Browse = Browser.browse
    Show = System.show

%%% Read File
    fun {GetFirstLine IN_NAME}
        {Reader.scan {New Reader.textfile init(name:IN_NAME)} 1}
    end

    fun {GetLineNb IN_NAME LineNumber}
       {Reader.scan {New Reader.textfile init(name:IN_NAME)} LineNumber}
    end

%%% GUI
    %% Make the window description, all the parameters are explained here:
    %% http://mozart2.org/mozart-v1/doc-1.4.0/mozart-stdlib/wp/qtk/html/node7.html)
    Text1 Text2 Description=td(
        title: "Text predictor"
        lr(
            text(handle:Text1 width:35 height:10 background:white foreground:black wrap:word)
            button(text:"Predict" action:Press)
        )
        text(handle:Text2 width:35 height:10 background:black foreground:white glue:w wrap:word)
        action:proc{$}{Application.exit 0} end % quit app gracefully on window closing
    )
    proc {Press}
       Inserted in
       Inserted = {Text1 getText(p(1 0) 'end' $)} % example using coordinates to get text
       {Text2 set(1:Inserted)} % you can get/set text this way too
    end

    % Build the layout from the description
    W={QTk.build Description}
    {W show}

    {Text1 tk(insert 'end' {GetFirstLine "tweets/part_1.txt"})}
    {Text1 bind(event:"<Control-s>" action:Press)} % You can also bind events

    {Show 'You can print in the terminal...'}
    % {Browse '... or use the browser window'}

%%% Cree une liste de 1 a Upto
    fun {CreateList Upto}
       fun {Create Upto Actual}
	  if Upto == Actual then Actual|nil
	  else Actual|{Create Upto Actual+1}
	  end
       end
    in
       {Create Upto 1}
    end

%%% Retourne la concatenation de deux strings
    fun {Concatenate String1 String2}
       fun {Enumerate String}
	  case String
	  of H|nil then H|String2
	  [] H|T then H|{Enumerate T}
	  end
       end
    in
       {Enumerate String1}
    end

%%% Retourne la concatenation de "tweets/part_", de Number et de ".txt"
    fun {PartNumber Number}
       {Concatenate {Concatenate "tweets/part_" {Int.toString Number}} ".txt"}
    end

%%% Ajoute au dictionnaire Dict les entités (mots) séparées par un espace de la ligne Line
    proc {AddWordsToDict Dict Line}
       WordToAdd GramCount in
       WordToAdd = {NewCell nil}
       GramCount = {NewCell nil}

       for Letter in Line
       do
	  if Letter \= 32 then
	     WordToAdd := {Append @WordToAdd Letter|nil}
	  else
	     GramCount := {Dictionary.condGet Dict {String.toAtom @WordToAdd} 0}
	     {Dictionary.put Dict {String.toAtom @WordToAdd} @GramCount+1}
	     WordToAdd := nil
	  end
       end
       GramCount := {Dictionary.condGet Dict {String.toAtom @WordToAdd} 0}
       {Dictionary.put Dict {String.toAtom @WordToAdd} @GramCount+1}
    end

%%% Ajoute au dictionnaire Dict des sous-dictionnaires de type:
%%% {"je" : {"suis" : 4, "mange" : 3}, "tu" : {"es" : 2}}
%%% ce qui signifie que le mot "je" est suivi 4 fois par le mot "suis", etc.
%%% dans la ligne Line
    proc {Add1GramsToDict Dict Line}
       FirstWord SecondWord SubDict GramCount in
       FirstWord = {NewCell nil} % premier mot du gram
       SecondWord = {NewCell nil} % second mot du gram
       SubDict = {NewCell nil} % sous-dictionnaire de chaque mot
       GramCount = {NewCell nil} % combien de fois le gram existe

       for Letter in Line do
	  if Letter \= 32 then
	     SecondWord := {Append @SecondWord Letter|nil}
	  else
	     % on prend subdict et s'il n'existe pas, on le cree
	    SubDict := {Dictionary.condGet Dict {String.toAtom @FirstWord} {Dictionary.new}}
	     % on regarde cb de fois le gram existe deja
	     GramCount := {Dictionary.condGet @SubDict {String.toAtom @SecondWord} 0}
	     % on (re)met dans le subdico en incrementant de 1
	     {Dictionary.put @SubDict {String.toAtom @SecondWord} @GramCount+1}
             % on met le subdico dans le dico
	     {Dictionary.put Dict {String.toAtom @FirstWord} @SubDict}
	 
	     FirstWord := @SecondWord
	     SecondWord := nil
	  end
       end
       
       % il faut le faire encore une fois pcq la ligne finit pas par un espace
       % oui c'est pas propre ahah
       SubDict := {Dictionary.condGet Dict {String.toAtom @FirstWord} {Dictionary.new}}
       GramCount := {Dictionary.condGet @SubDict {String.toAtom @SecondWord} 0}
       {Dictionary.put @SubDict {String.toAtom @SecondWord} @GramCount+1}
       {Dictionary.put Dict {String.toAtom @FirstWord} @SubDict}
    end

%%% Essayons des trucs
    % On crée le dictionnaire qui contient des données intéressantes
    WordsDict = {Dictionary.new}
    for FileNumber in {CreateList 20}
    do
       {Browse FileNumber}
       for LineNumber in {CreateList 100}
       do
	  % {AddWordsToDict WordsDict {GetLineNb {PartNumber FileNumber} LineNumber}} % activer ceci pour conter le nombre d'occurrences d'un mot
	  {Add1GramsToDict WordsDict {GetLineNb {PartNumber FileNumber} LineNumber}} % activer ceci pour conter les 1-grams
       end
    end

    % {Browse {Dictionary.condGet WordsDict {String.toAtom "I"} 0}} % activer ceci dans le cas 1
    ISubDict = {Dictionary.condGet WordsDict {String.toAtom "I"} 0} % activer ceci dans le cas 2
    {Browse {Dictionary.condGet ISubDict {String.toAtom "am"} 0}} % activer ceci AUSSI dans le cas 2
    
end

