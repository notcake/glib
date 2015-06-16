GLib: OOP and Utility Library for Garry's Mod
=============================================

The following is an incomplete function listing:

OOP
---------------------------------------------
```
(... -> Object) GLib.MakeConstructor (classTable[, baseClassConstructor])
string Object:GetHashCode ()
```

Color
---------------------------------------------
```
Color  GLib.Color.Clone (Color color[, Color clone])
Color  GLib.Color.FromColor (Color color[, Color out])
Color  GLib.Color.FromColor (Color color, float alpha[, Color out])
Color  GLib.Color.FromName (string colorName)
Color  GLib.Color.FromArgb (uint32 argb[, Color out])
Color  GLib.Color.FromHtmlColor (string htmlColor[, Color out])
Color  GLib.Color.FromHtmlColor (string htmlColor, float alpha[, Color out])
Color  GLib.Color.FromRgb (uint32 rbg[, Color out])
Color  GLib.Color.FromRgb (uint32 rbg, float alpha[, Color out])
Color  GLib.Color.FromVector (Vector v[, Color out])
Color  GLib.Color.FromVector (Vector v, float alpha[, Color out])
string GLib.Color.GetName (Color color)
Color  GLib.Color.Lerp (float t, Color color0, Color color1[, Color out])
uint32 GLib.Color.ToArgb (Color color)
string GLib.Color.ToHtmlColor (Color color)
uint32 GLib.Color.ToRgb (Color color)
Vector GLib.Color.ToVector (Color color[, Vector out])
```

IO
---------------------------------------------
```
interface GLib.InBuffer
interface GLib.OutBuffer
class     GLib.StringInBuffer
class     GLib.StringOutBuffer

StringInBuffer  GLib.StringInBuffer (string data)
StringOutBuffer GLib.StringOutBuffer ()

uint     InBuffer:GetBytesRemaining ()
uint     InBuffer:GetPosition ()
uint     InBuffer:GetSize ()
bool     InBuffer:IsEndOfStream ()
InBuffer InBuffer:Pin ()
void     InBuffer:SeekRelative (int relativeSeekPos)
void     InBuffer:SeekAbsolute (uint seekPos)

uint8    InBuffer:UInt8 ()
uint16   InBuffer:UInt16 ()
uint32   InBuffer:UInt32 ()
uint64   InBuffer:UInt64 ()
uint     InBuffer:ULEB128 ()
int8     InBuffer:Int8 ()
int16    InBuffer:Int16 ()
int32    InBuffer:Int32 ()
int64    InBuffer:Int64 ()
float    InBuffer:Float ()
double   InBuffer:Double ()
Vector   InBuffer:Vector ()
string   InBuffer:Char ()
string   InBuffer:Bytes (uint length)
string   InBuffer:String ()
string   InBuffer:StringN8 ()
string   InBuffer:StringN16 ()
string   InBuffer:StringN32 ()
string   InBuffer:StringZ ()
string   InBuffer:LongString ()
bool     InBuffer:Boolean ()

void     OutBuffer:Clear ()
uint     OutBuffer:GetSize ()
string   OutBuffer:GetString ()
void     OutBuffer:UInt8 (uint8 n)
void     OutBuffer:UInt16 (uint16 n)
void     OutBuffer:UInt32 (uint32 n)
void     OutBuffer:UInt64 (uint64 n)
void     OutBuffer:ULEB128 (uint n)
void     OutBuffer:Int8 (int8 n)
void     OutBuffer:Int16 (int16 n)
void     OutBuffer:Int32 (int32 n)
void     OutBuffer:Int64 (int64 n)
void     OutBuffer:Float (float f)
void     OutBuffer:Double (double f)
void     OutBuffer:Vector (Vector v)
void     OutBuffer:Char (string char)
void     OutBuffer:Bytes (string data[, uint length])
void     OutBuffer:String (string data)
void     OutBuffer:StringN8 (string data)
void     OutBuffer:StringN16 (string data)
void     OutBuffer:StringN32 (string data)
void     OutBuffer:StringZ (string data)
void     OutBuffer:Boolean (bool b)
```


String
---------------------------------------------
```
string         GLib.String.DumpHex (string str)
string[]       GLib.String.GetLines (string str)
(() -> string) GLib.String.LineIterator (string str)
string[]       GLib.String.Split (string str, string separator)
(() -> string) GLib.String.SplitIterator (string str, string separator)
string[]       GLib.String.ToCharArray ()

string         GLib.String.ConsoleEscape (string str)
string         GLib.String.Escape (string str)
string         GLib.String.EscapeNonprintable (string str)
string         GLib.String.EscapeWhitespace (string str)
string         GLib.String.Unescape (string str)
```

