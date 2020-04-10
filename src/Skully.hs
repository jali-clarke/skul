{-# LANGUAGE GADTs #-}

module Skully (
    Skully,

    eval,

    s,
    k,
    u,
    l,
    y,
    q,
    e,
    (.$),
    char
) where

import Prelude hiding (getChar, putChar)

import Skully.CharSocket
import Skully.Type

eval :: CharSocket m => Skully a -> m (Skully a)
eval expr =
    case expr of
        Ap (Ap (Ap S abc) ab) a -> eval (Ap (Ap abc a) (Ap ab a))
        Ap (Ap K a) _ -> eval a
        Ap (Ap U c) a ->
            case c of
                Char x -> putChar x *> eval a
                _ -> do
                    c' <- eval c
                    eval (Ap (Ap U c') a)
        Ap L g -> do
            x <- getChar
            eval (Ap g (Char x))
        Ap Y g -> eval (Ap g (Ap Y g))
        Ap (Ap Q c) g ->
            case c of
                Char x ->
                    let predChar = if x == '\x00' then x else pred x
                        succChar = if x == '\xff' then x else succ x
                    in eval (Ap (Ap g (Char predChar)) (Char succChar))
                _ -> eval c >>= (\c' -> eval (Ap (Ap Q c') g))
        Ap (Ap (Ap (Ap (Ap E (Char c0)) (Char c1)) a) b) c ->
            eval $ case c0 `compare` c1 of
                LT -> a
                EQ -> b
                GT -> c
        _ -> pure expr

s :: Skully ((a -> b -> c) -> (a -> b) -> a -> c)
s = S

k :: Skully (a -> b -> a)
k = K

u :: Skully (Char -> a -> a)
u = U

l :: Skully ((Char -> a) -> a)
l = L

y :: Skully ((a -> a) -> a)
y = Y

q :: Skully (Char -> (Char -> Char -> a) -> a)
q = Q

e :: Skully (Char -> Char -> a -> a -> a -> a)
e = E

infixl 9 .$
(.$) :: Skully (a -> b) -> Skully a -> Skully b
(.$) = Ap

char :: Char -> Skully Char
char = Char