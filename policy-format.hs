import Data.Char (isAlpha, isSpace)
import Data.List (dropWhileEnd, group, isPrefixOf, sort)
import System.Environment

-- Find symbols in a string and split it into substrings.
--  - It will search for the first occurrence, but not all.
--  - It will remove delimiters from substrings (this simplifies the top-level logic).
--  - This function is not very robust, but it should be good enough, as
--  I expect the input data to be compilable files.
splitSequentially :: String -> String -> [String]
splitSequentially [] input = [input]
splitSequentially (delimiter : delimiters) input = case break (== delimiter) input of
  ([], []) -> []
  ([], _ : suffix) -> [suffix]
  (prefix, []) -> [prefix]
  (prefix, _drop : suffix) -> prefix : splitSequentially delimiters suffix

-- Remove extra spaces at ':'
fixExtraWhitespacesAtColon :: String -> String
fixExtraWhitespacesAtColon input
  | isAllowRule input = normalizeColonInner $ break (':' ==) input
  | otherwise = input
  where
    isAllowRule :: String -> Bool
    isAllowRule = ("allow" `isPrefixOf`) . dropWhile isSpace

    isSpaceOrColon :: Char -> Bool
    isSpaceOrColon x = isSpace x || x == ':'

    normalizeColonInner :: (String, String) -> String
    normalizeColonInner (left, right) = dropWhileEnd isSpaceOrColon left ++ ":" ++ dropWhile isSpaceOrColon right

-- Remove duplication and fix order for permissions in '{...}'
fixPermissions :: String -> String
fixPermissions input = case splitSequentially "{}" input of
  (prefix : permissions : others) ->
    let uniquePermissions = unwords $ makeUniqueRules $ words $ filter isValidPermissionSymbol permissions
     in prefix
          ++ "{ "
          ++ uniquePermissions
          ++ " }"
          ++ concat others
  _ -> input
  where
    isValidPermissionSymbol :: Char -> Bool
    isValidPermissionSymbol symbol = isAlpha symbol || isSpace symbol || symbol == '_'

    makeUniqueRules :: [String] -> [String]
    makeUniqueRules = map head . group . sort

-- Remove extra ';' symbols after '(...)'
fixExtraSemicolon :: String -> String
fixExtraSemicolon input = case splitSequentially "();" input of
  (prefix : info : suffix) -> prefix ++ "(" ++ info ++ ")" ++ concat suffix
  _ -> input

-- Remove extra spaces before ';'
fixExtraWhitespacesBeforeSemicolon :: String -> String
fixExtraWhitespacesBeforeSemicolon input = case break (';' ==) input of
  (prefix, []) -> input
  (prefix, suffix) -> dropWhileEnd isSpace prefix ++ suffix

-- Remove extra spaces before ';'
fixTrailingWhitespaced :: String -> String
fixTrailingWhitespaced = dropWhileEnd isSpace

-- Top-level function for calling all fixers for a line
fixLine :: String -> String
fixLine input = fixTrailingWhitespaced $ (fixExtraWhitespacesBeforeSemicolon . fixExtraWhitespacesAtColon . fixExtraSemicolon . fixPermissions) parameters ++ comment
  where
    (parameters, comment) = break ('#' ==) input

run :: FilePath -> Maybe String -> IO ()
run inputFile outputFile = do
  fixedContent <- unlines . map fixLine . lines <$> readFile inputFile
  case outputFile of
    Just outputFile -> length fixedContent `seq` writeFile outputFile fixedContent
    _ -> putStrLn fixedContent

usage = do
  putStrLn "Usage"
  putStrLn "  policy-formater <input> - read input file and print formatted version to stdout"
  putStrLn "  policy-formater <input> <output> - read input file and save formatted version to output"

main = do
  args <- getArgs
  case args of
    [] -> usage
    [inputFile] -> run inputFile Nothing
    (inputFile : outputFile : _) -> run inputFile (Just outputFile)
