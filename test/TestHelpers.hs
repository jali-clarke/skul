{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module TestHelpers (
    FakeCharSocket,
    runWithStreams,
    withStreamsShouldReturn,

    skip
) where

import Test.Hspec

import Control.Monad.State.Lazy

import Skully.Base
import Skully.Internal.CharSocket

newtype FakeCharSocket a = FakeCharSocket (StateT (String, String) Maybe a)
    deriving (Functor, Applicative, Monad)

instance CharSocket FakeCharSocket where
    getChar = FakeCharSocket $ do
        (input, output) <- get
        case input of
            [] -> lift Nothing
            c : rest -> put (rest, output) *> pure c

    putChar c = FakeCharSocket $ do
        (input, output) <- get
        put (input, output ++ [c])

runWithStreams :: (String, String) -> FakeCharSocket a -> Maybe (a, (String, String))
runWithStreams streams (FakeCharSocket action) = runStateT action streams

withStreamsShouldReturn :: (String, String) -> (String, (String, String)) -> Skully a -> Expectation
withStreamsShouldReturn initStreams expectedResult expr =
    let eval' = fmap show . eval
    in runWithStreams initStreams (eval' expr) `shouldBe` Just expectedResult

skip :: (HasCallStack, Example a) => String -> (String -> a -> SpecWith (Arg a)) -> String -> a -> SpecWith ()
skip pendingReason _ description _ = it description $ pendingWith pendingReason
