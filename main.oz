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
       
       {Wait ThreadOver}
       
       InsertedLine PredictedWord in
       InsertedLine = {TakeSlashNOff {Text1 getText(p(1 0) 'end' $)}} % example using coordinates to get text
       PredictedWord = {FindMostFrequent1Gram WordsDict {GetLastWord InsertedLine}} % WordsDict est défini tout en bas
       {Text2 set(1:PredictedWord)} % you can get/set text this way too
    end

%%% Retourne la concatenation de "tweets/part_", de Number et de ".txt"
    fun {PartNumber Number}
       {Append {Append "tweets/part_" {Int.toString Number}} ".txt"}
    end

%%% Retourne le dernier mot de la ligne Line
    fun {GetLastWord Line}
       fun {GetIt Line Word}
	  case Line
	  of nil then Word
	  [] Letter|T then
	     if Letter \= 32 then
		{GetIt T {Append Word Letter|nil}}
	     else
		{GetIt T nil}
	     end
	  end
       end
    in
       {GetIt Line nil}
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

%%% Retourne le mot le plus frequent apres le mot Word, selon le dictionnaire Dict
    fun {FindMostFrequent1Gram Dict Word}
       SubDict MaxOccur in
       SubDict = {Dictionary.condGet Dict {String.toAtom Word} {Dictionary.new}} % on lit le subDict du mot
       MaxOccur = {NewCell [nil 0]} % ex. [apple 3] signifie que le mot Word est suivi 3 fois par apple
       
       for Key in {Dictionary.keys SubDict} do
	  if {Dictionary.get SubDict Key} > @MaxOccur.2.1 then
	     MaxOccur := {Append [Key] {Dictionary.get SubDict Key}|nil}
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
	  elseif Letter == 8217 then % apostrophe chelou
	     WordToAdd := {Append @WordToAdd "'"|nil}
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

%%% Ajoute au dictionnaire Dict des sous-dictionnaires de type:
%%% {"je" : {"suis" : 4, "mange" : 3}, "tu" : {"es" : 2}}
%%% ce qui signifie que le mot "je" est suivi 4 fois par le mot "suis", etc.
%%% dans la ligne Line
    proc {Add1GramsToDict Dict Stream}
       PrevWord SubDict GramCount in
       PrevWord = {NewCell nil} % premier mot du gram
       SubDict = {NewCell nil} % sous-dictionnaire de chaque mot
       GramCount = {NewCell nil} % combien de fois le gram existe

       for Word in Stream.1 do % second mot du gram
	  % on prend subdict et s'il n'existe pas, on le cree
	  SubDict := {Dictionary.condGet Dict {String.toAtom @PrevWord} {Dictionary.new}}
	  % on regarde cb de fois le gram existe deja
	  GramCount := {Dictionary.condGet @SubDict {String.toAtom Word} 0}
	  % on (re)met dans le subdico en incrementant de 1
	  {Dictionary.put @SubDict {String.toAtom Word} @GramCount+1}
	  % on met le subdico dans le dico
	  {Dictionary.put Dict {String.toAtom @PrevWord} @SubDict}

	  PrevWord := Word
       end

       if Stream.2 == over then
	  {Show add1gramsover}
	  ThreadOver = unit
       else
	  {Add1GramsToDict Dict Stream.2}
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
    {Wait ReadFilesOver}
    Time2 = {Time.time}
    {Show Time2-Time1}
    % thread {Disp ReadingStream} end
    
    % Ici les threads de parsing (j'ai suppose que c'etait ca ahah)
    GetListOver
    SeparatingStream
    thread SeparatingStream = {GetListOfWords ReadingStream} end
    % thread {Disp SeparatingStream} end
    {Wait GetListOver}
    Time3 = {Time.time}
    {Show Time3-Time2}

    % Et ici les threads d'écriture (guess que c'est ceux qui ecrivent dans le dico?)
    WordsDict = {Dictionary.new}
    ThreadOver
    thread {Add1GramsToDict WordsDict SeparatingStream} end
    {Wait ThreadOver}
    Time4 = {Time.time}
    {Show Time4-Time3}
    {Show over}

    % C'est parti !
    {Text1 set(1:"Chargement terminé ! Effacez ce texte et écrivez le vôtre à la place.")} % you can get/set text this way too   
end

