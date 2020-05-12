functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    % OS
    % Browser

    Reader
define
%%% Easier macros for imported functions
    % Browse = Browser.browse
    Show = System.show

%%% Read File
   fun {GetLineNb IN_NAME LineNumber}
      Line in
      Line = {Reader.scan {New Reader.textfile init(name:IN_NAME)} LineNumber}
      if Line == none then
	 nil
      else
	 Line
      end
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
       {Wait Add2GramsOver}
       
       InsertedLine PredictedWord in
       InsertedLine = {Format {Text1 getText(p(1 0) 'end' $)}}
       PredictedWord = {FindMostFrequent2Gram WordsDict {GetLastTwoWords InsertedLine}}
       
       if PredictedWord == "nil" then
	  {Text2 set(1:"We couldn't find any prediction. Please try again with other words.")}
       elseif PredictedWord == nil then
	  {Text2 set(1:"Please write some text.")}
       else
	  {Text2 set(1:PredictedWord)} 
       end
    end

%%% Retourne la concatenation de "tweets/part_", de Number et de ".txt"
    fun {PartNumber Number}
       {Append {Append "tweets/part_" {Int.toString Number}} ".txt"}
    end

%%% Retourne les deux derniers mots, sous forme de liste, de la ligne Line
    fun {GetLastTwoWords Line}
       fun {GetThem List}
	  case List
	  of nil then nil
	  [] W|nil then [W nil]
	  [] W1|W2|nil then [W1 W2]
	  else
	     {GetThem List.2}
	  end
       end
    in
       {GetThem {RecurGetListOfWords Line|over|nil 1}.1 }
    end
       
%%% Retourne le même string mais sans aucun "\n", sans espace final et sans double espace
    fun {Format String}
       case String
       of nil then
	  nil
       [] 10|T then
	  {Format T}
       [] 32|32|T then
	  {Format 32|T}
       [] 32|nil then
	  nil
       else
	  String.1|{Format String.2}
       end
    end

%%% Retourne le mot le plus frequent apres la suite de mots Words, selon le dictionnaire Dict
    fun {FindMostFrequent2Gram Dict Words}
       Word1 Word2 SubDict SubSubDict MaxOccur in
       Word1 = Words.1
       Word2 = Words.2.1
       SubDict = {Dictionary.condGet Dict {String.toAtom Word1} {Dictionary.new}} % on lit le subDict du mot 1
       SubSubDict = {Dictionary.condGet SubDict {String.toAtom Word2} {Dictionary.new}} % on lit le subsubDict du mot 1, suivi du mot 2
       MaxOccur = {NewCell [nil 0]} % ex. [apple 3] signifie que les mots Word 1 et Word 2 sont suivis 3 fois par apple

       for Key in {Dictionary.keys SubSubDict} do
	  if {Dictionary.get SubSubDict Key} > @MaxOccur.2.1 then
	     MaxOccur := {Append [Key] {Dictionary.get SubSubDict Key}|nil}
	  end
       end

       % return
       {Atom.toString @MaxOccur.1}
    end

%%% Lit les fichiers du numéro FromFile au numéro ToFile
%%% Lit les lignes de la ligne FromLine à la ligne ToLine
%%% Et ajoute les lignes, une à une, au port Port
%%% Envoie over quand il a terminé
    proc {ReadFiles Port FromFile ToFile FromLine ToLine}
       proc {ReadIt CurrentFile CurrentLine}
	  {Send Port {GetLineNb {PartNumber CurrentFile} CurrentLine}}
	  if CurrentLine == ToLine then
	     if CurrentFile == ToFile then
		ReadFilesOver = unit
		{Show readfilesover}
		{Send Port over}
	     else
		{Show CurrentFile}
		{ReadIt CurrentFile+1 FromLine}
	     end
	  else
	     {ReadIt CurrentFile CurrentLine+1}
	  end
       end
    in
       {ReadIt FromFile FromLine}
    end

%%% Retourne un stream de liste des mots, dans l'ordre, de la ligne Line, termine par over
    fun {RecurGetListOfWords Stream OverExpected}
       fun {GetWords Line CurrentWord}
	  if Line == nil then CurrentWord|nil % fin de ligne
	  elseif Line.1 == 32 then CurrentWord|{GetWords Line.2 nil} % espace
	  elseif 65 =< Line.1 andthen Line.1 =< 89 then % lettre majuscule
	     {GetWords Line.2 {Append CurrentWord Line.1+32|nil}}
	  elseif 90 =< Line.1 andthen Line.1 =< 124 then % lettre minuscule
	     {GetWords Line.2 {Append CurrentWord Line.1|nil}}
	  else
	     {GetWords Line.2 CurrentWord}
	  end
       end
    in
       if Stream.1 == over then
	  if OverExpected == 1 then
	     GetListOver = unit
	     over
	  else
	     {RecurGetListOfWords Stream.2 OverExpected-1}
	  end
       else
	  {GetWords {Format Stream.1} nil}|{RecurGetListOfWords Stream.2 OverExpected}
       end
    end	     

