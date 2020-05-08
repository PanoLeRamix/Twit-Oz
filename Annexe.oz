%% How to use les dictionnaires
declare A B C D E
A = {Dictionary.new}
C = "Clef"
B = "abcde"
{Dictionary.put A {String.toAtom C} B}
D = {Dictionary.condGet A {String.toAtom C} 0}
E = {Dictionary.condGet A {String.toAtom "hola"} 0}
% {Browse D} % browse "abcde"
% {Browse E} % browse 0

% espace = [32]

declare
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

declare
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

declare
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

declare
Line = "yo soy Anton, y yo quiero comer unos pasteles porque los pasteles son algo que a mi me gusta mucho, pero yo no soy de esos que comen demasiados pasteles, o tal vez si lo sea, no se, preguntenlo a los que si comen muchos pasteles o los que demasiado lo hacen. los"
A = {Dictionary.new}
{Add1GramsToDict A Line}
{Browse {Dictionary.keys A}}
declare
SubDict = {Dictionary.condGet A {String.toAtom "los"} 0}
{Browse {Dictionary.condGet SubDict {String.toAtom "que"} 0}}
{Browse {GetLastWord Line}}
{Browse {FindMostFrequent1Gram A {GetLastWord Line}}}
