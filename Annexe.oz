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

% ca fonctionne eheh
for Element in {CreateList 5}
do {Browse {PartNumber Element}}
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
{Browse D} % browse "abcde"
{Browse E} % browse 0

%% Tests avec les dicos
declare A B C D E
A = {Dictionary.new}
C = "Clef"
B = 5
{Dictionary.put A {String.toAtom C} B}
Temp = {Dictionary.condGet A {String.toAtom C} 0}
{Dictionary.put A {String.toAtom C} Temp+1}
{Browse {Dictionary.condGet A {String.toAtom C} 0}}