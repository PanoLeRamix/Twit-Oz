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
       {Reader.scan {New Reader.textfile init(name:IN_NAME)} Number}
    end

%%% GUI
    % Make the window description, all the parameters are explained here:
    % http://mozart2.org/mozart-v1/doc-1.4.0/mozart-stdlib/wp/qtk/html/node7.html)
    Text1 Text2 Description=td(
        title: "Text predictor"
        lr(
            text(handle:Text1 width:35 height:10 background:white foreground:black wrap:word)
            button(text:"Predict" action:Press)
        )
        text(handle:Text2 width:35 height:10 background:black foreground:white glue:w wrap:word)
        action:proc{$}{Application.exit 0} end % quit app gracefully on window closing
    )
    proc {Press} Inserted in
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

    %% Cree une liste de 1 a Upto
    fun {CreateList Upto}
       fun {Create Upto Actual}
	  if Upto == Actual then Actual|nil
	  else Actual|{Create Upto Actual+1}
	  end
       end
    in
       {Create Upto 1}
    end

    %% Retourne la concatenation de deux strings
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

    %% Retourne la concatenation de "tweets/part_", de Number et de ".txt"
    fun {PartNumber Number}
       {Concatenate {Concatenate "tweets/part_" {Int.toString Number}} ".txt"}
    end

    %% Ajoute au dictionnaire Dict les mots séparés d'un espace de la ligne Ligne
    proc {AddWordsToDic Dict Line}
       local WordToAdd Temp
       in
	  WordToAdd = {NewCell nil}
	  Temp = {NewCell nil}

	  for Letter in Line
	  do
	     if Letter \= 32 then
		WordToAdd := {Append @WordToAdd Letter|nil}
	     else
		% {Browse @WordToAdd}
		Temp := {Dictionary.condGet Dict {String.toAtom @WordToAdd} 0}
		{Dictionary.put Dict {String.toAtom @WordToAdd} @Temp+1}
		WordToAdd := nil
	     end
	  end
	  % {Browse @WordToAdd}
	  Temp := {Dictionary.condGet Dict {String.toAtom @WordToAdd} 0}
	  {Dictionary.put Dict {String.toAtom @WordToAdd} @Temp+1}
	  WordToAdd := nil
       end
    end

    %% Essayons des trucs
    {Browse 5}
    {Delay 6500} % pour avoir le temps d'activer la vision des strings sur le browser
    WordsDict = {Dictionary.new}
    for FileNumber in {CreateList 207}
    do
       {AddWordsToDic WordsDict {GetFirstLine {PartNumber FileNumber}}}
    end
    {Browse {Dictionary.condGet WordsDict {String.toAtom "the"} 0}}
    {Browse {Reader.scan {New Reader.textfile init(name:{PartNumber 203})} 101}}
    
end

