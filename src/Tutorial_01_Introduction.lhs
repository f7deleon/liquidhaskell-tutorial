Introduction {#intro}
============

\begin{comment}
\begin{code}
{-# LANGUAGE CPP #-}

module Tutorial_01_Introduction where
main = putStrLn "Intro"

-- {-@ ignore average @-}

\end{code}
\end{comment}

One of the great things about Haskell is its brainy type system that
allows one to enforce a variety of invariants at compile time, thereby
nipping in the bud a large swathe of run-time [errors](#getting-started).

Well-Typed Programs Do Go Wrong {#gowrong}
------------------------------------------

Alas, well-typed programs *do* go quite wrong, in a variety of ways.

\newthought{Division by Zero} This innocuous function computes the average
of a list of integers:

\begin{code}
average    :: [Int] -> Int
average xs = sum xs `div` length xs
\end{code}

We get the desired result on a non-empty list of numbers:

~~~~~{.ghci}
ghci> average [10, 20, 30, 40]
25
~~~~~

However, if we call it with an empty list, we get a rather unpleasant crash:
^[We could write `average` more *defensively*, returning
a `Maybe` or `Either` value. However, this merely kicks
the can down the road. Ultimately, we will want to extract
the `Int` from the `Maybe` and if the inputs were invalid
to start with, then at that point we'd be stuck.]

~~~~~{.ghci}
ghci> average []
*** Exception: divide by zero
~~~~~

\newthought{Missing Keys}
Associative key-value maps are the new lists; they come "built-in"
with modern languages like Go, Python, JavaScript and Lua; and of
course, they're widely used in Haskell too.

~~~~~{.ghci}
ghci> :m +Data.Map 
ghci> let m = fromList [ ("haskell", "lazy")
                       , ("ocaml"  , "eager")]

ghci> m ! "haskell"
"lazy"
~~~~~

Alas, maps are another source of vexing errors that are tickled
when we try to find the value of an absent key: ^[Again, one could
use a `Maybe` but it's just deferring the inevitable.]

~~~~~{.ghci}
ghci> m ! "javascript"
"*** Exception: key is not in the map
~~~~~


\newthought{Segmentation Faults}
Say what? How can one possibly get a segmentation fault with a *safe*
language like Haskell. Well, here's the thing: every safe language is
built on a foundation of machine code, or at the very least, `C`.
Consider the ubiquitous `vector` library:

~~~~~{.ghci}
ghci> :m +Data.Vector 
ghci> let v = fromList ["haskell", "ocaml"]
ghci> unsafeIndex v 0
"haskell"
~~~~~

However, invalid inputs at the safe upper
levels can percolate all the way down and
stir a mutiny down below:
^[Why use a function marked `unsafe`?
Because it's very fast! Furthermore, even if we used
the safe variant, we'd get a *run-time* exception
which is only marginally better. Finally, we should remember
to thank the developers for carefully marking it unsafe,
because in general, given the many layers of abstraction,
it is hard to know which functions are indeed safe.]


~~~~~{.ghci}
ghci> unsafeIndex v 3
'ghci' terminated by signal SIGSEGV ...
~~~~~


\newthought{Heart Bleeds}
Finally, for certain kinds of programs, there is a fate worse than death.
`text` is a high-performance string processing library for Haskell, that
is used, for example, to build web services.

~~~~~{.ghci}
ghci> :m +Data.Text Data.Text.Unsafe 
ghci> let t = pack "Voltage"
ghci> takeWord16 5 t
"Volta"
~~~~~

A cunning adversary can use invalid, or rather,
*well-crafted*, inputs that go well outside the size of
the given `text` to read extra bytes and thus *extract secrets*
without anyone being any the wiser.

~~~~~{.ghci}
ghci> takeWord16 20 t
"Voltage\1912\3148\SOH\NUL\15928\2486\SOH\NUL"
~~~~~

The above call returns the bytes residing in memory
*immediately after* the string `Voltage`. These bytes
could be junk, or could be either the name of your
favorite TV show, or, more worryingly, your bank
account password.

Refinement Types
----------------

Refinement types allow us to enrich Haskell's type system with
*predicates* that precisely describe the sets of *valid* inputs
and outputs of functions, values held inside containers, and
so on. These predicates are drawn from special *logics* for which
there are fast *decision procedures* called SMT solvers.

\newthought{By combining types with predicates} you can specify *contracts*
which describe valid inputs and outputs of functions. The refinement
type system *guarantees at compile-time* that functions adhere to
their contracts. That is, you can rest assured that 
the above calamities *cannot occur at run-time*.

\newthought{LiquidHaskell} is a Refinement Type Checker for Haskell, and in
this tutorial we'll describe how you can use it to make programs
better and programming even more fun. ^[If you are familiar with
the notion of Dependent Types, for example, as in the Coq proof
assistant, then Refinement Types can be thought of as restricted
class of the former where the logic is restricted, at the cost of
expressiveness, but with the reward of a considerable amount of
automation.]


Audience
--------

Do you

* know a bit of basic arithmetic and logic?
* know the difference between a `nand` and an `xor`?
* know any typed languages e.g. ML, Haskell, Scala, F# or (Typed) Racket?
* know what `forall a. a -> a` means?
* like it when your code editor politely points out infinite loops?
* like your programs to not have bugs?

Then this tutorial is for you!

Getting Started
---------------

As of July 2020, LiquidHaskell, version 0.8.10 onwards, is available
as a [GHC plugin](https://downloads.haskell.org/~ghc/8.10.1/docs/html/users_guide/extending_ghc.html).

This means, roughly, that you need simply 

1. Add LH to your project dependencies, after which 
2. GHC produces LH type errors whenever you compile the code, so that you can
3. View errors using your favorite editor's existing Haskell tooling.

\newthought{LiquidHaskell Requires} (in addition to the cabal
dependencies) a binary for an `SMTLIB2` compatible
solver, e.g. one of

+ [Z3][z3] (which we recommend)
+ [CVC4][cvc4]
+ [MathSat][mathsat]
   
\newthought{This Tutorial} is written in literate Haskell and
the code for it is available [here][liquid-tutorial].
Hence, we *strongly* recommend you grab the code, and follow
along, and especially that you do the exercises, via two steps.

**Step 1** Clone the code repository,

~~~~~{.sh}
git clone --recursive https://github.com/ucsd-progsys/liquidhaskell-tutorial.git
~~~~~

**Step 2:** Try building the code using

~~~~~{.sh}
cabal v2-build
~~~~~

or 

~~~~~{.sh}
stack build --fast --file-watch
~~~~~

If your environment is set up correctly,
compilation will stop with a Liquid type error:

~~~~~{.spec}
src/Tutorial_01_Introduction.lhs:30:27: error:
    Liquid Type Mismatch              
    .                                 
    The inferred type                 
      VV : {v : GHC.Types.Int | v >= 0
                                && v == len xs}
    .                                 
    is not a subtype of the required type
      VV : {VV : GHC.Types.Int | VV /= 0}
    .                                 
    in the context                    
      xs : {v : [GHC.Types.Int] | len v >= 0}
   |                                  
30 | average xs = sum xs `div` length xs
   |                           ^^^^^^^^^
~~~~~

**Step 3:** Iteratively edit-compile until the code in `src/`

until it _builds_ without any liquid type errors.

The above workflow will let you use whatever GHC/Haskell tooling you use for your 
favorite editor, to automatically display LH errors as well.

Sample Code
-----------

This tutorial is written in literate Haskell and
the code for it is available [here][liquid-tutorial].

We *strongly* recommend you grab the code, and follow
along, and especially that you do the exercises.

If you'd like to copy and paste code snippets into the 
web demo, instead of cloning the repo, note that you may
need to pass `--no-termination` to `liquid`, or equivalently,
add the pragma `{-@ LIQUID "--no-termination" @-}` to the top 
of the source file. (By default, `liquid` tries to ensure that 
all code it examines will terminate. Some of the code in this 
tutorial is written in such a way that termination is not 
immediately obvious to LH.) 

**Note:** This tutorial is a *work in progress*, and we will 
be **very** grateful for feedback and suggestions, ideally 
via pull-requests on github.

\noindent Lets begin!


