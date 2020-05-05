functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    OS
    Browser

    Reader
define
%%% Easier macros for imported functions
    Browse = Browser.browse
    Show = System.show

%%% Read File
    fun {GetFirstLine IN_NAME}
        {Reader.scan {New Reader.textfile init(name:IN_NAME)} 1}
    end 

%%% GUI
    % Make the window description, all the parameters are explained here:
    % http://mozart2.org/mozart-v1/doc-1.4.0/mozart-stdlib/wp/qtk/html/node7.html)
    Text1 Text2 Description=td(
        title: "Text predictor"
        lr(
            text(handle:Text1 width:35 height:10 background:white foreground:black wrap:word)
            button(text:"Predict" action:Press)
        )
        text(handle:Text2 width:35 height:10 background:black foreground:white glue:w wrap:word)
        action:proc{$}{Application.exit 0} end % quit app gracefully on window closing
    )
    proc {Press} Inserted in
        Inserted = {Text1 getText(p(1 0) 'end' $)} % example using coordinates to get text
        {Text2 set(1:Inserted)} % you can get/set text this way too
    end
    % Build the layout from the description
    W={QTk.build Description}
    {W show}

    {Text1 tk(insert 'end' {GetFirstLine "tweets/part_1.txt"})}
    {Text1 bind(event:"<Control-s>" action:Press)} % You can also bind events

    {Show 'You can print in the terminal...'}
    % {Browse '... or use the browser window'}
end

%%% Beginning le projet
declare
% Crée une liste de 1 à Upto
fun {List1To Upto}
   fun {CreateTheList Upto Actual}
      if Upto == Actual then Actual|nil
      else Actual|{CreateTheList Upto Actual+1}
      end
   end
in
   {CreateTheList Upto 1}
end
{Browse {List1To 30}}

declare
% Retourne la concaténation de deux strings
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

declare
% Retourn la concaténation de "tweets/part_", de Number et de ".txt"
fun {PartNumber Number}
   {Concatenate {Concatenate "tweets/part_" {Int.toString Number}} ".txt"}
end

% ça fonctionne eheh
for Element in {List1To 5}
do {Browse {PartNumber Element}}
end

% Objectif : compter le nombre de fois que tous les mots apparaissent
% mais jsp comment faire ahah
for Part_Nb in {List1To 5}
   do {GetFirstLine "tweets/part_1.txt"}


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