Unicode
---------------------------------------------
```
enum GLib.UnicodeCategory
enum GLib.WordType

bool            GLib.Unicode.CharacterHasDecomposition (string char)
bool            GLib.Unicode.CharacterHasTransliteration (string char)
bool            GLib.Unicode.CodePointHasDecomposition (uint32 codePoint)
bool            GLib.Unicode.CodePointHasTransliteration (uint32 codePoint)
string          GLib.Unicode.DecomposeCharacter (string char)
string          GLib.Unicode.DecomposeCodePoint (codePoint)
UnicodeCategory GLib.Unicode.GetCharacterCategory (string char)
string          GLib.Unicode.GetCharacterName (string char)
table (uint32 codePoint -> string codePointName) GLib.Unicode.GetCharacterNameTable ()
UnicodeCategory GLib.Unicode.GetCodePointCategory (uint32 codePoint)
string          GLib.Unicode.GetCodePointName (uint32 codePoint)
table           GLib.Unicode.GetDecompositionMap ()
table           GLib.Unicode.GetTransliterationTable ()
bool            GLib.Unicode.IsCharacterNamed (string char)
bool            GLib.Unicode.IsCodePointNamed (uint32 codePoint)
bool            GLib.Unicode.IsCombiningCategory (UnicodeCategory unicodeCategory)
bool            GLib.Unicode.IsCombiningCharacter (string char)
bool            GLib.Unicode.IsCombiningCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsControl (string char)
bool            GLib.Unicode.IsControlCategory (UnicodeCategory unicodeCategory)
bool            GLib.Unicode.IsControlCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsDigit (string char)
bool            GLib.Unicode.IsDigitCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsLetter (string char)
bool            GLib.Unicode.IsLetterCategory (UnicodeCategory unicodeCategory)
bool            GLib.Unicode.IsLetterCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsLetterOrDigit (string char)
bool            GLib.Unicode.IsLetterOrDigitCategory (UnicodeCategory unicodeCategory)
bool            GLib.Unicode.IsLetterOrDigitCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsLower (string char)
bool            GLib.Unicode.IsLowerCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsNumber (string char)
bool            GLib.Unicode.IsNumberCategory (UnicodeCategory unicodeCategory)
bool            GLib.Unicode.IsNumberCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsPunctuation (string char)
bool            GLib.Unicode.IsPunctuationCategory (UnicodeCategory unicodeCategory)
bool            GLib.Unicode.IsSeparator (string char)
bool            GLib.Unicode.IsSeparatorCategory (UnicodeCategory unicodeCategory)
bool            GLib.Unicode.IsSeparatorCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsSymbol (string char)
bool            GLib.Unicode.IsSymbolCategory (UnicodeCategory unicodeCategory)
bool            GLib.Unicode.IsSymbolCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsUpper (string char)
bool            GLib.Unicode.IsUpperCodePoint (uint32 codePoint)
bool            GLib.Unicode.IsWhitespace (string char)
bool            GLib.Unicode.IsWhitespaceCategory (UnicodeCategory unicodeCategory)
string          GLib.Unicode.ToLower (string char)
string          GLib.Unicode.ToLowerCodePoint (uint32 codePoint)
string          GLib.Unicode.ToTitle (string char)
string          GLib.Unicode.ToTitleCodePoint (uint32 codePoint)
string          GLib.Unicode.ToUpper (string char)
string          GLib.Unicode.ToUpperCodePoint (uint32 codePoint)
```

UTF-8
---------------------------------------------
```
uint32           GLib.UTF8.Byte (string char, uint offset = 1)
string           GLib.UTF8.Char (uint32 codePoint)
uint             GLib.UTF8.CharacterToOffset (string str, uint character)
string[]         GLib.UTF8.ChunkSplit (string str, uint chunkSize)
bool             GLib.UTF8.ContainsSequences (string str, uint offset = 1)
string           GLib.UTF8.Decompose (string str)
uint             GLib.UTF8.GetGraphemeStart (string str, uint offset)
uint             GLib.UTF8.GetSequenceStart (string str, uint offset)
(() -> string char, uint offset) GLib.UTF8.GraphemeIterator (string str, uint offset = 1)
(() -> string char, uint offset) GLib.UTF8.Iterator (string str, uint offset = 1)
uint             GLib.UTF8.Length (string str)
bool             GLib.UTF8.MatchTransliteration (string str, string substring, uint strOffset = 1)
string, uint     GLib.UTF8.NextChar (string str, uint offset = 1)
uint, WordType leftWordType, WordType rightWordType GLib.UTF8.NextWordBoundary (string str, uint offset = 1)
string, uint     GLib.UTF8.PreviousChar (string str, uint offset = 1)
uint, WordType leftWordType, WordType rightWordType GLib.UTF8.PreviousWordBoundary (string str, uint offset = 1)
(() -> string char, uint offset) GLib.UTF8.ReverseGraphemeIterator (string str, uint offset = 1)
(() -> string char, uint offset) GLib.UTF8.ReverseIterator (string str, uint offset = 1)
uint             GLib.UTF8.SequenceLength (string str, uint offset = 1)
string, string   GLib.UTF8.SplitAt (string str, uint char)
string           GLib.UTF8.StripCombiningCharacters (string str)
string           GLib.UTF8.Sub (string str, uint startCharacter, uint endCharacter)
string           GLib.UTF8.SubOffset (sstring str, uint offset, uint startCharacter, uint endCharacter)
string           GLib.UTF8.FromLatin1 (string str)
string           GLib.UTF8.ToLatin1 (string str)
string           GLib.UTF8.ToLower (str)
string           GLib.UTF8.ToUpper (str)
string           GLib.UTF8.TransformString (string str, (string char -> string) f)
string           GLib.UTF8.TransformUnicodeString (string str, (string char -> string) f)
string           GLib.UTF8.Transliterate (str)
string, WordType GLib.UTF8.WordIterator (string str, uint offset = 1)
```