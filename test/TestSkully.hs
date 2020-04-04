{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module TestSkully (
    testSkully
) where

import Prelude hiding (getChar, putChar)

import Test.Hspec
import Control.Monad.State.Lazy

import CharSocket
import Skully

newtype FakeCharSocket a = FakeCharSocket (StateT (String, String) Maybe a)
    deriving (Functor, Applicative, Monad)

runWithStreams :: (String, String) -> FakeCharSocket a -> Maybe (a, (String, String))
runWithStreams streams (FakeCharSocket action) = runStateT action streams

instance CharSocket FakeCharSocket where
    getChar = FakeCharSocket $ do
        (input, output) <- get
        case input of
            [] -> lift Nothing
            c : rest -> put (rest, output) *> pure c

    putChar c = FakeCharSocket $ do
        (input, output) <- get
        put (input, output ++ [c])

testShowSkully :: Spec
testShowSkully = describe "show :: Skully a -> String" $ do
    it "prints S as \"s\"" $ show S `shouldBe` "s"
    it "prints K as \"k\"" $ show K `shouldBe` "k"
    it "prints U as \"u\"" $ show U `shouldBe` "u"
    it "prints L as \"l\"" $ show L `shouldBe` "l"
    it "prints Y as \"y\"" $ show Y `shouldBe` "y"
    it "prints Q as \"q\"" $ show Q `shouldBe` "q"
    it "prints E as \"e\"" $ show E `shouldBe` "e"
    it "prints Ap S S as \"ss\"" $ show (Ap S S) `shouldBe` "ss"
    it "prints Ap S Q as \"sq\"" $ show (Ap S Q) `shouldBe` "sq"
    it "prints Ap K Q as \"kq\"" $ show (Ap K Q) `shouldBe` "kq"
    it "prints Ap S (Ap K K) as \"s(kk)\"" $ show (Ap S (Ap K K)) `shouldBe` "s(kk)"
    it "prints Ap (Ap S K) K as \"skk\"" $ show (Ap (Ap S K) K) `shouldBe` "skk"
    it "prints Char 'x' as \"'x'\"" $ show (Char 'x') `shouldBe` "'x'"
    it "prints Char 'y' as \"'y'\"" $ show (Char 'y') `shouldBe` "'y'"

testEvalSkully :: Spec
testEvalSkully = describe "eval :: CharSocket m => Skully a -> m (Skully a)" $ do
    it "is a no-op when evaluating Char 'x'" $
        runWithStreams ("", "") (fmap show . eval $ Char 'x') `shouldBe` Just ("'x'", ("", ""))
    it "is a no-op when evaluating S" $
        runWithStreams ("", "") (fmap show . eval $ S) `shouldBe` Just ("s", ("", ""))
    it "outputs 'x' when evaluating Ap (Ap U (Char 'x')) K" $
        runWithStreams ("", "") (fmap show . eval $ Ap (Ap U (Char 'x')) K) `shouldBe` Just ("k", ("", "x"))
    it "outputs 'x' when evaluating Ap (Ap U (Char 'y')) K" $
        runWithStreams ("", "") (fmap show . eval $ Ap (Ap U (Char 'y')) K) `shouldBe` Just ("k", ("", "y"))
    it "outputs 'x' when evaluating Ap (Ap U (Char 'y')) S" $
        runWithStreams ("", "") (fmap show . eval $ Ap (Ap U (Char 'y')) S) `shouldBe` Just ("s", ("", "y"))
    it "outputs 'x' and then 'y' when evaluating Ap (Ap U (Char 'x')) (Ap (Ap U (Char 'y')) L)" $
        runWithStreams ("", "") (fmap show . eval $ Ap (Ap U (Char 'x')) (Ap (Ap U (Char 'y')) L)) `shouldBe` Just ("l", ("", "xy"))

testSkully :: Spec
testSkully = describe "operations on Skully a" $ do
    testShowSkully
    testEvalSkully