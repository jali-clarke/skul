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

runFakeCharSocket :: (String, String) -> FakeCharSocket a -> Maybe (a, (String, String))
runFakeCharSocket streams (FakeCharSocket action) = runStateT action streams

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
    it "prints Ap S S as \"s s\"" $ show (Ap S S) `shouldBe` "ss"
    it "prints Ap S Q as \"s q\"" $ show (Ap S Q) `shouldBe` "sq"
    it "prints Ap K Q as \"k q\"" $ show (Ap K Q) `shouldBe` "kq"
    it "prints Ap S (Ap K K) as \"s (k k)\"" $ show (Ap S (Ap K K)) `shouldBe` "s(kk)"
    it "prints Ap (Ap S K) K as \"s k k\"" $ show (Ap (Ap S K) K) `shouldBe` "skk"
    it "prints Char 'x' as \"x\"" $ show (Char 'x') `shouldBe` "x"
    it "prints Char '2' as \"2\"" $ show (Char '2') `shouldBe` "2"

testEvalSkully :: Spec
testEvalSkully = describe "eval :: Skully a -> a" $ do
    it "eval L g = g (getChar())" $
        let AnyCharSocket evaluated = eval L pure
        in runFakeCharSocket ("y", "") evaluated `shouldBe` Just ('y', ("", ""))
    it "eval L g = g (getChar()) different args" $
        let AnyCharSocket evaluated = eval L putChar
        in runFakeCharSocket ("x", "") evaluated `shouldBe` Just ((), ("", "x"))
                
testSkully :: Spec
testSkully = describe "operations on Skully a" $ do
    testShowSkully
    testEvalSkully