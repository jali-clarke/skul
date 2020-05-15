module TestSkully.Internal.TypeRep (
    testSkullyTypeRep
) where

import Test.Hspec

import Skully.Internal.TypeRep

testUnify :: Spec
testUnify =
    describe "unify :: TypeRep a -> TypeRep b -> Either String (TypeRep a)" $ do
        it "should unify Char against Char" $ unify Char Char `shouldBe` Right Char
        it "should not unify (Char :->: Char) against Char" $
            unify (Char :->: Char) Char `shouldBe` Left "cannot unify (Char :->: Char) against Char"

testSkullyTypeRep :: Spec
testSkullyTypeRep =
    describe "Skully.Internal.TypeRep" $ do
        testUnify
