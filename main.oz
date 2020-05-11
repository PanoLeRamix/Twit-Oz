functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    % OS
    Browser

    Reader
define
%%% Easier macros for imported functions
    Browse = Browser.browse
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
       %% code du prof pas virer c'est pour se souvenir de comment faire
       % Inserted in
       % Inserted = {Text1 getText(p(1 0) 'end' $)} % example using coordinates to get text
       % {Text2 set(1:Inserted)} % you can get/set text this way too
       
       {Wait Add2GramsOver}
       
       InsertedLine PredictedWord in
       InsertedLine = {TakeSlashNOff {Text1 getText(p(1 0) 'end' $)}} % example using coordinates to get text
       PredictedWord = {FindMostFrequent2Gram WordsDict {GetLastTwoWords InsertedLine}} % WordsDict est défini tout en bas
       {Text2 set(1:PredictedWord)} % you can get/set text this way too
    end

%%% Retourne la concatenation de "tweets/part_", de Number et de ".txt"
    fun {PartNumber Number}
       {Append {Append "tweets/part_" {Int.toString Number}} ".txt"}
    end

%%% Retourne les deux derniers mots, sous forme de liste, de la ligne Line
    fun {GetLastTwoWords Line}
       fun {GetThem Line AnteUltWord UltWord}
	  case Line
	  of nil then [AnteUltWord UltWord]
	  [] Letter|T then
	     if Letter \= 32 then
		{GetThem T AnteUltWord {Append UltWord Letter|nil}}
	     else
		{GetThem T UltWord nil}
	     end
	  end
       end
    in
       {GetThem Line nil nil}
    end
       
%%% Retourne le même string mais sans aucun "\n"
    fun {TakeSlashNOff String}
       case String
       of nil then
	  String
       [] 10|T then
	  {TakeSlashNOff T}
       else
	  String.1|{TakeSlashNOff String.2}
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

%%%%%% PARTIE OU LES FONCTIONS FONCTIONNENT AVEC DES STREAMS (THREADS) %%%%%
%%% Browse un stream
    proc {Disp S}
       case S
       of X|over then {Browse X}
       [] X|S2 then
	  {Browse X}
	  {Disp S2}
       end
    end
    
%%% Lit les fichiers du numéro FromFile au numéro ToFile
%%% Lit les lignes de la ligne FromLine à la ligne ToLine
%%% Et retourne les lignes, une à une, sous forme de stream, terminé par over
    fun {ReadFiles FromFile ToFile FromLine ToLine}
       fun {ReadIt CurrentFile CurrentLine}
	  if CurrentLine == ToLine then
	     if CurrentFile == ToFile then
		ReadFilesOver = unit
		{Show readfilesover}
		{GetLineNb {PartNumber CurrentFile} CurrentLine}|over
	     else
		{Show CurrentFile}
		{GetLineNb {PartNumber CurrentFile} CurrentLine}|{ReadIt CurrentFile+1 FromLine}
	     end
	  else
	     {GetLineNb {PartNumber CurrentFile} CurrentLine}|{ReadIt CurrentFile CurrentLine+1}
	  end
       end
    in
       {ReadIt FromFile FromLine}
    end

%%% Retourne un stream de liste des mots, dans l'ordre, de la ligne Line, termine par over
    fun {GetListOfWords Stream}
       LineSineN ToReturn WordToAdd in
       LineSineN = {TakeSlashNOff Stream.1}
       ToReturn = {NewCell nil}
       WordToAdd = {NewCell nil}
       for Letter in LineSineN do
	  if Letter == 32 then % " "
	     ToReturn := {Append @ToReturn @WordToAdd|nil}
	     WordToAdd := nil
	  elseif Letter == 46 orelse Letter == 59 orelse Letter == 33 orelse Letter == 63 then % ".", ";", "!", "?"
	     skip
	  elseif Letter == 146 orelse Letter == 222 then % fonctionne pas
	     skip
	  elseif 64 < Letter andthen Letter < 90 then % lettre majuscule
	     WordToAdd := {Append @WordToAdd Letter+32|nil}
	  else
	     WordToAdd := {Append @WordToAdd Letter|nil}
	  end
       end
       if Stream.2 == over then
	  GetListOver = unit
	  {Show getlistover}
	  {Append @ToReturn @WordToAdd|nil}|over
       else
	  {Append @ToReturn @WordToAdd|nil}|{GetListOfWords Stream.2}
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
    {Text1 tk(insert 'end' "Chargement... Veuillez patienter.")}
    {Text1 bind(event:"<Control-s>" action:Press)} % You can also bind events
    
    % On cree le dictionnaire qui contient des données intéressantes
    % Ici il va falloir lancer les threads de lecture
    ReadFilesOver
    ReadingStream
    %ReadingStream2
    %ReadingStream3
    Time1 = {Time.time}
    thread ReadingStream = {ReadFiles 1 208 1 100} end
    %thread ReadingStream2 = {ReadFiles 71 140 1 100} end
    %thread ReadingStream3 = {ReadFiles 141 208 1 100} end
    %{Wait ReadFilesOver}
    %Time2 = {Time.time}
    %{Show Time2-Time1}
    
    % Ici les threads de parsing (j'ai suppose que c'etait ca ahah)
    GetListOver
    SeparatingStream
    thread SeparatingStream = {GetListOfWords ReadingStream} end
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
    {Text1 set(1:"Chargement terminé ! Effacez ce texte et écrivez le vôtre à la place.")} % you can get/set text this way too   
end

