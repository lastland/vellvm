(* begin hide *)
From Coq Require Import
     String Morphisms.

Require Import List.
Import ListNotations.

From ITree Require Import
     ITree
     Basics.Monad
     Eq.Eqit
     TranslateFacts.

From TwoPhase Require Import
     Utilities
     Utils.MapMonadExtra
     Semantics
     Theory.InterpreterCFG.

Open Scope list_scope.
Open Scope itree_scope.

Import ITreeNotations.

Module InstrLemmas (IS : InterpreterStack) (TOP : LLVMTopLevel IS).
  Module CFGT := CFGTheory IS TOP.


  Export CFGT.
  Export TOP.
  Export IS.
  Export IS.LLVM.

  Import SemNotations.
  (* end hide *)

  (** * Lemmas related to the semantics of instructions (and terminators)
  This file contains essentially proof rules specifying the behavior of instructions,
   allowing for symbolic execution in refinement proofs.
   *)

  (** Helper lemmas that should probably be moved *)
  (* TODO: Move this *)
  Lemma interp_cfg2_concretize_or_pick_concrete :
    forall (uv : uvalue) (dv : dvalue) g l,
      is_concrete uv = true ->
      uvalue_to_dvalue uv = inr dv ->
      ℑ2 (concretize_or_pick uv) g l ≈ Ret2 g l dv.
  Proof.
    intros * CONC CONV.
    unfold concretize_or_pick.
    rewrite CONC.
    cbn.
    unfold lift_err.
    rewrite CONV.
    rewrite interp_cfg2_ret.
    reflexivity.
  Qed.

  (* TODO: Move this *)
  Lemma interp_cfg3_concretize_or_pick_concrete_exists :
    forall (uv : uvalue) g l,
      is_concrete uv = true ->
      exists dv, uvalue_to_dvalue uv = inr dv /\ ℑ2 (concretize_or_pick uv) g l ≈ Ret2 g l dv.
  Proof.
    intros uv g ρ CONC.
    pose proof is_concrete_uvalue_to_dvalue uv CONC as (dv & CONV).
    exists dv.
    split; auto.
    apply interp_cfg2_concretize_or_pick_concrete; auto.
  Qed.

  (* TODO; Move this *)
  Lemma interp_cfg2_concretize_or_pick_not_concrete :
    forall (uv : uvalue) (dv : dvalue) g l,
      is_concrete uv = false ->
      ℑ2 (concretize_or_pick uv) g l ≈ 'dv <- trigger (pick_uvalue uv) ;; Ret2 g l (proj1_sig dv).
  Proof.
    intros uv dv g ρ NCONC.
    unfold concretize_or_pick.
    rewrite NCONC.
    setoid_rewrite interp_cfg2_pick_proj1_sig.
    reflexivity.
  Qed.

  (** Lemmas about denote_instr *)

  Module InstrTactics.

    Hint Rewrite @bind_ret_l : rwexp.
    Hint Rewrite @translate_ret : rwexp.
    Hint Rewrite @interp_cfg2_ret : rwexp.
    Hint Rewrite @translate_bind : rwexp.
    Hint Rewrite @interp_cfg2_bind : rwexp.
    Hint Rewrite @translate_trigger : rwexp.

    Ltac go := autorewrite with rwexp.

    Ltac step :=
      match goal with
      | |- context [trigger (GlobalRead _)] =>
          match goal with
          | h: Maps.lookup _ _ = Some _ |- _ =>
              rewrite interp_cfg2_GR; [rewrite ?bind_ret_l | eauto]
          | h: Maps.lookup _ _ = None |- _ =>
              rewrite interp_cfg2_GR_fail; [rewrite ?bind_ret_l | eauto]
          end
      | |- context [trigger (LocalRead _)] =>
          match goal with
          | h: Maps.lookup _ _ = Some _ |- _ =>
              rewrite interp_cfg2_LR; [rewrite ?bind_ret_l | eauto]
          | h: Maps.lookup _ _ = None |- _ =>
              rewrite interp_cfg2_LR_fail; [rewrite ?bind_ret_l | eauto]
          end
      (* | |- context [trigger (Load _ _)] => rewrite interp_cfg3_Load; [rewrite ?bind_ret_l | eauto] *)
      (* | |- context [trigger (Store _ _)] => rewrite interp_cfg3_store; [rewrite ?bind_ret_l | eauto] *)
      | |- context [trigger (LocalWrite _ _)] => rewrite interp_cfg2_LW
      | |- context [trigger (GlobalWrite _ _)] => rewrite interp_cfg2_GW
      end.

  End InstrTactics.

  Import InstrTactics.

  (* Note: we know that we can prove that [l = l'] is always true.
   However there is no reason to put this burden on the hypothesis, it is easier to use this way.
   Arguably we could do the same for [g] and [m] but haven't felt the need for it so far.
   *)
  (* Lemma denote_instr_load : *)
  (*   forall (i : raw_id) volatile τ τp ptr align g l l' m a uv, *)
  (*     ⟦ ptr at τp ⟧e3 g l m ≈ Ret3 g l' m (UVALUE_Addr a) -> *)
  (*     read m a τ = inr uv -> *)
  (*     ⟦ (IId i, INSTR_Load volatile τ (τp, ptr) align) ⟧i3 g l m ≈ Ret3 g (Maps.add i uv l') m tt. *)
  (* Proof. *)
  (*   intros * EXP READ. *)
  (*   cbn. *)
  (*   go. *)
  (*   rewrite EXP. *)
  (*   go. *)
  (*   cbn. *)
  (*   go. *)
  (*   step. *)
  (*   step. *)
  (*   reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_store : *)
  (*   forall {M} `{MemMonad MemState M} *)
  (*     (i : int) volatile τv val τp ptr align uv a g l l' l'' m m', *)
  (*     ⟦ val at τv ⟧e3 g l m ≈ Ret3 g l' m uv -> *)
  (*     ⟦ ptr at τp ⟧e3 g l' m ≈ Ret3 g l'' m (UVALUE_Addr a) -> *)
  (*     MemMonad_runs_to (write a uv τv) m = Some (m', tt) -> *)
  (*     ⟦ (IVoid i, INSTR_Store volatile (τv, val) (τp, ptr) align) ⟧i3 g l m ≈ Ret3 g l'' m' tt. *)
  (* Proof. *)
  (*   intros * EXP PTR WRITE. *)
  (*   cbn. *)
  (*   go. *)
  (*   rewrite EXP. *)
  (*   go. *)

  (*   go. *)
  (*   rewrite PTR. *)
  (*   go. *)
  (*   cbn. *)
  (*   go. *)
  (*   rewrite interp_cfg3_store; eauto. *)
  (*   reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_store_exists : *)
  (*   forall (i : int) volatile τv val τp ptr align uv dv a g l l' l'' m aids, *)
  (*     ⟦ val at τv ⟧e3 g l m ≈ Ret3 g l' m uv -> *)
  (*     ⟦ ptr at τp ⟧e3 g l' m ≈ Ret3 g l'' m (UVALUE_Addr a) -> *)
  (*     uvalue_to_dvalue uv = inr dv -> *)
  (*     dvalue_has_dtyp dv τv -> *)
  (*     write_allowed (fst (ms_memory_stack m)) (fst a) (snd a) (N.to_nat (sizeof_dtyp τv)) = inr aids -> *)
  (*     exists m', *)
  (*       write (ms_memory_stack m) a dv = inr m' /\ ⟦ (IVoid i, INSTR_Store volatile (τv, val) (τp, ptr) align) ⟧i3 g l m ≈ Ret3 g l'' m' tt. *)
  (* Proof. *)
  (*   intros * EXP PTR CONV_UV TYP FITS. *)
  (*   apply write_succeeds with (v:=dv) in FITS as [m2 WRITE]; auto. *)
  (*   exists m2. split; auto. *)
  (*   eapply denote_instr_store; eauto. *)
  (* Qed. *)

  (* Lemma denote_instr_alloca_exists : *)
  (*   forall m τ g l i align nb, *)
  (*     non_void τ -> *)
  (*     exists m' a, *)
  (*       allocate m τ = inr (m', a) /\ *)
  (*       ⟦ (IId i, INSTR_Alloca τ nb align) ⟧i3 g l m ≈ Ret3 g (Maps.add i (UVALUE_Addr a) l) m' tt. *)
  (* Proof. *)
  (*   intros * NV. *)
  (*   pose proof interp_cfg3_alloca m τ g l NV as (m' & a & ALLOC & TRIGGER). *)
  (*   exists m', a. split; auto. *)

  (*   cbn. go.  *)
  (*   rewrite TRIGGER; cbn. *)
  (*   rewrite bind_ret_l. *)
  (*   step; reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_comment : *)
  (*   forall i str g l m, *)
  (*     ⟦ (IVoid i, INSTR_Comment str) ⟧i3 g l m ≈ Ret3 g l m tt. *)
  (* Proof. *)
  (*   intros *. *)
  (*   destruct i; cbn; go; reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_op : *)
  (*   forall i op uv g l l' m, *)
  (*     ⟦ op ⟧e3 g l m ≈ Ret3 g l' m uv -> *)
  (*     ⟦ (IId i, INSTR_Op op) ⟧i3 g l m ≈ Ret3 g (Maps.add i uv l') m tt. *)
  (* Proof. *)
  (*   intros * OP. *)
  (*   cbn. *)
  (*   unfold denote_op. *)
  (*   go. *)
  (*   rewrite OP. *)
  (*   go; step; reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_gep_array : *)
  (*   forall i size τ e_ix ix ptr a val g l l' l'' m, *)
  (*     ⟦ ptr at DTYPE_Pointer ⟧e3 g l m ≈ Ret3 g l' m (UVALUE_Addr a) *)
  (*     -> *)
  (*     ⟦ e_ix at DTYPE_I 64 ⟧e3 g l' m ≈ Ret3 g l'' m (UVALUE_I64 (repr (Z.of_nat ix))) *)
  (*     -> *)
  (*     get_array_cell m a ix τ = inr val *)
  (*     -> *)
  (*     exists ptr_res, *)
  (*       read m ptr_res τ = inr val /\ *)
  (*       ⟦ (IId i, INSTR_Op (OP_GetElementPtr (DTYPE_Array size τ) (DTYPE_Pointer, ptr) [(DTYPE_I 64, EXP_Integer 0%Z); (DTYPE_I 64, e_ix)])) ⟧i3 g l m *)
  (*       ≈ *)
  (*       Ret3 g (Maps.add i (UVALUE_Addr ptr_res) l'') m tt.  *)
  (* Proof. *)
  (*   intros * PTR IX GET. *)

  (*   pose proof interp_cfg3_GEP_array τ a size g l'' m val ix GET as (ptr_res & EQ & READ). *)
  (*   exists ptr_res. split; auto. *)

  (*   cbn. *)
  (*   go. *)
  (*   rewrite PTR. *)
  (*   go. *)
  (*   rewrite !bind_bind. *)
  (*   rewrite IX; cbn. *)
  (*   go. *)
  (*   cbn. *)
  (*   unfold ITree.map. *)
  (*   go. *)
  (*   rewrite EQ. *)
  (*   go. *)
  (*   step. *)
  (*   reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_gep_array' : *)
  (*   forall i size τ e_ix ix ptr a val g l l' l'' m, *)
  (*     ⟦ ptr at DTYPE_Pointer ⟧e3 g l m ≈ Ret3 g l' m (UVALUE_Addr a) *)
  (*     -> *)
  (*     ⟦ e_ix at DTYPE_I 64 ⟧e3 g l' m ≈ Ret3 g l'' m (UVALUE_I64 (repr (Z.of_nat ix))) *)
  (*     -> *)
  (*     get_array_cell m a ix τ = inr val *)
  (*     -> *)
  (*     exists ptr_res, *)
  (*       read m ptr_res τ = inr val /\ *)
  (*       handle_gep_addr (DTYPE_Array size τ) a [DVALUE_I64 (repr 0); DVALUE_I64 (repr (Z.of_nat ix))] = inr ptr_res /\ *)
  (*       ⟦ (IId i, INSTR_Op (OP_GetElementPtr (DTYPE_Array size τ) (DTYPE_Pointer, ptr) [(DTYPE_I 64, EXP_Integer 0%Z); (DTYPE_I 64, e_ix)])) ⟧i3 g l m *)
  (*       ≈ *)
  (*       Ret3 g (Maps.add i (UVALUE_Addr ptr_res) l'') m tt. *)
  (* Proof. *)
  (*   intros * PTR IX GET. *)

  (*   pose proof interp_cfg3_GEP_array' τ a size g l'' m val ix GET as (ptr_res & EQ & GEP & READ). *)
  (*   exists ptr_res. *)
  (*   split; auto. *)
  (*   split; auto. *)

  (*   cbn. *)
  (*   go. *)
  (*   rewrite !bind_bind. *)
  (*   rewrite PTR. *)
  (*   go. *)
  (*   rewrite IX. *)
  (*   go. *)
  (*   cbn; unfold ITree.map. *)
  (*   go. *)
  (*   rewrite EQ. *)
  (*   go. *)
  (*   step. *)
  (*   reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_gep_array_no_read_addr : *)
  (*   forall i size τ e_ix ix ptr a g l l' l'' m ptr_res, *)
  (*     ⟦ ptr at DTYPE_Pointer ⟧e3 g l m ≈ Ret3 g l' m (UVALUE_Addr a) *)
  (*     -> *)
  (*     ⟦ e_ix at DTYPE_I 64 ⟧e3 g l' m ≈ Ret3 g l'' m (UVALUE_I64 (repr (Z.of_nat ix))) *)
  (*     -> *)
  (*     dtyp_fits m a (DTYPE_Array size τ) -> *)
  (*     handle_gep_addr (DTYPE_Array size τ) a [DVALUE_I64 (Int64.repr 0); DVALUE_I64 (Int64.repr (Z.of_nat ix))] = inr ptr_res -> *)
  (*     ⟦ (IId i, INSTR_Op (OP_GetElementPtr (DTYPE_Array size τ) (DTYPE_Pointer, ptr) [(DTYPE_I 64, EXP_Integer 0%Z); (DTYPE_I 64, e_ix)])) ⟧i3 g l m *)
  (*     ≈ *)
  (*     Ret3 g (Maps.add i (UVALUE_Addr ptr_res) l'') m tt.  *)
  (* Proof. *)
  (*   intros * PTR IX FITS HGEP. *)
  (*   pose proof @interp_cfg3_GEP_array_no_read_addr τ a size g l'' m ix ptr_res FITS. *)

  (*   cbn. *)
  (*   go. *)
  (*   rewrite PTR. *)
  (*   go. *)
  (*   rewrite IX. *)
  (*   go. *)
  (*   cbn; unfold ITree.map; go. *)
  (*   rewrite H; auto. *)
  (*   go. *)
  (*   step. *)
  (*   reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_gep_array_no_read : *)
  (*   forall i size τ e_ix ix ptr a g l l' l'' m, *)
  (*     ⟦ ptr at DTYPE_Pointer ⟧e3 g l m ≈ Ret3 g l' m (UVALUE_Addr a) *)
  (*     -> *)
  (*     ⟦ e_ix at DTYPE_I 64 ⟧e3 g l' m ≈ Ret3 g l'' m (UVALUE_I64 (repr (Z.of_nat ix))) *)
  (*     -> *)
  (*     dtyp_fits m a (DTYPE_Array size τ) -> *)
  (*     exists ptr_res, *)
  (*       handle_gep_addr (DTYPE_Array size τ) a [DVALUE_I64 (repr 0); DVALUE_I64 (repr (Z.of_nat ix))] = inr ptr_res /\ *)
  (*       ⟦ (IId i, INSTR_Op (OP_GetElementPtr (DTYPE_Array size τ) (DTYPE_Pointer, ptr) [(DTYPE_I 64, EXP_Integer 0%Z); (DTYPE_I 64, e_ix)])) ⟧i3 g l m *)
  (*       ≈ *)
  (*       Ret3 g (Maps.add i (UVALUE_Addr ptr_res) l'') m tt. *)
  (* Proof. *)
  (*   intros * PTR IX FITS. *)

  (*   pose proof interp_cfg3_GEP_array_no_read τ a size g l'' m ix FITS as (ptr_res & EQ & GEP). *)
  (*   exists ptr_res. *)
  (*   split; auto. *)

  (*   cbn. *)
  (*   go. *)
  (*   rewrite PTR. *)
  (*   go. *)
  (*   rewrite IX. *)
  (*   unfold ITree.map; cbn. *)
  (*   go. *)
  (*   cbn. *)
  (*   go. *)
  (*   rewrite EQ. *)
  (*   go. *)
  (*   step; reflexivity. *)
  (* Qed. *)

  (* Lemma denote_instr_intrinsic : *)
  (*   forall i τ fn in_n sem_f args arg_vs conc_args res g l m, *)
  (*     @intrinsic_exp dtyp (EXP_Ident (ID_Global (Name fn))) = Some in_n *)
  (*     -> *)
  (*     assoc in_n (defs_assoc) = Some sem_f *)
  (*     -> *)
  (*     ℑ3 (map_monad (fun '(t, op) => translate exp_to_instr ⟦ op at t ⟧e) args) g l m *)
  (*     ≈ *)
  (*     Ret3 g l m arg_vs *)
  (*     -> *)
  (*     ℑ3 (map_monad (fun uv : uvalue => pickUnique uv) arg_vs) g l m *)
  (*     ≈ *)
  (*     Ret3 g l m conc_args *)
  (*     -> *)
  (*     sem_f conc_args = inr res *)
  (*     -> *)
  (*     ⟦ (IId i, INSTR_Call (τ, EXP_Ident (ID_Global (Name fn))) args) ⟧i3 g l m *)
  (*     ≈ *)
  (*     Ret3 g (FMapAList.alist_add i (dvalue_to_uvalue res) l) m tt. *)
  (* Proof. *)
  (*   intros * INTRINSIC ASSOC MAP CONCARGS RES. *)

  (*   cbn. *)
  (*   go. *)
  (*   rewrite MAP. *)
  (*   go. *)
  (*   cbn in *. *)
  (*   rewrite INTRINSIC. *)
  (*   go. *)
  (*   rewrite CONCARGS. *)
  (*   unfold ITree.map; go. *)
  (*   rewrite interp_cfg3_intrinsic; eauto. *)
  (*   go. *)
  (*   step. *)
  (*   reflexivity. *)
  (* Qed. *)

  (* Lemma denote_term_br_l : *)
  (*   forall (e : exp dtyp) b1 b2 g l l' m, *)
  (*     ⟦ e at DTYPE_I 1 ⟧e3 g l m ≈ Ret3 g l' m (UVALUE_I1 one) -> *)
  (*     ⟦ TERM_Br (DTYPE_I 1%N, e) b1 b2 ⟧t3 g l m ≈ Ret3 g l' m (inl b1). *)
  (* Proof. *)
  (*   intros * EXP. *)
  (*   simpl. *)
  (*   go. *)
  (*   rewrite EXP; go. *)
  (*   cbn. *)
  (*   go. *)
  (*   cbn. *)
  (*   go. *)
  (*   reflexivity. *)
  (* Qed. *)

  (* Lemma denote_term_br_r : *)
  (*   forall (e : exp dtyp) b1 b2 g l l' m, *)
  (*     ⟦ e at DTYPE_I 1 ⟧e3 g l m ≈ Ret3 g l' m (UVALUE_I1 zero) -> *)
  (*     ⟦ TERM_Br (DTYPE_I 1%N, e) b1 b2 ⟧t3 g l m ≈ Ret3 g l' m (inl b2). *)
  (* Proof. *)
  (*   intros * EXP. *)
  (*   simpl. *)
  (*   go. *)
  (*   rewrite EXP; go. *)
  (*   cbn. *)
  (*   go. *)
  (*   cbn. *)
  (*   go. *)
  (*   reflexivity. *)
  (* Qed. *)

  (* Lemma denote_term_br_1 : *)
  (*   forall b g l m, *)
  (*     ⟦ TERM_Br_1 b ⟧t3 g l m ≈ Ret3 g l m (inl b). *)
  (* Proof. *)
  (*   intros b g ρ m. *)
  (*   cbn. *)
  (*   go. *)
  (*   reflexivity. *)
  (* Qed. *)
End InstrLemmas.
