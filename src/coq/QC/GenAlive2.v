From Vellvm Require Import
  DList
  Utilities
  AstLib
  Syntax
  Semantics.Memory.Sizeof
  LLVMEvents
  LLVMAst
  QC.Utils
  QC.Generators.

Require Import Integers.

From ExtLib.Structures Require Export
  Functor Applicative Monad Monoid.

Require Import ExtLib.Data.Monads.StateMonad.
Require Import ExtLib.Structures.Monads.
Require Export ExtLib.Structures.Functor.

Require Import List.

Import ListNotations.
Import MonadNotation.
Import ApplicativeNotation.

From Coq Require Import
  ZArith Lia Bool.Bool.


From QuickChick Require Import QuickChick.
Import QcDefaultNotation.
Open Scope qc_scope.
Open Scope Z_scope.

Definition nat_gen_example : G nat :=
  choose (0, 10)%nat.


Module Type GEN_ALIVE2 (ADDR : MemoryAddress.ADDRESS) (IP:MemoryAddress.INTPTR) (SIZEOF : Sizeof) (LLVMEvents:LLVM_INTERACTIONS(ADDR)(IP)(SIZEOF)).
  Import LLVMEvents.
  Import DV.

  Search G.
  Print failwith.
  
  Definition gen_uvalue_trivial `{MonadExc string G}: G uvalue :=
    failwith "bla".
  
  Fixpoint gen_uvalue `{MonadExc string G} (t : typ): G uvalue :=
    match t with
    | TYPE_I i =>
        match i with
        | 1%N =>
            returnGen UVALUE_I1 <*> (returnGen repr <*> (choose (0, 1)))            
            (* x <- choose (0,1);; *)
            (* returnGen (UVALUE_I1 (repr x))  *)
        | 8%N =>
            returnGen UVALUE_I8 <*> (returnGen repr <*> (choose (0, 2^8)))
            (* x <- choose (0,2 ^ 8);; *)
            (* returnGen (UVALUE_I8 (repr x)) *)
        | 32%N =>
            returnGen UVALUE_I32 <*> (returnGen repr <*> (choose (0, 2^32)))
            (* x <- choose (0, 2 ^ 32);; *)
            (* returnGen (UVALUE_I32 (repr x)) *)
        | 64%N =>
            returnGen UVALUE_I64 <*> (returnGen repr <*> (choose (0, 2^64)))
            (* x <- choose (0, 2 ^ 63);; *)
            (* returnGen (UVALUE_I64 (repr x)) *)
        | _ => failwith "Invalid size"
        end
    | TYPE_Float =>
        returnGen UVALUE_Float <*> fing32
    | TYPE_Double =>
        returnGen UVALUE_None (* FailGen *)
    | TYPE_Void => returnGen UVALUE_None
    | TYPE_Vector sz subtyp =>
        returnGen UVALUE_Vector <*> vectorOf (N.to_nat sz) (gen_uvalue subtyp)
    | TYPE_Array sz subtyp =>
        returnGen UVALUE_Array <*> vectorOf (N.to_nat sz) (gen_uvalue subtyp)
    | _ => failwith "Unimplemented uvalue generators"
    end.
  
End GEN_ALIVE2.
 
(* Extract Inlined Constant fst => "fst". *)
(* Extract Inlined Constant app => "append". *)
(* Extract Inlined Constant rev => "rev". *)
(* Extract Inlined Constant map => "map". *)
(* Extract Inlined Constant combine => "combine". *)
(* (* Extract Inlined Constant eqn => "( == )". *) *)

(* Recursive Extraction nat_gen_example. *)