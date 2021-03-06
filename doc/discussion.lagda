\section{Discussion}
\label{sec:discussion}

The |auto| function presented here is far from perfect. This section
not only discusses its limitations, but compares it to existing proof
automation techniques in interactive proof assistants.

%% REASON:
%%  I removed the section on performance here, since we can and
%%  should tone it down a whole bunch. My rewrites and possibly Agda's
%%  new treatment of natural numbers as Haskell integers (if addition is
%%  treated as a Haskell operation) sped our tactic up a WHOLE bunch.
%%
%%\paragraph{Performance}
%%First of all, the performance of the |auto| function is terrible. Any
%%proofs that require a depth greater than ten are intractable in
%%practice. This is an immediate consequence of Agda's poor compile-time
%%evaluation. The current implementation is call-by-name and does no
%%optimisation whatsoever. While a mature evaluator is beyond the scope
%%of this project, we believe that it is essential for Agda proofs to
%%scale beyond toy examples. Simple optimizations, such as the erasure
%%of the natural number indexes used in unification~\cite{brady-opt},
%%would certainly help speed up the proof search.

\paragraph{Restricted language fragment}
The |auto| function can only handle first-order terms. Even though
higher-order unification is not decidable in general, we believe that it
should be possible to adapt our algorithm to work on second-order
goals.
Furthermore, there are plenty of Agda features that are not
supported or ignored by our quotation functions, such as universe
polymorphism, instance arguments, and primitive functions.

Even for definitions that seem completely first-order, our |auto|
function can fail unexpectedly. Consider the following definition of
the pair type:
\begin{code}
  _×_ : (A B : Set) → Set
  A × B = Σ A (λ _ → B)

  pair : {A B : Set} -> A -> B -> A × B
  pair x y = x , y
\end{code}
Here a (non-dependent) pair is defined as a special case of the
dependent pair type |Σ|. Now consider the following trivial lemma:
\begin{code}
  andIntro : (A : Set) -> (B : Set) -> A × B
\end{code}
Somewhat surprisingly, trying to prove this lemma using our |auto|
function, providing the |pair| function as a hint, fails.
The |quoteGoal| construct always returns
the goal in normal form, which exposes the higher-order nature of |A ×
B|. Converting the goal |(A × (λ _ → B))| to a |PsTerm| will raise the
`exception' |unsupportedSyntax|; the goal type contains a lambda which
causes the proof search to fail before it has even started.

% \todo{No longer relevant; tactic also takes context}
% Furthermore, there are some limitations on the hints that may be
% stored in the hint database. At the moment, we construct every hint by
% quoting an Agda |Name|. Not all useful hints, however, have such a
% |Name|, such as any variables locally bound in the context by pattern
% matching or function arguments. For example, the following call to the
% |auto| function fails to produce the desired proof:
% \begin{code}
%   trivial : Even n → Even (n + 2)
%   trivial e = tactic (auto 5 hints)
% \end{code}
% The variable |e|, necessary to complete the proof is not part of the
% hint database. The |tactic| keyword in the upcoming Agda release
% addresses this, by providing both the current goal and a list of the
% terms bound in the local context as arguments to the tactic functions.
% \review{What if we remove e in the LHS of trivial, and ask the system
%   to find a proof for Even n -> Even (n+2)? Also, eliminate the
%   newline.}
% \pepijn{Do we want to mention that we can now easily pattern-match,
%   rewrite the paper to include the most recent version of |tactic|,
%   etc? Or should we just delete this section?}
% Wouter: I've commented out this section. It's hard to be precise here as
% long as Agda is still in flux.

\paragraph{Refinement}
The |auto| function returns a complete proof term or fails
entirely. This is not always desirable. We may want to return an
incomplete proof, that still has open holes that the user must
complete. The difficulty lies with the current implementation of Agda's
reflection mechanism, as it cannot generate an incomplete |Term|.

In the future, it may be interesting to explore how to integrate proof
automation using the reflection mechanism better with Agda's IDE. For
instance, we could create an IDE feature which replaces a call to |auto| with
the proof terms that it generates.
As a result, reloading the file
would no longer need to recompute the proof terms.

\paragraph{Metatheory}
The |auto| function is necessarily untyped because the interface of
Agda's reflection mechanism is untyped. Defining a well-typed
representation of dependent types in a dependently typed language
remains an open problem, despite various efforts in this
direction~\citep{james-phd,nisse,devriese,kipling}. If we had such a
representation, however, we could use the type information to prove
that when the |auto| function succeeds, the resulting term has the
correct type. As it stands, a bug in our |auto| function could
potentially produce an ill-typed proof term, that only causes a type
error when that term is unquoted.

\paragraph{Variables}
The astute reader will have noticed that the tactic we have
implemented is closer to Coq's |eauto| tactic than the |auto|
tactic. The difference between the two tactics lies in the treatment
of unification variables: |eauto| may introduce new variables during
unification; |auto| will never do so. It would be fairly
straightforward to restrict our tactic to only apply hints when all
variables known. A suitable instantiation algorithm, which we could
use instead of the more general unification algorithm in this paper,
has already been developed in previous work~\citep{vannoort}.

\paragraph{Technical limitations}

The |auto| tactic relies on the unification algorithm and proof search
mechanism we have implemented ourselves. These are all run \emph{at
  compile time}, using the reflection mechanism to try and find a
suitable proof term. It is very difficult to say anything meaningful
about the performance of the |auto| tactic, as Agda currently has no
mechanism for debugging or profiling programs run at compile time. We
hope that further advancement of the Agda compiler and associated
toolchain can help provide meaningful measurements of the performance
of |auto|. Similarly, a better (static) debugger would be invaluable
when trying to understand why a call to |auto| failed to produce the
desired proof.


% Finally, we should mention that a technical limitation in Agda's
% reflection mechanism prevents us from proving recursive theorems using
% the |auto| tactic. Ideally, we would like to

% As it stands, proving soundness of the
% |auto| function is non-trivial: we would need to define the typing
% rules of Agda's |Term| data type and prove that the |Term| we produce
% witnesses the validity of our goal |Term|.
% It may be slightly easier
% to ignore Agda's reflection mechanism and instead verify the
% metatheory of the Prolog interpreter: if a proof exists at some given
% depth, |dfs| should find it; any |Proof| returned by
% |dfs| should correspond to a valid derivation.
% \review{Somewhere early in the paper you say that working with a typed
%   representation of terms would not offer additional safety for the
%   proof search procedure. In the Metatheory paragraph in Section 6 you
%   seem to contradict that. Anyway, what I would be additionally
%   interested in here is to hear about whether a typed representation
%   might also help the effectiveness of the tactic. (Since fewer
%   potential proof terms would need to be considered?)}
% \pepijn{Nope, because we compute on the types... so typing the
%   metatheory wouldn't really allow us to make anything simpler, it
%   would just give a richer structure for the `Proof` objects. What I
%   mean here is that we could encode the proof structure as a list of
%   subgoals, and the partial proof as a function from a heterogeneous
%   list whose types are indexed by those subgoals, to a value whose
%   type is equal to the top-level goal.}
%% Wouter -- I've commented out part of this discussion. We only put it in there to make
%% an ICFP reviewer happy, if I remember correctly.

\subsection*{Related work}
There are several other interactive proof assistants, dependently
typed programming languages, and alternative forms of proof
automation in Agda. In the remainder of this section, we will briefly compare
the approach taken in this paper to these existing systems.

\paragraph{Coq}
Coq has rich support for proof automation. The Ltac language
and the many primitive, customizable tactics are extremely
powerful~\citep{chlipala}. Despite Coq's success, it is still
worthwhile to explore better methods for proof automation. Recent work
on Mtac~\citep{mtac} shows how to add a typed language for proof
automation on top of Ltac. Furthermore, Ltac itself is not designed to
be a general purpose programming language. It can be difficult to
abstract over certain patterns and debugging
proof automation is not easy. The programmable proof automation,
written using reflection, presented here may not be as mature as Coq's
Ltac language, but addresses these issues.

More recently, \cite{malecha} have designed a higher-order reflective
programming language (MirrorCore) and an associated tactic language
(Rtac). MirrorCore defines a unification algorithm -- similar to the
one we have implemented in this paper. Alternative implementations
of several familiar Coq tactics, such as |eauto| and |setoid_rewrite|,
have been developed using Rtac. The authors have identified several
similar advantages of `programming' tactics, rather than using
built-in primitives, that we mention in this paper, such as
manipulating and assembling first-class hint databases.

