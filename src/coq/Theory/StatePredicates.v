(* begin hide *)
From TwoPhase Require Import
     Semantics.LLVMParams
     Semantics.Lang.
(* end hide *)

(** * Utilities to build predicates and relations over VIR's state *)

Definition pred T : Type := T -> Prop.
Definition rel  T : Type := T -> T -> Prop.

Definition conj_pred {T} (P1 P2: pred T) : pred T :=
  fun x => P1 x /\ P2 x.

Definition conj_rel {T} (R1 R2: rel T) : rel T :=
  fun x y => R1 x y /\ R2 x y.

Infix "×" := conj_rel (at level 30, right associativity).

Module CFG_LEVEL (LP : LLVMParams) (LLVM : Lang LP).
  Import LP.
  Import LLVM.
  Import MEM.
  Import MEM.MMEP.
  Import MEM.MMEP.MMSP.

  Definition state_cfg : Type := MemState * (local_env * global_env).

  Definition state_cfg_T (T:Type): Type
    := MemState * (local_env * (global_env * T)).

  Definition state_cfgP := pred state_cfg.
  Definition state_cfg_TP {T : Type} := pred (state_cfg_T T).
  Definition state_cfgR := rel state_cfg.
  Definition state_cfg_TR {T : Type} := rel (state_cfg_T T).

  Definition lift_pure_cfgP {T : Type} (P : pred T) : @state_cfg_TP T :=
    fun '(_,(_,(_,v))) => P v.
  Definition lift_pure_cfgR {T : Type} (P : rel T) : @state_cfg_TR T :=
    fun '(_,(_,(_,v))) '(_,(_,(_,v'))) => P v v'.

  Definition lift_state_cfgP {T : Type} (P : state_cfgP) : @state_cfg_TP T :=
    fun '(m,(l,(g,_))) => P (m,(l,g)).
  Definition lift_state_cfgR {T : Type} (P : state_cfgR) : @state_cfg_TR T :=
    fun '(m,(l,(g,_))) '(m',(l',(g',_))) => P (m,(l,g)) (m',(l',g')).
  
  Notation "↑" :=  lift_state_cfgP.
End CFG_LEVEL.

