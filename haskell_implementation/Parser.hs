import Control.Applicative ((<$>))
import Text.ParserCombinators.Parsec
import Text.ParserCombinators.Parsec.Char


type JuxType = String


data JuxToken = JuxInt Int JuxType | JuxIdentifier String JuxType | JuxQuotation [JuxToken] JuxType
  deriving (Show, Eq, Ord)

--parse :: String -> [JuxToken]

integer :: Parser Int
integer = read <$> many1 digit


parseScore :: Parser JuxToken
parseScore = do
  a <- integer
  char ':'
  b <- integer
  return $ JuxQuotation [JuxInt a "Integer", JuxInt b "Integer"] "Score"

runParsec :: String -> Maybe JuxToken
runParsec input = case parse parseScore "" input of
  Left e -> Nothing
  Right e ->  Just e
