/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Sébastien Gouëzel, Yury Kudryashov
-/
import dynamics.ergodic.measure_preserving
import linear_algebra.determinant
import linear_algebra.matrix.diagonal
import linear_algebra.matrix.transvection
import measure_theory.constructions.pi
import measure_theory.measure.stieltjes
import measure_theory.measure.haar_of_basis

/-!
# Lebesgue measure on the real line and on `ℝⁿ`

We show that the Lebesgue measure on the real line (constructed as a particular case of additive
Haar measure on inner product spaces) coincides with the Stieltjes measure associated
to the function `x ↦ x`. We deduce properties of this measure on `ℝ`, and then of the product
Lebesgue measure on `ℝⁿ`. In particular, we prove that they are translation invariant.

We show that, on `ℝⁿ`, a linear map acts on Lebesgue measure by rescaling it through the absolute
value of its determinant, in `real.map_linear_map_volume_pi_eq_smul_volume_pi`.

More properties of the Lebesgue measure are deduced from this in `haar_lebesgue.lean`, where they
are proved more generally for any additive Haar measure on a finite-dimensional real vector space.
-/

noncomputable theory
open classical set filter measure_theory measure_theory.measure topological_space
open ennreal (of_real)
open_locale big_operators ennreal nnreal topology

/-!
### Definition of the Lebesgue measure and lengths of intervals
-/

namespace real

variables {ι : Type*} [fintype ι]

/-- The volume on the real line (as a particular case of the volume on a finite-dimensional
inner product space) coincides with the Stieltjes measure coming from the identity function. -/
lemma volume_eq_stieltjes_id : (volume : measure ℝ) = stieltjes_function.id.measure :=
begin
  haveI : is_add_left_invariant stieltjes_function.id.measure :=
  ⟨λ a, eq.symm $ real.measure_ext_Ioo_rat $ λ p q,
    by simp only [measure.map_apply (measurable_const_add a) measurable_set_Ioo,
      sub_sub_sub_cancel_right, stieltjes_function.measure_Ioo, stieltjes_function.id_left_lim,
      stieltjes_function.id_apply, id.def, preimage_const_add_Ioo]⟩,
  have A : stieltjes_function.id.measure (std_orthonormal_basis ℝ ℝ).to_basis.parallelepiped = 1,
  { change stieltjes_function.id.measure (parallelepiped (std_orthonormal_basis ℝ ℝ)) = 1,
    rcases parallelepiped_orthonormal_basis_one_dim (std_orthonormal_basis ℝ ℝ) with H|H;
    simp only [H, stieltjes_function.measure_Icc, stieltjes_function.id_apply, id.def, tsub_zero,
      stieltjes_function.id_left_lim, sub_neg_eq_add, zero_add, ennreal.of_real_one] },
  conv_rhs { rw [add_haar_measure_unique stieltjes_function.id.measure
    (std_orthonormal_basis ℝ ℝ).to_basis.parallelepiped, A] },
  simp only [volume, basis.add_haar, one_smul],
end

theorem volume_val (s) : volume s = stieltjes_function.id.measure s :=
by simp [volume_eq_stieltjes_id]

@[simp] lemma volume_Ico {a b : ℝ} : volume (Ico a b) = of_real (b - a) :=
by simp [volume_val]

@[simp] lemma volume_Icc {a b : ℝ} : volume (Icc a b) = of_real (b - a) :=
by simp [volume_val]

@[simp] lemma volume_Ioo {a b : ℝ} : volume (Ioo a b) = of_real (b - a) :=
by simp [volume_val]

@[simp] lemma volume_Ioc {a b : ℝ} : volume (Ioc a b) = of_real (b - a) :=
by simp [volume_val]

@[simp] lemma volume_singleton {a : ℝ} : volume ({a} : set ℝ) = 0 :=
by simp [volume_val]

@[simp] lemma volume_univ : volume (univ : set ℝ) = ∞ :=
ennreal.eq_top_of_forall_nnreal_le $ λ r,
  calc (r : ℝ≥0∞) = volume (Icc (0 : ℝ) r) : by simp
              ... ≤ volume univ            : measure_mono (subset_univ _)

@[simp] lemma volume_ball (a r : ℝ) :
  volume (metric.ball a r) = of_real (2 * r) :=
