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

{Browse " "} % [32]
{Browse "."} % [46]
{Browse ":"} % [58]
{Browse ";"} % [59]
{Browse "!"} % [33]
{Browse "?"} % [63]
%% je peux pas save les caractères bizarres:/ je les ai sur notepad++
{Browse ""} % [8220]
{Browse ""} % [8221]
{Browse ""} % [8217]
