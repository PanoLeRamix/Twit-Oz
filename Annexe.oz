declare
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
% {Browse {CreateList 30}}

declare
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
% {Browse {Concatenate "alo" "ola"}}

declare
% Retourne la concatenation de "tweets/part_", de Number et de ".txt"
fun {PartNumber Number}
   {Concatenate {Concatenate "tweets/part_" {Int.toString Number}} ".txt"}
end

% Objectif : compter le nombre de fois que tous les mots apparaissent


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

%% Tests avec les dicos
declare A B C D E
A = {Dictionary.new}
C = "Clef"
B = 5
{Dictionary.put A {String.toAtom C} B}
Temp = {Dictionary.condGet A {String.toAtom C} 0}
{Dictionary.put A {String.toAtom C} Temp+1}
% {Browse {Dictionary.condGet A {String.toAtom C} 0}} % browse 6

% espace = [32]
declare
Line = [108 111 110 103 101 32 101 106 115 32 108 111 110 103 101 32 101]
A = {Dictionary.new}

declare
proc {AddWordsToDic Dic Line}
   local WordToAdd Temp
   in
      WordToAdd = {NewCell nil}
      Temp = {NewCell nil}

      for Letter in Line
      do
	 if Letter \= 32 then
	    WordToAdd := {Append @WordToAdd Letter|nil}
	 else
	    {Browse @WordToAdd}
	    Temp := {Dictionary.condGet A {String.toAtom @WordToAdd} 0}
	    {Dictionary.put A {String.toAtom @WordToAdd} @Temp+1}
	    WordToAdd := nil
	 end
      end
      {Browse @WordToAdd}
      Temp := {Dictionary.condGet A {String.toAtom @WordToAdd} 0}
      {Dictionary.put A {String.toAtom @WordToAdd} @Temp+1}
      WordToAdd := nil
   end
end

{AddWordsToDic A Line}
{Browse {Dictionary.condGet A {String.toAtom "longe"} 0}}