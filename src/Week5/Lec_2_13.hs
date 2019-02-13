{-@ LIQUID "--reflection"  @-}
{-@ LIQUID "--diff"        @-}
{-@ LIQUID "--ple"         @-}
{-@ LIQUID "--short-names" @-}

{-@ infixr ++  @-}  -- TODO: Silly to have to rewrite this annotation!

{-# LANGUAGE GADTs #-}

module Lec_2_13 where

import           Prelude hiding ((++)) 
import           ProofCombinators
import qualified State as S
import           Expressions hiding (And)

--------------------------------------------------------------------------------
-- | IMP Commands
--------------------------------------------------------------------------------

{- 
  
    BStep c s1 s2 



  ------------------[BSkip]
    BStep Skip s s


  ------------------------------------------[BAssign]
    BStep (x := a) s (set s x (aval a s))


    BStep c1 s smid    BStep c2 smid s'
  ----------------------------------------[BSeq]
    BStep (c1; c2) s s' 


    bval b s = TRUE      BStep c1 s s'
  ----------------------------------------[BIfT]
    BStep (If b c1 c2) s s' 


    bval b s = FALSE     BStep c2 s s'
  ----------------------------------------[BIfF]
    BStep (If b c1 c2) s s' 


    bval b s = TRUE      BStep (c ; While b c) s s'   
  --------------------------------------------------[BWhileT]
    BStep (While b c) s s' 

    bval b s = FALSE      
  ----------------------------------------[BWhileF]
    BStep (While b c) s s




 -}

data Com 
  = Skip                      -- skip 
  | Assign Vname AExp         -- x := a
  | Seq    Com   Com          -- c1; c2
  | If     BExp  Com   Com    -- if b then c1 else c2
  | While  BExp  Com          -- while b c 
  deriving (Show)


{-@ reflect <~ @-}
x <~ a = Assign x a 

{-@ reflect @@ @-}
s1 @@ s2 = Seq s1 s2

-- x = y + 1; y = 2

ex_7_1 :: Com 
ex_7_1 = ("x" <~ Plus (V "y") (N 1))  @@ 
         ("y" <~ N 2)                 @@ 
         Skip 

--------------------------------------------------------------------------------
-- | Big-step Semantics 
--------------------------------------------------------------------------------

data BStepP where
  BStep :: Com -> State -> State -> BStepP 

data BStep where 
  BSkip   :: State -> BStep 
  BAssign :: Vname -> AExp -> State -> BStep 
  BSeq    :: Com   -> Com  -> State -> State -> State -> BStep -> BStep -> BStep 
  BIfT    :: BExp  -> Com  -> Com   -> State -> State -> BStep -> BStep  
  BIfF    :: BExp  -> Com  -> Com   -> State -> State -> BStep -> BStep
  BWhileF :: BExp  -> Com  -> State -> BStep 
  BWhileT :: BExp  -> Com  -> State -> State -> State -> BStep -> BStep -> BStep 

{-@ data BStep where 
      BSkip   :: s:State 
              -> Prop (BStep Skip s s)
    | BAssign :: x:Vname -> a:AExp -> s:State 
              -> Prop (BStep (Assign x a) s (asgn x a s)) 
    | BSeq    :: c1:Com -> c2:Com -> s1:State -> s2:State -> s3:State 
              -> Prop (BStep c1 s1 s2) 
              -> Prop (BStep c2 s2 s3) 
              -> Prop (BStep (Seq c1 c2) s1 s3)
    | BIfT    :: b:BExp -> c1:Com -> c2:Com -> s:{State | bval b s} -> s1:State
              -> Prop (BStep c1 s s1) -> Prop (BStep (If b c1 c2) s s1)
    | BIfF    :: b:BExp -> c1:Com -> c2:Com -> s:{State | not (bval b s)} -> s2:State
              -> Prop (BStep c2 s s2) -> Prop (BStep (If b c1 c2) s s2)
    | BWhileF :: b:BExp -> c:Com -> s:{State | not (bval b s)} 
              -> Prop (BStep (While b c) s s)
    | BWhileT :: b:BExp -> c:Com -> s1:{State | bval b s1} -> s1':State -> s2:State
              -> Prop (BStep c s1 s1') 
              -> Prop (BStep (While b c) s1' s2)
              -> Prop (BStep (While b c) s1 s2)
  @-}  


--------------------------------------------------------------------------------

{-@ reflect cmd_1 @-}
cmd_1 = "x" <~ N 5

{-@ reflect cmd_2 @-}
cmd_2 = "y" <~ (V "x")

{-@ reflect cmd_1_2 @-}
cmd_1_2 = cmd_1 @@ cmd_2 

{-@ reflect prop_set @-}
prop_set cmd x v s = BStep cmd s (S.set s x v)

{-@ step_1 :: s:State -> Prop (prop_set cmd_1 {"x"} 5 s)  @-}
step_1 s =  BAssign "x" (N 5) s

{-@ step_2 :: s:{State | S.get s "x" == 5} -> Prop (prop_set cmd_2 {"y"} 5 s) @-}
step_2 s = BAssign "y" (V "x") s

{-@ step_1_2 :: s:State -> Prop (BStep cmd_1_2 s (S.set (S.set s {"x"} 5) {"y"} 5)) @-}
step_1_2 s = BSeq cmd_1 cmd_2 s s1 s2 (step_1 s) (step_2 s1) 
  where 
    s1     = S.set s  "x" 5 
    s2     = S.set s1 "y" 5
