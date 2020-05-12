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

   proc {Press}
      {Wait Add2GramsOver}

      InsertedLine PredictedWord in
      InsertedLine = {Text1 getText(p(1 0) 'end' $)}
      PredictedWord = {FindMostFrequent2Gram WordsDict {GetLastTwoWords InsertedLine}}

      if PredictedWord == "nil" then
	 {Text2 set(1:"We couldn't find any prediction. Please try again with other words.")}
      elseif PredictedWord == nil then
	 {Text2 set(1:"Please write some text.")}
      else
	 {Text2 set(1:PredictedWord)}
      end
   end
   
%%% Renvoie la ligne numero LineNumber du fichier IN_NAME
   fun {GetLineNb IN_NAME LineNumber}
      Line in
      Line = {Reader.scan {New Reader.textfile init(name:IN_NAME)} LineNumber}
      if Line == none then
	 nil
      else
	 Line
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
	  [] W|nil then [nil W]
	  [] W|nil|_ then [nil W]
	  [] W1|W2|nil then [W1 W2]
	  else
	     {GetThem List.2}
	  end
       end
    in
       {GetThem {GetListOfWords Line|over|nil 1}.1}
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

%%% Retourne le mot le plus frequent apres la suite de deux mots Words, selon le dictionnaire Dict
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
%%% Et envoie les lignes, une à une, au port Port
%%% Envoie over quand il a terminé
    proc {ReadFiles Port FromFile ToFile FromLine ToLine}
       proc {ReadIt CurrentFile CurrentLine}
	  {Send Port {GetLineNb {PartNumber CurrentFile} CurrentLine}}
	  if CurrentLine == ToLine then
	     if CurrentFile == ToFile then
		% {Show readfilesover}
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

%%% Retourne un stream de liste des mots, dans l'ordre, de la ligne Line, terminé par over
    fun {GetListOfWords Stream OverExpected}
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
	     over
	  else
	     {GetListOfWords Stream.2 OverExpected-1}
	  end
       else
	  {GetWords {Format Stream.1} nil}|{GetListOfWords Stream.2 OverExpected}
       end
    end	     

%%% Ajoute au dictionnaire Dict des sous-dictionnaires de façon que Dict ressemble à :
%%% {"je" : {"suis" : {grand : 4, petit : 3}, "mange" : {des : 1, une : 3}}, "tu" : {"es" : {grand : 2}}}
%%% ce qui signifie que la suite de mots "je suis" est suivi 4 fois par le mot "grand", etc.
%%% depuis le stream Stream, terminé par over
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
	  Add2GramsOver = unit
       else
	  {Add2GramsToDict Dict Stream.2}
       end
    end

%%% Lance les N threads de lecture
    proc {LaunchReadingThreads N}
       proc {Launch NthThread}
	  if NthThread < N then
	     thread {ReadFiles ReadingPort 1+(NthThread-1)*Step Step*NthThread 1 100} end
	     {Launch NthThread+1}
	  else
	     thread {ReadFiles ReadingPort 1+(NthThread-1)*Step 208 1 100} end
	  end
       end
       Step
    in
       Step = 208 div N
       {Show Step}
       {Launch 1}
    end
           
%%% ICI SE TROUVE LE CODE QUI TOURNE
    % Création de l'interface graphique
    Text1 Text2
    Description=td(
	title: "Text predictor"
	lr(text(handle:Text1 width:35 height:10 background:white foreground:black wrap:word) button(text:"Predict" action:Press))
	text(handle:Text2 width:35 height:10 background:black foreground:white glue:w wrap:word)
	action:proc{$}{Application.exit 0} end % quit app gracefully on window closing
		   )

    % Creation de la description ci-dessus
    W={QTk.build Description}
    {W show}

    %
    {Text1 tk(insert 'end' "Loading... Please wait.")}
    {Text1 bind(event:"<Control-s>" action:Press)} % You can also bind events

    Time1 = {Time.time}
    % Creation du port qui redirige vers le stream des lignes lues
    ReadingStream
    ReadingPort = {NewPort ReadingStream}

    NbReadingThreads = 12
    {LaunchReadingThreads NbReadingThreads}

    % On sépare les mots des listes
    SeparatingStream
    thread SeparatingStream = {GetListOfWords ReadingStream NbReadingThreads} end

    % On inscrit les mots et la frequence des mots qui les suivent dans un dictionnaire
    WordsDict = {Dictionary.new}
    Add2GramsOver
    thread {Add2GramsToDict WordsDict SeparatingStream} end
    {Wait Add2GramsOver}
    
    Time4 = {Time.time}    
    {Show Time4-Time1}
    
    % C'est parti !
    {Text1 set(1:"Loading ended! Delete this text and write your own instead.")}
end