%%% Ajoute au dictionnaire Dict des sous-dictionnaires de façon que Dict ressemble à :
%%% {"je" : {"suis" : {grand : 4, petit : 3}, "mange" : {des : 1, une : 3}}, "tu" : {"es" : {grand : 2}}}
%%% ce qui signifie que la suite de mots "je suis" est suivi 4 fois par le mot "grand", etc.
%%% depuis le stream Stream
    proc {Add2GramsToDict Dict Stream}
       AnteUltWord UltWord SubDict SubSubDict GramCount in
       AnteUltWord = {NewCell nil} % premier mot du gram
       UltWord = {NewCell nil} % deuxieme mot du gram
       SubDict = {NewCell nil} % sous-dictionnaire de chaque mot
       SubSubDict = {NewCell nil}
       GramCount = {NewCell nil} % combien de fois le gram existe

       for Word in Stream.1 do % troisieme mot du gram
	  SubDict := {Dictionary.condGet Dict {String.toAtom @AnteUltWord} {Dictionary.new}}
	  SubSubDict := {Dictionary.condGet @SubDict {String.toAtom @UltWord} {Dictionary.new}}
	  GramCount := {Dictionary.condGet @SubSubDict {String.toAtom Word} 0}
	  {Dictionary.put @SubSubDict {String.toAtom Word} @GramCount+1}
	  {Dictionary.put @SubDict {String.toAtom @UltWord} @SubSubDict}
	  {Dictionary.put Dict {String.toAtom @AnteUltWord} @SubDict}

	  AnteUltWord := @UltWord
	  UltWord := Word
       end

       if Stream.2 == over then
	  {Show add2gramsover}
	  Add2GramsOver = unit
       else
	  {Add2GramsToDict Dict Stream.2}
       end
    end 
       
%%% Et voici le code qui tourne
    % Build the layout from the description
    % jsp ce que c'est ahah
    W={QTk.build Description}
    {W show}

    % On cree la fenetre du haut (en blanc)
    {Text1 tk(insert 'end' "Loading... Please wait.")}
    {Text1 bind(event:"<Control-s>" action:Press)} % You can also bind events
    
    % On cree le dictionnaire qui contient des données intéressantes
    ReadingStream
    ReadingPort = {NewPort ReadingStream}
    
    % Ici il va falloir lancer les threads de lecture
    ReadFilesOver
    %ReadingStream2
    %ReadingStream3
    Time1 = {Time.time}

    NbReadingThreads = 8
    thread {ReadFiles ReadingPort 1 26 1 100} end
    thread {ReadFiles ReadingPort 27 52 1 100} end
    thread {ReadFiles ReadingPort 53 78 1 100} end
    thread {ReadFiles ReadingPort 79 104 1 100} end
    thread {ReadFiles ReadingPort 105 130 1 100} end
    thread {ReadFiles ReadingPort 131 156 1 100} end
    thread {ReadFiles ReadingPort 157 182 1 100} end
    thread {ReadFiles ReadingPort 183 208 1 100} end
    %{Wait ReadFilesOver}
    %Time2 = {Time.time}
    %{Show Time2-Time1}
    
    % Ici les threads de parsing (j'ai suppose que c'etait ca ahah)
    GetListOver
    SeparatingStream
    thread SeparatingStream = {RecurGetListOfWords ReadingStream NbReadingThreads} end
    % thread {Disp SeparatingStream} end
    %{Wait GetListOver}
    %Time3 = {Time.time}
    %{Show Time3-Time2}

    % Et ici les threads d'écriture (guess que c'est ceux qui ecrivent dans le dico?)
    WordsDict = {Dictionary.new}
    Add2GramsOver
    thread {Add2GramsToDict WordsDict SeparatingStream} end
    {Wait Add2GramsOver}
    Time4 = {Time.time}
    %{Show Time4-Time3}
    
    {Show over}
    {Show Time4-Time1}
    
    % C'est parti !
    {Text1 set(1:"Loading ended! Delete this text and write your own instead.")} % you can get/set text this way too   
end

