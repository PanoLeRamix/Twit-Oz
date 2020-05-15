functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   Open

define
%%% Pour ouvrir les fichiers (voir fonction ReadFiles)
   class TextFile % This class enables line-by-line reading
        from Open.file Open.text
   end
   
%%% Easier macros for imported functions
   Show = System.show

%%% Procedure qui se declenche lorsqu'on appuie sur le bouton de prediction
%%% Affiche la prediction du prochain mot selon les deux derniers mots entres
   proc {Press}
      {Wait Add2GramsOver}

      InsertedLine PredictedWord in
      InsertedLine = {Format {Text1 getText(p(1 0) 'end' $)}}
      PredictedWord = {FindMostFrequent2Gram WordsDict {GetLastTwoWords InsertedLine}}

      if PredictedWord == "nil" orelse PredictedWord == nil then
	 {Text2 set(1:"We couldn't find any prediction. Please try again with other words.")}
      else
	 {Text2 set(1:PredictedWord)}
      end
   end

%%%%% FONCTIONS ANNEXES %%%%%

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
       GetStream
       GetPort = {NewPort GetStream}
    in
       {GetListOfWords GetPort Line|over|nil}
       {GetThem GetStream.1}
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

%%%%% FONCTIONS APPELEES PAR LE PROGRAMME %%%%%
    
%%% Envoie vers le port Port toutes les lignes des fichiers
%%% du fichier numéro FromFile au fichier numéro ToFile
    proc {ReadFiles Port FromFile ToFile}
       proc {ScanWhole File}
	  Line = {File getS($)}
       in
	  if Line == false then
	     {File close}
	  else
	     {Send Port Line}
	     {ScanWhole File}
	  end
       end
    in
       {ScanWhole {New TextFile init(name:{PartNumber FromFile})}}
       % {Show FromFile}
       if FromFile < ToFile then
	  {ReadFiles Port FromFile+1 ToFile}
       else
	  {Send Port over}
       end
    end
    
%%% Envoie vers le port Port des listes des mots, dans l'ordre, des lignes du stream Stream, et finalement envoie over
    proc {GetListOfWords Port Stream}
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
	  {Send Port over}
       else
	  {Send Port {GetWords {Format Stream.1} nil}}
	  {GetListOfWords Port Stream.2}
       end
    end	     

%%% Ajoute au dictionnaire Dict des sous-dictionnaires de façon que Dict ressemble à :
%%% {"je" : {"suis" : {grand : 4, petit : 3}, "mange" : {des : 1, une : 3}}, "tu" : {"es" : {grand : 2}}}
%%% ce qui signifie que la suite de mots "je suis" est suivi 4 fois par le mot "grand", etc.
%%% depuis le stream Stream, terminé par over
    proc {AddToDict Dict Stream OverExpected}
       proc {Add Line AnteUltWord UltWord}
	  Word = Line.1
	  SubDict = {Dictionary.condGet Dict {String.toAtom AnteUltWord} {Dictionary.new}}
	  SubSubDict = {Dictionary.condGet SubDict {String.toAtom UltWord} {Dictionary.new}}
	  GramCount = {Dictionary.condGet SubSubDict {String.toAtom Word} 0}
       in
	  {Dictionary.put SubSubDict {String.toAtom Word} GramCount+1}
	  {Dictionary.put SubDict {String.toAtom UltWord} SubSubDict}
	  {Dictionary.put Dict {String.toAtom AnteUltWord} SubDict}

	  case Line
	  of _|nil then
	     skip
	  [] W1|W2|T then
	     {Add W2|T UltWord W1}
	  end
       end
    in
       case Stream
       of over|_ then
	  if OverExpected == 1 then
	     Add2GramsOver = unit
	  else
	     {AddToDict Dict Stream.2 OverExpected-1}
	  end
       else
	  thread {Add Stream.1 nil nil} end
	  {AddToDict Dict Stream.2 OverExpected}
       end
    end

%%% Lance les N threads de lecture et de parsing,
%%%	qui liront et traiteront tous les fichiers jusqu'au fichier numero Upto
%%% Les threads de parsing envoie leur resultat au port SeparatingPort
    proc {LaunchThreads SeparatingPort N Upto}
       proc {Launch NthThread}
	  ReadingStream
	  ReadingPort = {NewPort ReadingStream}
       in
	  if NthThread < N then
	     thread {ReadFiles ReadingPort 1+(NthThread-1)*Step Step*NthThread} end
	     thread {GetListOfWords SeparatingPort ReadingStream} end
	     {Launch NthThread+1}
	  else
	     thread {ReadFiles ReadingPort 1+(NthThread-1)*Step Upto} end
	     thread {GetListOfWords SeparatingPort ReadingStream} end
	  end
       end
       Step
    in
       Step = Upto div N
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

    % On lance les threads de lecture et de parsing
    SeparatedWordsStream
    SeparatedWordsPort = {NewPort SeparatedWordsStream}

    NbThreads = 4
    {LaunchThreads SeparatedWordsPort NbThreads 208}
    
    % On inscrit les mots et la frequence des mots qui les suivent dans un dictionnaire
    WordsDict = {Dictionary.new}
    Add2GramsOver
    thread {AddToDict WordsDict SeparatedWordsStream NbThreads} end
    {Wait Add2GramsOver}

    Time2 = {Time.time}
    {Show lasted}
    {Show Time2-Time1}
    {Show seconds}
    
    % C'est parti !
    {Text1 set(1:"Loading ended! Delete this text and write your own instead.")}
end