\paragraph{Idris}
The dependently typed programming language Idris also has a collection
of tactics, inspired by some of the more simple Coq tactics, such as
|rewrite|, |intros|, or |exact|. Each of these tactics is built-in and
implemented as part of the Idris system. There is a small Haskell
library for tactic writers to use that exposes common commands, such
as unification, evaluation, or type checking. Furthermore, there are
library functions to help handle the construction of proof terms,
generation of fresh names, and splitting sub-goals. This approach is
reminiscent of the HOL family of theorem provers~\citep{hol} or Coq's
plug-in mechanism. An important drawback is that tactic writers need
to write their tactics in a different language to the rest of their
Idris code; furthermore, any changes to tactics requires a
recompilation of the entire Idris system.

\paragraph{Agsy}
Agda already has a built-in `auto' tactic that outperforms the |auto|
function we have defined here~\citep{lindblad}. It is nicely integrated
with the IDE and does not require the users to provide an explicit
hint database. It is, however, implemented in Haskell and shipped as
part of the Agda system. As a result, users have very few
opportunities for customization: there is limited control over which
hints may (or may not) be used; there is no way to assign priorities
to certain hints; and there is a single fixed search strategy. In
contrast to the proof search presented here, where we have much more
fine grained control over all these issues.

\subsection*{Conclusion}

The proof automation presented in this paper is not as mature as some
of these alternative systems. Yet we strongly believe that this style
of proof automation is worth pursuing further.

The advantages of using reflection to program proof tactics should be
clear: we do not need to learn a new programming language to write new
tactics; we can use existing language technology to debug and test our
tactics; and we can use all of Agda's expressive power in the design
and implementation of our tactics. If a particular problem domain
requires a different search strategy, this can be implemented by
writing a new traversal over a |SearchTree|. Hint databases are
first-class values. There is never any built-in magic; there are no
compiler primitives beyond Agda's reflection mechanism.

The central philosophy of Martin-L\"of type theory is that the
construction of programs and proofs is the same activity. Any
external language for proof automation renounces this philosophy. This
paper demonstrates that proof automation is not inherently at odds
with the philosophy of type theory. Paraphrasing
Martin-L\"of~\citeyearpar{martin-lof}, it no longer seems possible to
distinguish the discipline of \emph{programming} from the
\emph{construction} of mathematics.

% \pepijn{The |auto| tactic currently works under the latest release of
%   Agda; however, the changes to |tactic| have not yet been
%   released. Therefore, I feel |auto| will probably break soon (for a
%   while, at least).}
% Wouter: we need to prepare the best paper we can NOW. We can always update
% the library quite easily when the new version of Agda is released.


%%% Local Variables:
%%% mode: latex
%%% TeX-master: t
%%% TeX-command-default: "rake"
%%% End:
