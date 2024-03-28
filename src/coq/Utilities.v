(* Re-export of the main utilities used accross the development.
   Use `From Vellvm Require Import Utils.` to get most utilities in scope.

   Note: We avoid as much as possible to import notations. You can therefore import 
   additionally the following modules:
   - `Import AlistNotations.` for notations related to `alist` used to lookup blocks.
 *)

From Vellvm Require Export
     Utils.Tactics
     Utils.Util
     Utils.AListFacts
     Utils.ListUtil
     Utils.Error
     Utils.PropT
     Utils.Monads
     Utils.InterpProp.

From stdpp Require Import base.

Notation "x =d y" := (decide (x = y)) (at level 70, no associativity, only parsing).
