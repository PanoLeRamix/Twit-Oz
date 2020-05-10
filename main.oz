functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    % System
    Application
    % OS
    Browser

    Reader
define
%%% Easier macros for imported functions
    Browse = Browser.browse
    % Show = System.show

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
       
       {Wait FillThread}
       
       InsertedLine PredictedWord in
       InsertedLine = {TakeSlashNOff {Text1 getText(p(1 0) 'end' $)}} % example using coordinates to get text
       PredictedWord = {FindMostFrequent1Gram WordsDict {GetLastWord InsertedLine}} % WordsDict est défini tout en bas
       {Text2 set(1:PredictedWord)} % you can get/set text this way too
    end

%%% Cree une liste de From a Upto
    fun {CreateList From Upto}
       fun {Create Upto Actual}
	  if Upto == Actual then Actual|nil
	  else Actual|{Create Upto Actual+1}
	  end
       end
    in
       {Create Upto From}
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

%%% Retourne une liste des mots, dans l'ordre, de la ligne Line
    fun {GetListOfWords Line}
       LineSineN ToReturn WordToAdd in
       LineSineN = {TakeSlashNOff Line}
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
       @ToReturn
    end
    
    
%%% Ajoute au dictionnaire Dict les entités (mots) séparées par un espace de la ligne Line
    proc {AddWordsToDict Dict Line}
       GramCount in
       GramCount = {NewCell nil}

       for Word in {GetListOfWords Line} do
	  GramCount := {Dictionary.condGet Dict {String.toAtom Word} 0}
	  {Dictionary.put Dict {String.toAtom Word} @GramCount+1}
       end
    end

%%% Ajoute au dictionnaire Dict des sous-dictionnaires de type:
%%% {"je" : {"suis" : 4, "mange" : 3}, "tu" : {"es" : 2}}
%%% ce qui signifie que le mot "je" est suivi 4 fois par le mot "suis", etc.
%%% dans la ligne Line
    proc {Add1GramsToDict Dict Line}
       PrevWord SubDict GramCount in
       PrevWord = {NewCell nil} % premier mot du gram
       SubDict = {NewCell nil} % sous-dictionnaire de chaque mot
       GramCount = {NewCell nil} % combien de fois le gram existe

       for Word in {GetListOfWords Line} do % second mot du gram
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

%%% Lit tous les tweets et remplit le dictionnaire
%%% Dict est le dictionnaire à remplir
%%% Lit les fichiers du numéro FromFile au numéro ToFile
%%% Lit les lignes de la ligne FromLine à la lgien ToLine
%%% Ngram est la qualité du dictionnaire qu'on désire (0-gram, 1-gram, 2-gram)
    proc {FillDictionary Dict FromFile ToFile FromLine ToLine Ngram}
       if Ngram == 0 then
	  for FileNumber in {CreateList FromFile ToFile} do
	     {Browse FileNumber}
	     for LineNumber in {CreateList FromLine ToLine} do
		{AddWordsToDict WordsDict {GetLineNb {PartNumber FileNumber} LineNumber}}
	     end
	  end
       else
	  for FileNumber in {CreateList FromFile ToFile} do
	     {Browse FileNumber}
	     for LineNumber in {CreateList FromLine ToLine} do
		{Add1GramsToDict WordsDict {GetLineNb {PartNumber FileNumber} LineNumber}}
	     end
	  end
       end
       FillThread = unit
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
    WordsDict = {Dictionary.new}
    FillThread
    thread {FillDictionary WordsDict 200 208 1 100 1} end
    {Wait FillThread}

    % C'est parti !
    {Text1 set(1:"Chargement terminé ! Effacez ce texte et écrivez le vôtre à la place.")} % you can get/set text this way too
    
    % {Show 'You can print in the terminal...'} % pour ça faut activer 2 trucs (envoie-moi un msg si tu veux le faire)
    % {Browse '... or use the browser window'}
    
end