by rw [ball_eq_Ioo, volume_Ioo, ← sub_add, add_sub_cancel', two_mul]

@[simp] lemma volume_closed_ball (a r : ℝ) :
  volume (metric.closed_ball a r) = of_real (2 * r) :=
by rw [closed_ball_eq_Icc, volume_Icc, ← sub_add, add_sub_cancel', two_mul]

@[simp] lemma volume_emetric_ball (a : ℝ) (r : ℝ≥0∞) :
  volume (emetric.ball a r) = 2 * r :=
begin
  rcases eq_or_ne r ∞ with rfl|hr,
  { rw [metric.emetric_ball_top, volume_univ, two_mul, ennreal.top_add] },
  { lift r to ℝ≥0 using hr,
    rw [metric.emetric_ball_nnreal, volume_ball, two_mul, ← nnreal.coe_add,
      ennreal.of_real_coe_nnreal, ennreal.coe_add, two_mul] }
end

@[simp] lemma volume_emetric_closed_ball (a : ℝ) (r : ℝ≥0∞) :
  volume (emetric.closed_ball a r) = 2 * r :=
begin
  rcases eq_or_ne r ∞ with rfl|hr,
  { rw [emetric.closed_ball_top, volume_univ, two_mul, ennreal.top_add] },
  { lift r to ℝ≥0 using hr,
    rw [metric.emetric_closed_ball_nnreal, volume_closed_ball, two_mul, ← nnreal.coe_add,
      ennreal.of_real_coe_nnreal, ennreal.coe_add, two_mul] }
end

instance has_no_atoms_volume : has_no_atoms (volume : measure ℝ) :=
⟨λ x, volume_singleton⟩

@[simp] lemma volume_interval {a b : ℝ} : volume (uIcc a b) = of_real (|b - a|) :=
by rw [←Icc_min_max, volume_Icc, max_sub_min_eq_abs]

@[simp] lemma volume_Ioi {a : ℝ} : volume (Ioi a) = ∞ :=
top_unique $ le_of_tendsto' ennreal.tendsto_nat_nhds_top $ λ n,
calc (n : ℝ≥0∞) = volume (Ioo a (a + n)) : by simp
... ≤ volume (Ioi a) : measure_mono Ioo_subset_Ioi_self

@[simp] lemma volume_Ici {a : ℝ} : volume (Ici a) = ∞ :=
by simp [← measure_congr Ioi_ae_eq_Ici]

@[simp] lemma volume_Iio {a : ℝ} : volume (Iio a) = ∞ :=
top_unique $ le_of_tendsto' ennreal.tendsto_nat_nhds_top $ λ n,
calc (n : ℝ≥0∞) = volume (Ioo (a - n) a) : by simp
... ≤ volume (Iio a) : measure_mono Ioo_subset_Iio_self

@[simp] lemma volume_Iic {a : ℝ} : volume (Iic a) = ∞ :=
by simp [← measure_congr Iio_ae_eq_Iic]

instance locally_finite_volume : is_locally_finite_measure (volume : measure ℝ) :=
⟨λ x, ⟨Ioo (x - 1) (x + 1),
  is_open.mem_nhds is_open_Ioo ⟨sub_lt_self _ zero_lt_one, lt_add_of_pos_right _ zero_lt_one⟩,
  by simp only [real.volume_Ioo, ennreal.of_real_lt_top]⟩⟩

instance is_finite_measure_restrict_Icc (x y : ℝ) : is_finite_measure (volume.restrict (Icc x y)) :=
⟨by simp⟩

instance is_finite_measure_restrict_Ico (x y : ℝ) : is_finite_measure (volume.restrict (Ico x y)) :=
⟨by simp⟩

instance is_finite_measure_restrict_Ioc (x y : ℝ) : is_finite_measure (volume.restrict (Ioc x y)) :=
 ⟨by simp⟩

instance is_finite_measure_restrict_Ioo (x y : ℝ) : is_finite_measure (volume.restrict (Ioo x y)) :=
⟨by simp⟩

lemma volume_le_diam (s : set ℝ) : volume s ≤ emetric.diam s :=
begin
  by_cases hs : metric.bounded s,
  { rw [real.ediam_eq hs, ← volume_Icc],
    exact volume.mono (real.subset_Icc_Inf_Sup_of_bounded hs) },
  { rw metric.ediam_of_unbounded hs, exact le_top }
end

lemma _root_.filter.eventually.volume_pos_of_nhds_real
  {p : ℝ → Prop} {a : ℝ} (h : ∀ᶠ x in 𝓝 a, p x) :
  (0 : ℝ≥0∞) < volume {x | p x} :=
begin
  rcases h.exists_Ioo_subset with ⟨l, u, hx, hs⟩,
  refine lt_of_lt_of_le _ (measure_mono hs),
  simpa [-mem_Ioo] using hx.1.trans hx.2
end

/-!
### Volume of a box in `ℝⁿ`
-/

lemma volume_Icc_pi {a b : ι → ℝ} : volume (Icc a b) = ∏ i, ennreal.of_real (b i - a i) :=
begin
  rw [← pi_univ_Icc, volume_pi_pi],
  simp only [real.volume_Icc]
end

@[simp] lemma volume_Icc_pi_to_real {a b : ι → ℝ} (h : a ≤ b) :
  (volume (Icc a b)).to_real = ∏ i, (b i - a i) :=
by simp only [volume_Icc_pi, ennreal.to_real_prod, ennreal.to_real_of_real (sub_nonneg.2 (h _))]

lemma volume_pi_Ioo {a b : ι → ℝ} :
  volume (pi univ (λ i, Ioo (a i) (b i))) = ∏ i, ennreal.of_real (b i - a i) :=
(measure_congr measure.univ_pi_Ioo_ae_eq_Icc).trans volume_Icc_pi

@[simp] lemma volume_pi_Ioo_to_real {a b : ι → ℝ} (h : a ≤ b) :
  (volume (pi univ (λ i, Ioo (a i) (b i)))).to_real = ∏ i, (b i - a i) :=
by simp only [volume_pi_Ioo, ennreal.to_real_prod, ennreal.to_real_of_real (sub_nonneg.2 (h _))]

lemma volume_pi_Ioc {a b : ι → ℝ} :
  volume (pi univ (λ i, Ioc (a i) (b i))) = ∏ i, ennreal.of_real (b i - a i) :=
(measure_congr measure.univ_pi_Ioc_ae_eq_Icc).trans volume_Icc_pi

@[simp] lemma volume_pi_Ioc_to_real {a b : ι → ℝ} (h : a ≤ b) :
  (volume (pi univ (λ i, Ioc (a i) (b i)))).to_real = ∏ i, (b i - a i) :=
by simp only [volume_pi_Ioc, ennreal.to_real_prod, ennreal.to_real_of_real (sub_nonneg.2 (h _))]

lemma volume_pi_Ico {a b : ι → ℝ} :
  volume (pi univ (λ i, Ico (a i) (b i))) = ∏ i, ennreal.of_real (b i - a i) :=
(measure_congr measure.univ_pi_Ico_ae_eq_Icc).trans volume_Icc_pi

@[simp] lemma volume_pi_Ico_to_real {a b : ι → ℝ} (h : a ≤ b) :
  (volume (pi univ (λ i, Ico (a i) (b i)))).to_real = ∏ i, (b i - a i) :=
by simp only [volume_pi_Ico, ennreal.to_real_prod, ennreal.to_real_of_real (sub_nonneg.2 (h _))]

@[simp] lemma volume_pi_ball (a : ι → ℝ) {r : ℝ} (hr : 0 < r) :
  volume (metric.ball a r) = ennreal.of_real ((2 * r) ^ fintype.card ι) :=
begin
  simp only [volume_pi_ball a hr, volume_ball, finset.prod_const],
  exact (ennreal.of_real_pow (mul_nonneg zero_le_two hr.le) _).symm
end

@[simp] lemma volume_pi_closed_ball (a : ι → ℝ) {r : ℝ} (hr : 0 ≤ r) :
  volume (metric.closed_ball a r) = ennreal.of_real ((2 * r) ^ fintype.card ι) :=
begin
  simp only [volume_pi_closed_ball a hr, volume_closed_ball, finset.prod_const],
  exact (ennreal.of_real_pow (mul_nonneg zero_le_two hr) _).symm
end

lemma volume_pi_le_prod_diam (s : set (ι → ℝ)) :
  volume s ≤ ∏ i : ι, emetric.diam (function.eval i '' s) :=
calc volume s ≤ volume (pi univ (λ i, closure (function.eval i '' s))) :
  volume.mono $ subset.trans (subset_pi_eval_image univ s) $ pi_mono $ λ i hi, subset_closure
          ... = ∏ i, volume (closure $ function.eval i '' s) :
  volume_pi_pi _
          ... ≤ ∏ i : ι, emetric.diam (function.eval i '' s) :
  finset.prod_le_prod' $ λ i hi, (volume_le_diam _).trans_eq (emetric.diam_closure _)

lemma volume_pi_le_diam_pow (s : set (ι → ℝ)) :
  volume s ≤ emetric.diam s ^ fintype.card ι :=
calc volume s ≤ ∏ i : ι, emetric.diam (function.eval i '' s) : volume_pi_le_prod_diam s
          ... ≤ ∏ i : ι, (1 : ℝ≥0) * emetric.diam s                      :
  finset.prod_le_prod' $ λ i hi, (lipschitz_with.eval i).ediam_image_le s
          ... = emetric.diam s ^ fintype.card ι              :
  by simp only [ennreal.coe_one, one_mul, finset.prod_const, fintype.card]

/-!
### Images of the Lebesgue measure under multiplication in ℝ
-/

lemma smul_map_volume_mul_left {a : ℝ} (h : a ≠ 0) :
  ennreal.of_real (|a|) • measure.map ((*) a) volume = volume :=
begin
  refine (real.measure_ext_Ioo_rat $ λ p q, _).symm,
  cases lt_or_gt_of_ne h with h h,
  { simp only [real.volume_Ioo, measure.smul_apply, ← ennreal.of_real_mul (le_of_lt $ neg_pos.2 h),
      measure.map_apply (measurable_const_mul a) measurable_set_Ioo, neg_sub_neg,
      neg_mul, preimage_const_mul_Ioo_of_neg _ _ h, abs_of_neg h, mul_sub, smul_eq_mul,
      mul_div_cancel' _ (ne_of_lt h)] },
  { simp only [real.volume_Ioo, measure.smul_apply, ← ennreal.of_real_mul (le_of_lt h),
      measure.map_apply (measurable_const_mul a) measurable_set_Ioo, preimage_const_mul_Ioo _ _ h,
      abs_of_pos h, mul_sub, mul_div_cancel' _ (ne_of_gt h), smul_eq_mul] }
end

lemma map_volume_mul_left {a : ℝ} (h : a ≠ 0) :
  measure.map ((*) a) volume = ennreal.of_real (|a⁻¹|) • volume :=
by conv_rhs { rw [← real.smul_map_volume_mul_left h, smul_smul,
  ← ennreal.of_real_mul (abs_nonneg _), ← abs_mul, inv_mul_cancel h, abs_one, ennreal.of_real_one,
  one_smul] }

@[simp] lemma volume_preimage_mul_left {a : ℝ} (h : a ≠ 0) (s : set ℝ) :
  volume (((*) a) ⁻¹' s) = ennreal.of_real (abs a⁻¹) * volume s :=
calc volume (((*) a) ⁻¹' s) = measure.map ((*) a) volume s :
  ((homeomorph.mul_left₀ a h).to_measurable_equiv.map_apply s).symm
... = ennreal.of_real (abs a⁻¹) * volume s : by { rw map_volume_mul_left h, refl }

lemma smul_map_volume_mul_right {a : ℝ} (h : a ≠ 0) :
  ennreal.of_real (|a|) • measure.map (* a) volume = volume :=
by simpa only [mul_comm] using real.smul_map_volume_mul_left h

lemma map_volume_mul_right {a : ℝ} (h : a ≠ 0) :
  measure.map (* a) volume = ennreal.of_real (|a⁻¹|) • volume :=
by simpa only [mul_comm] using real.map_volume_mul_left h

@[simp] lemma volume_preimage_mul_right {a : ℝ} (h : a ≠ 0) (s : set ℝ) :
  volume ((* a) ⁻¹' s) = ennreal.of_real (abs a⁻¹) * volume s :=
calc volume ((* a) ⁻¹' s) = measure.map (* a) volume s :
  ((homeomorph.mul_right₀ a h).to_measurable_equiv.map_apply s).symm
... = ennreal.of_real (abs a⁻¹) * volume s : by { rw map_volume_mul_right h, refl }

/-!
### Images of the Lebesgue measure under translation/linear maps in ℝⁿ
-/

open matrix

/-- A diagonal matrix rescales Lebesgue according to its determinant. This is a special case of
`real.map_matrix_volume_pi_eq_smul_volume_pi`, that one should use instead (and whose proof
uses this particular case). -/
lemma smul_map_diagonal_volume_pi [decidable_eq ι] {D : ι → ℝ} (h : det (diagonal D) ≠ 0) :
  ennreal.of_real (abs (det (diagonal D))) • measure.map ((diagonal D).to_lin') volume = volume :=
begin
  refine (measure.pi_eq (λ s hs, _)).symm,
  simp only [det_diagonal, measure.coe_smul, algebra.id.smul_eq_mul, pi.smul_apply],
  rw [measure.map_apply _ (measurable_set.univ_pi hs)],
  swap, { exact continuous.measurable (linear_map.continuous_on_pi _) },
  have : (matrix.to_lin' (diagonal D)) ⁻¹' (set.pi set.univ (λ (i : ι), s i))
    = set.pi set.univ (λ (i : ι), ((*) (D i)) ⁻¹' (s i)),
  { ext f,
    simp only [linear_map.coe_proj, algebra.id.smul_eq_mul, linear_map.smul_apply, mem_univ_pi,
      mem_preimage, linear_map.pi_apply, diagonal_to_lin'] },
  have B : ∀ i, of_real (abs (D i)) * volume (has_mul.mul (D i) ⁻¹' s i) = volume (s i),
  { assume i,
    have A : D i ≠ 0,
    { simp only [det_diagonal, ne.def] at h,
      exact finset.prod_ne_zero_iff.1 h i (finset.mem_univ i) },
    rw [volume_preimage_mul_left A, ← mul_assoc, ← ennreal.of_real_mul (abs_nonneg _), ← abs_mul,
      mul_inv_cancel A, abs_one, ennreal.of_real_one, one_mul] },
  rw [this, volume_pi_pi, finset.abs_prod,
    ennreal.of_real_prod_of_nonneg (λ i hi, abs_nonneg (D i)), ← finset.prod_mul_distrib],
  simp only [B]
end

/-- A transvection preserves Lebesgue measure. -/
lemma volume_preserving_transvection_struct [decidable_eq ι] (t : transvection_struct ι ℝ) :
  measure_preserving (t.to_matrix.to_lin') :=
begin
  /- We separate the coordinate along which there is a shearing from the other ones, and apply
  Fubini. Along this coordinate (and when all the other coordinates are fixed), it acts like a
  translation, and therefore preserves Lebesgue. -/
  let p : ι → Prop := λ i, i ≠ t.i,
  let α : Type* := {x // p x},
  let β : Type* := {x // ¬ (p x)},
  let g : (α → ℝ) → (β → ℝ) → (β → ℝ) := λ a b, (λ x, t.c * a ⟨t.j, t.hij.symm⟩) + b,
  let F : (α → ℝ) × (β → ℝ) → (α → ℝ) × (β → ℝ) :=
    λ p, (id p.1, g p.1 p.2),
  let e : (ι → ℝ) ≃ᵐ (α → ℝ) × (β → ℝ) := measurable_equiv.pi_equiv_pi_subtype_prod (λ i : ι, ℝ) p,
  have : (t.to_matrix.to_lin' : (ι → ℝ) → (ι → ℝ)) = e.symm ∘ F ∘ e,
  { cases t,
    ext f k,
    simp only [linear_equiv.map_smul, dite_eq_ite, linear_map.id_coe, p, ite_not,
      algebra.id.smul_eq_mul, one_mul, dot_product, std_basis_matrix,
      measurable_equiv.pi_equiv_pi_subtype_prod_symm_apply, id.def, transvection,
      pi.add_apply, zero_mul, linear_map.smul_apply, function.comp_app,
      measurable_equiv.pi_equiv_pi_subtype_prod_apply, matrix.transvection_struct.to_matrix_mk,
      matrix.mul_vec, linear_equiv.map_add, ite_mul, e, matrix.to_lin'_apply,
      pi.smul_apply, subtype.coe_mk, g, linear_map.add_apply, finset.sum_congr, matrix.to_lin'_one],
    by_cases h : t_i = k,
    { simp only [h, true_and, finset.mem_univ, if_true, eq_self_iff_true, finset.sum_ite_eq,
        one_apply, boole_mul, add_comm], },
    { simp only [h, ne.symm h, add_zero, if_false, finset.sum_const_zero, false_and, mul_zero] } },
  rw this,
  have A : measure_preserving e,
  { convert volume_preserving_pi_equiv_pi_subtype_prod (λ i : ι, ℝ) p },
  have B : measure_preserving F,
  { have g_meas : measurable (function.uncurry g),
    { have : measurable (λ (c : (α → ℝ)), c ⟨t.j, t.hij.symm⟩) :=
        measurable_pi_apply ⟨t.j, t.hij.symm⟩,
      refine (measurable_pi_lambda _ (λ i, measurable.const_mul _ _)).add measurable_snd,
      exact this.comp measurable_fst },
    exact (measure_preserving.id _).skew_product g_meas
      (eventually_of_forall (λ a, map_add_left_eq_self _ _)) },
  exact ((A.symm e).comp B).comp A,
end

/-- Any invertible matrix rescales Lebesgue measure through the absolute value of its
determinant. -/
lemma map_matrix_volume_pi_eq_smul_volume_pi [decidable_eq ι] {M : matrix ι ι ℝ} (hM : det M ≠ 0) :
  measure.map M.to_lin' volume = ennreal.of_real (abs (det M)⁻¹) • volume :=
begin
  -- This follows from the cases we have already proved, of diagonal matrices and transvections,
  -- as these matrices generate all invertible matrices.
  apply diagonal_transvection_induction_of_det_ne_zero _ M hM (λ D hD, _) (λ t, _)
    (λ A B hA hB IHA IHB, _),
  { conv_rhs { rw [← smul_map_diagonal_volume_pi hD] },
    rw [smul_smul, ← ennreal.of_real_mul (abs_nonneg _), ← abs_mul, inv_mul_cancel hD, abs_one,
      ennreal.of_real_one, one_smul] },
  { simp only [matrix.transvection_struct.det, ennreal.of_real_one,
      (volume_preserving_transvection_struct _).map_eq, one_smul, _root_.inv_one, abs_one] },
  { rw [to_lin'_mul, det_mul, linear_map.coe_comp, ← measure.map_map, IHB, measure.map_smul,
      IHA, smul_smul, ← ennreal.of_real_mul (abs_nonneg _), ← abs_mul, mul_comm, mul_inv],
    { apply continuous.measurable,
      apply linear_map.continuous_on_pi },
    { apply continuous.measurable,
      apply linear_map.continuous_on_pi } }
end

/-- Any invertible linear map rescales Lebesgue measure through the absolute value of its
determinant. -/
lemma map_linear_map_volume_pi_eq_smul_volume_pi {f : (ι → ℝ) →ₗ[ℝ] (ι → ℝ)} (hf : f.det ≠ 0) :
  measure.map f volume = ennreal.of_real (abs (f.det)⁻¹) • volume :=
begin
  -- this is deduced from the matrix case
  classical,
  let M := f.to_matrix',
  have A : f.det = det M, by simp only [linear_map.det_to_matrix'],
  have B : f = M.to_lin', by simp only [to_lin'_to_matrix'],
  rw [A, B],
  apply map_matrix_volume_pi_eq_smul_volume_pi,
  rwa A at hf
end

end real

section region_between

variable {α : Type*}

/-- The region between two real-valued functions on an arbitrary set. -/
def region_between (f g : α → ℝ) (s : set α) : set (α × ℝ) :=
{p : α × ℝ | p.1 ∈ s ∧ p.2 ∈ Ioo (f p.1) (g p.1)}

lemma region_between_subset (f g : α → ℝ) (s : set α) : region_between f g s ⊆ s ×ˢ univ :=
by simpa only [prod_univ, region_between, set.preimage, set_of_subset_set_of] using λ a, and.left

variables [measurable_space α] {μ : measure α} {f g : α → ℝ} {s : set α}

/-- The region between two measurable functions on a measurable set is measurable. -/
lemma measurable_set_region_between
  (hf : measurable f) (hg : measurable g) (hs : measurable_set s) :
  measurable_set (region_between f g s) :=
begin
  dsimp only [region_between, Ioo, mem_set_of_eq, set_of_and],
  refine measurable_set.inter _ ((measurable_set_lt (hf.comp measurable_fst) measurable_snd).inter
    (measurable_set_lt measurable_snd (hg.comp measurable_fst))),
  exact measurable_fst hs
end

/-- The region between two measurable functions on a measurable set is measurable;
a version for the region together with the graph of the upper function. -/
lemma measurable_set_region_between_oc
  (hf : measurable f) (hg : measurable g) (hs : measurable_set s) :
  measurable_set {p : α × ℝ | p.fst ∈ s ∧ p.snd ∈ Ioc (f p.fst) (g p.fst)} :=
begin
  dsimp only [region_between, Ioc, mem_set_of_eq, set_of_and],
  refine measurable_set.inter _ ((measurable_set_lt (hf.comp measurable_fst) measurable_snd).inter
    (measurable_set_le measurable_snd (hg.comp measurable_fst))),
  exact measurable_fst hs,
end

/-- The region between two measurable functions on a measurable set is measurable;
a version for the region together with the graph of the lower function. -/
lemma measurable_set_region_between_co
  (hf : measurable f) (hg : measurable g) (hs : measurable_set s) :
  measurable_set {p : α × ℝ | p.fst ∈ s ∧ p.snd ∈ Ico (f p.fst) (g p.fst)} :=
begin
  dsimp only [region_between, Ico, mem_set_of_eq, set_of_and],
  refine measurable_set.inter _ ((measurable_set_le (hf.comp measurable_fst) measurable_snd).inter
    (measurable_set_lt measurable_snd (hg.comp measurable_fst))),
  exact measurable_fst hs,
end

/-- The region between two measurable functions on a measurable set is measurable;
a version for the region together with the graphs of both functions. -/
lemma measurable_set_region_between_cc
  (hf : measurable f) (hg : measurable g) (hs : measurable_set s) :
  measurable_set {p : α × ℝ | p.fst ∈ s ∧ p.snd ∈ Icc (f p.fst) (g p.fst)} :=
begin
  dsimp only [region_between, Icc, mem_set_of_eq, set_of_and],
  refine measurable_set.inter _ ((measurable_set_le (hf.comp measurable_fst) measurable_snd).inter
    (measurable_set_le measurable_snd (hg.comp measurable_fst))),
  exact measurable_fst hs,
end

/-- The graph of a measurable function is a measurable set. -/
lemma measurable_set_graph (hf : measurable f) :
  measurable_set {p : α × ℝ | p.snd = f p.fst} :=
by simpa using measurable_set_region_between_cc hf hf measurable_set.univ

theorem volume_region_between_eq_lintegral'
  (hf : measurable f) (hg : measurable g) (hs : measurable_set s) :
  μ.prod volume (region_between f g s) = ∫⁻ y in s, ennreal.of_real ((g - f) y) ∂μ :=
begin
  classical,
  rw measure.prod_apply,
  { have h : (λ x, volume {a | x ∈ s ∧ a ∈ Ioo (f x) (g x)})
            = s.indicator (λ x, ennreal.of_real (g x - f x)),
    { funext x,
      rw indicator_apply,
      split_ifs,
      { have hx : {a | x ∈ s ∧ a ∈ Ioo (f x) (g x)} = Ioo (f x) (g x) := by simp [h, Ioo],
        simp only [hx, real.volume_Ioo, sub_zero] },
      { have hx : {a | x ∈ s ∧ a ∈ Ioo (f x) (g x)} = ∅ := by simp [h],
        simp only [hx, measure_empty] } },
    dsimp only [region_between, preimage_set_of_eq],
    rw [h, lintegral_indicator];
    simp only [hs, pi.sub_apply] },
  { exact measurable_set_region_between hf hg hs },
end

/-- The volume of the region between two almost everywhere measurable functions on a measurable set
    can be represented as a Lebesgue integral. -/
theorem volume_region_between_eq_lintegral [sigma_finite μ]
  (hf : ae_measurable f (μ.restrict s)) (hg : ae_measurable g (μ.restrict s))
  (hs : measurable_set s) :
  μ.prod volume (region_between f g s) = ∫⁻ y in s, ennreal.of_real ((g - f) y) ∂μ :=
begin
  have h₁ : (λ y, ennreal.of_real ((g - f) y))
          =ᵐ[μ.restrict s]
              λ y, ennreal.of_real ((ae_measurable.mk g hg - ae_measurable.mk f hf) y) :=
    (hg.ae_eq_mk.sub hf.ae_eq_mk).fun_comp _,
  have h₂ : (μ.restrict s).prod volume (region_between f g s) =
    (μ.restrict s).prod volume (region_between (ae_measurable.mk f hf) (ae_measurable.mk g hg) s),
  { apply measure_congr,
    apply eventually_eq.rfl.inter,
    exact ((quasi_measure_preserving_fst.ae_eq_comp hf.ae_eq_mk).comp₂ _ eventually_eq.rfl).inter
      (eventually_eq.rfl.comp₂ _ $ quasi_measure_preserving_fst.ae_eq_comp hg.ae_eq_mk) },
  rw [lintegral_congr_ae h₁,
      ← volume_region_between_eq_lintegral' hf.measurable_mk hg.measurable_mk hs],
  convert h₂ using 1,
  { rw measure.restrict_prod_eq_prod_univ,
    exact (measure.restrict_eq_self _ (region_between_subset f g s)).symm, },
  { rw measure.restrict_prod_eq_prod_univ,
    exact (measure.restrict_eq_self _
      (region_between_subset (ae_measurable.mk f hf) (ae_measurable.mk g hg) s)).symm },
end

theorem volume_region_between_eq_integral' [sigma_finite μ]
  (f_int : integrable_on f s μ) (g_int : integrable_on g s μ)
  (hs : measurable_set s) (hfg : f ≤ᵐ[μ.restrict s] g ) :
  μ.prod volume (region_between f g s) = ennreal.of_real (∫ y in s, (g - f) y ∂μ) :=
begin
  have h : g - f =ᵐ[μ.restrict s] (λ x, real.to_nnreal (g x - f x)),
    from hfg.mono (λ x hx, (real.coe_to_nnreal _ $ sub_nonneg.2 hx).symm),
  rw [volume_region_between_eq_lintegral f_int.ae_measurable g_int.ae_measurable hs,
    integral_congr_ae h, lintegral_congr_ae,
    lintegral_coe_eq_integral _ ((integrable_congr h).mp (g_int.sub f_int))],
  simpa only,
end

/-- If two functions are integrable on a measurable set, and one function is less than
    or equal to the other on that set, then the volume of the region
    between the two functions can be represented as an integral. -/
theorem volume_region_between_eq_integral [sigma_finite μ]
  (f_int : integrable_on f s μ) (g_int : integrable_on g s μ)
  (hs : measurable_set s) (hfg : ∀ x ∈ s, f x ≤ g x) :
  μ.prod volume (region_between f g s) = ennreal.of_real (∫ y in s, (g - f) y ∂μ) :=
volume_region_between_eq_integral' f_int g_int hs
  ((ae_restrict_iff' hs).mpr (eventually_of_forall hfg))

end region_between

/-- Consider a real set `s`. If a property is true almost everywhere in `s ∩ (a, b)` for
all `a, b ∈ s`, then it is true almost everywhere in `s`. Formulated with `μ.restrict`.
See also `ae_of_mem_of_ae_of_mem_inter_Ioo`. -/
lemma ae_restrict_of_ae_restrict_inter_Ioo
  {μ : measure ℝ} [has_no_atoms μ] {s : set ℝ} {p : ℝ → Prop}
  (h : ∀ a b, a ∈ s → b ∈ s → a < b → ∀ᵐ x ∂(μ.restrict (s ∩ Ioo a b)), p x) :
  ∀ᵐ x ∂(μ.restrict s), p x :=
begin
  /- By second-countability, we cover `s` by countably many intervals `(a, b)` (except maybe for
  two endpoints, which don't matter since `μ` does not have any atom). -/
  let T : s × s → set ℝ := λ p, Ioo p.1 p.2,
  let u := ⋃ (i : ↥s × ↥s), T i,
  have hfinite : (s \ u).finite := s.finite_diff_Union_Ioo',
  obtain ⟨A, A_count, hA⟩ :
    ∃ (A : set (↥s × ↥s)), A.countable ∧ (⋃ (i ∈ A), T i) = ⋃ (i : ↥s × ↥s), T i :=
    is_open_Union_countable _ (λ p, is_open_Ioo),
  have : s ⊆ (s \ u) ∪ (⋃ p ∈ A, s ∩ T p),
  { assume x hx,
    by_cases h'x : x ∈ ⋃ (i : ↥s × ↥s), T i,
    { rw ← hA at h'x,
      obtain ⟨p, pA, xp⟩ : ∃ (p : ↥s × ↥s), p ∈ A ∧ x ∈ T p,
        by simpa only [mem_Union, exists_prop, set_coe.exists, exists_and_distrib_right] using h'x,
      right,
      exact mem_bUnion pA ⟨hx, xp⟩ },
    { exact or.inl ⟨hx, h'x⟩ } },
  apply ae_restrict_of_ae_restrict_of_subset this,
  rw [ae_restrict_union_iff, ae_restrict_bUnion_iff _ A_count],
  split,
  { have : μ.restrict (s \ u) = 0, by simp only [restrict_eq_zero, hfinite.measure_zero],
    simp only [this, ae_zero] },
  { rintros ⟨⟨a, as⟩, ⟨b, bs⟩⟩ -,
    dsimp [T],
    rcases le_or_lt b a with hba|hab,
    { simp only [Ioo_eq_empty_of_le hba, inter_empty, restrict_empty, ae_zero] },
    { exact h a b as bs hab } }
end

/-- Consider a real set `s`. If a property is true almost everywhere in `s ∩ (a, b)` for
all `a, b ∈ s`, then it is true almost everywhere in `s`. Formulated with bare membership.
See also `ae_restrict_of_ae_restrict_inter_Ioo`. -/
lemma ae_of_mem_of_ae_of_mem_inter_Ioo
  {μ : measure ℝ} [has_no_atoms μ] {s : set ℝ} {p : ℝ → Prop}
  (h : ∀ a b, a ∈ s → b ∈ s → a < b → ∀ᵐ x ∂μ, x ∈ s ∩ Ioo a b → p x) :
  ∀ᵐ x ∂μ, x ∈ s → p x :=
begin
  /- By second-countability, we cover `s` by countably many intervals `(a, b)` (except maybe for
  two endpoints, which don't matter since `μ` does not have any atom). -/
  let T : s × s → set ℝ := λ p, Ioo p.1 p.2,
  let u := ⋃ (i : ↥s × ↥s), T i,
  have hfinite : (s \ u).finite := s.finite_diff_Union_Ioo',
  obtain ⟨A, A_count, hA⟩ :
    ∃ (A : set (↥s × ↥s)), A.countable ∧ (⋃ (i ∈ A), T i) = ⋃ (i : ↥s × ↥s), T i :=
    is_open_Union_countable _ (λ p, is_open_Ioo),
  have M : ∀ᵐ x ∂μ, x ∉ s \ u, from hfinite.countable.ae_not_mem _,
  have M' : ∀ᵐ x ∂μ, ∀ (i : ↥s × ↥s) (H : i ∈ A), x ∈ s ∩ T i → p x,
  { rw ae_ball_iff A_count,
    rintros ⟨⟨a, as⟩, ⟨b, bs⟩⟩ -,
    change ∀ᵐ (x : ℝ) ∂μ, x ∈ s ∩ Ioo a b → p x,
    rcases le_or_lt b a with hba|hab,
    { simp only [Ioo_eq_empty_of_le hba, inter_empty, is_empty.forall_iff, eventually_true,
        mem_empty_iff_false], },
    { exact h a b as bs hab } },
  filter_upwards [M, M'] with x hx h'x,
  assume xs,
  by_cases Hx : x ∈ ⋃ (i : ↥s × ↥s), T i,
  { rw ← hA at Hx,
    obtain ⟨p, pA, xp⟩ : ∃ (p : ↥s × ↥s), p ∈ A ∧ x ∈ T p,
      by simpa only [mem_Union, exists_prop, set_coe.exists, exists_and_distrib_right] using Hx,
    apply h'x p pA ⟨xs, xp⟩ },
  { exact false.elim (hx ⟨xs, Hx⟩) }
end
