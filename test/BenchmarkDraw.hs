module Main where

import Brick (renderFinal, resetRenderState)
import Criterion.Main
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BSL
import Graphics.Vty (Image, picImage)
import Lens.Micro.Platform
import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure)

import Draw
import Types

usage :: IO a
usage = do
    n <- getProgName
    putStrLn $ "Usage: " <> n <> " <state file>"
    exitFailure

doDraw :: SerializedState -> Image
doDraw ss =
    let cs = serializedChatState ss
        rs = resetRenderState $ serializedRenderState ss
        (_, pic, _, _) = renderFinal (cs^.csResources.crTheme) (draw cs) (serializedWindowSize ss) (const Nothing) rs
    in picImage pic

main :: IO ()
main = do
    args <- getArgs

    stateFilePath <- case args of
        (p:_) -> return p
        _ -> usage

    stateBytes <- BSL.readFile stateFilePath
    loadedState <- case A.eitherDecode stateBytes :: Either String SerializedState of
        Left e -> do
            putStrLn $ "Error decoding state file: " <> e
            exitFailure
        Right s -> return s

    let cases = [ bench "draw" $ nf doDraw loadedState
                ]

    defaultMain cases
