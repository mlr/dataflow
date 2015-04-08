module DataFlow.DFD where

import Control.Monad.State
import Control.Monad.Writer
import DataFlow.Core

-- | Type class for types that can be rendered as DFD.
class DFD t where
  dfd :: t -> Gen ()

instance DFD Object where
  dfd (External id' name) = objectWith brackets id' $ do
    write "shape = square;"
    write "style = bold;"
    label $ bold $ write name

  dfd (TrustBoundary id' name objects) = do
    blank
    write $ "subgraph cluster_" ++ id' ++ " {"
    withIndent $ do
      mapM_ dfd objects
      blank
      write $ "label = <<b>" ++ name ++ "</b>>;"
      write "graph[style = dashed];"
    write "}"

  dfd (Process id' name) = objectWith brackets id' $ do
    write "shape = circle;"
    label $ bold $ write name

  dfd (Database id' name) = objectWith brackets id' $ do
    label $
      table "sides=\"TB\" cellborder=\"0\"" $
        tr $
          td $
            bold $ write name
    write "shape = none;"

  dfd (Edge i1 i2 operation description) = do
    step <- nextStep
    blank
    write $ i1 ++ " -> " ++ i2 ++ " ["
    withIndent $
      label $ do
        bold $ write $ "(" ++ show step ++ ") " ++ operation
        write "<br/>"
        write description
    write "]"

instance DFD Diagram where
  dfd (Diagram title objects) = do
    write $ "digraph \"" ++ title ++ "\" {"
    withIndent $ do
      useFont "graph" "sans-serif"
      useFont "node" "sans-serif"
      useFont "edge" "sans-serif"
      blank

      write "labelloc = \"t\";"
      label $ bold $ write title

      write "rankdir = LR;"

      mapM_ dfd objects

    write "}"

-- | Generates the DFD output as a String.
runDfd :: Diagram -> String
runDfd diagram = unlines $ evalState (execWriterT (dfd diagram)) (GenState 0 0)

-- | Prints the DFD output to stdout.
printDfd :: Diagram -> IO ()
printDfd = putStr . runDfd
