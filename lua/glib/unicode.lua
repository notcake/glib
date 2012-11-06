GLib.Unicode = {}
GLib.Unicode.Characters = {}
GLib.Unicode.CharacterNames = {}

function GLib.Unicode.GetCharacterCategory (...)
	local codePoint = GLib.UTF8.Byte (...)
	return GLib.Unicode.GetCodePointCategory (codePoint)
end

function GLib.Unicode.GetCharacterName (...)
	local codePoint = GLib.UTF8.Byte (...)
	if GLib.Unicode.CharacterNames [codePoint] then
		return GLib.Unicode.CharacterNames [codePoint]
	end
	if codePoint < 0x010000 then
		return string.format ("CHARACTER 0x%04x", codePoint)
	else
		return string.format ("CHARACTER 0x%06x", codePoint)
	end
end

function GLib.Unicode.GetCodePointCategory (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint)
end

function GLib.Unicode.GetCodePointName (codePoint)
	if GLib.Unicode.CharacterNames [codePoint] then
		return GLib.Unicode.CharacterNames [codePoint]
	end
	if codePoint < 0x010000 then
		return string.format ("CHARACTER 0x%04x", codePoint)
	else
		return string.format ("CHARACTER 0x%06x", codePoint)
	end
end

function GLib.Unicode.IsCharacterNamed (...)
	local codePoint = GLib.UTF8.Byte (...)
	return GLib.Unicode.CharacterNames [codePoint] and true or false
end

function GLib.Unicode.IsCodePointNamed (codePoint)
	return GLib.Unicode.CharacterNames [codePoint] and true or false
end

function GLib.Unicode.IsControl (...)
	return GLib.Unicode.GetCharacterCategory (...) == GLib.UnicodeCategory.Control
end

function GLib.Unicode.IsControlCodePoint (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint) == GLib.UnicodeCategory.Control
end

local combiningCategories =
{
	[GLib.UnicodeCategory.NonSpacingMark]       = true,
	[GLib.UnicodeCategory.SpacingCombiningMark] = true,
	[GLib.UnicodeCategory.EnclosingMark]        = true
}
function GLib.Unicode.IsCombiningCharacter (...)
	return combiningCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end
function GLib.Unicode.IsCombiningCodePoint (codePoint)
	return combiningCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.IsDigit (...)
	return GLib.Unicode.GetCharacterCategory (...) == GLib.UnicodeCategory.DecimalDigitNumber
end

function GLib.Unicode.IsDigitCodePoint (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint) == GLib.UnicodeCategory.DecimalDigitNumber
end

local letterCategories =
{
	[GLib.UnicodeCategory.UppercaseLetter] = true,
	[GLib.UnicodeCategory.LowercaseLetter] = true,
	[GLib.UnicodeCategory.TitlecaseLetter] = true,
	[GLib.UnicodeCategory.ModifierLetter ] = true,
	[GLib.UnicodeCategory.OtherLetter    ] = true
}
function GLib.Unicode.IsLetter (...)
	return letterCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsLetterCategory (unicodeCategory)
	return letterCategories [unicodeCategory] or false
end

function GLib.Unicode.IsLetterCodePoint (codePoint)
	return letterCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.IsLetterOrDigit (...)
	local unicodeCategory = GLib.Unicode.GetCharacterCategory (...)
	return letterCategories [unicodeCategory] or unicodeCategory == GLib.UnicodeCategory.DecimalDigitNumber or false
end

function GLib.Unicode.IsLetterOrDigitCategory (unicodeCategory)
	return letterCategories [unicodeCategory] or unicodeCategory == GLib.UnicodeCategory.DecimalDigitNumber or false
end

function GLib.Unicode.IsLetterOrDigitCodePoint (codePoint)
	local unicodeCategory = GLib.Unicode.GetCodePointCategory (codePoint)
	return letterCategories [unicodeCategory] or unicodeCategory == GLib.UnicodeCategory.DecimalDigitNumber or false
end

function GLib.Unicode.IsLower (...)
	return GLib.Unicode.GetCharacterCategory (...) == GLib.UnicodeCategory.LowercaseLetter
end

function GLib.Unicode.IsLowerCodePoint (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint) == GLib.UnicodeCategory.LowercaseLetter
end

local numberCategories =
{
	[GLib.UnicodeCategory.DecimalDigitNumber] = true,
	[GLib.UnicodeCategory.LetterNumber      ] = true,
	[GLib.UnicodeCategory.OtherNumber       ] = true
}
function GLib.Unicode.IsNumber (...)
	return numberCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsNumberCategory (unicodeCategory)
	return numberCategories [unicodeCategory] or false
end

function GLib.Unicode.IsNumberCodePoint (codePoint)
	return numberCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

local separatorCategories =
{
	[GLib.UnicodeCategory.SpaceSeparator    ] = true,
	[GLib.UnicodeCategory.LineSeparator     ] = true,
	[GLib.UnicodeCategory.ParagraphSeparator] = true
}
function GLib.Unicode.IsSeparator (...)
	return separatorCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsSeparatorCategory (unicodeCategory)
	return separatorCategories [unicodeCategory] or false
end

function GLib.Unicode.IsSeparatorCodePoint (codePoint)
	return separatorCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

local symbolCategories =
{
	[GLib.UnicodeCategory.MathSymbol    ] = true,
	[GLib.UnicodeCategory.CurrencySymbol] = true,
	[GLib.UnicodeCategory.ModifierSymbol] = true,
	[GLib.UnicodeCategory.OtherSymbol   ] = true
}
function GLib.Unicode.IsSymbol (...)
	return symbolCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsSymbolCategory (unicodeCategory)
	return symbolCategories [unicodeCategory] or false
end

function GLib.Unicode.IsSymbolCodePoint (codePoint)
	return symbolCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.IsUpper (...)
	return GLib.Unicode.GetCharacterCategory (...) == GLib.UnicodeCategory.UppercaseLetter
end

function GLib.Unicode.IsUpperCodePoint (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint) == GLib.UnicodeCategory.UppercaseLetter
end

local whitespaceCategories =
{
	[GLib.UnicodeCategory.SpaceSeparator    ] = true,
	[GLib.UnicodeCategory.LineSeparator     ] = true,
	[GLib.UnicodeCategory.ParagraphSeparator] = true
}
local whitespaceCodePoints =
{
	[0x0009] = true,
	[0x000A] = true,
	[0x000B] = true,
	[0x000C] = true,
	[0x000D] = true,
	[0x0085] = true,
	[0x00A0] = true
}
function GLib.Unicode.IsWhitespace (...)
	local codePoint = GLib.UTF8.Byte (...)
	return whitespaceCodePoints [codePoint] or whitespaceCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.IsWhitespaceCodePoint (codePoint)
	return whitespaceCodePoints [codePoint] or whitespaceCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

GLib.Unicode.DataLines = nil
GLib.Unicode.StartTime = SysTime ()

GLib.Unicode.DataLines = string.Split (string.Trim (file.Read ("glib_unicodedata.txt") or ""), "\n")
local i = 1
local lastCodePoint = 0
timer.Create ("GLib.Unicode.ParseData", 0.001, 0,
	function ()
		local startTime = SysTime ()
		while SysTime () - startTime < 0.005 do
			local bits = string.Split (GLib.Unicode.DataLines [i], ";")
			local codePoint = tonumber ("0x" .. (bits [1] or "0")) or 0
			
			lastCodePoint = codePoint
			
			GLib.Unicode.CharacterNames [codePoint] = bits [2]
			
			i = i + 1
			if i > #GLib.Unicode.DataLines then
				timer.Destroy ("GLib.Unicode.ParseData")
				GLib.Unicode.DataLines = nil
				
				GLib.Unicode.EndTime   = SysTime ()
				GLib.Unicode.DeltaTime = GLib.Unicode.EndTime - GLib.Unicode.StartTime
				
				break
			end
		end
	end
)

GLib.Unicode.Characters.LeftToRightMark          = GLib.UTF8.Char (0x200E)
GLib.Unicode.Characters.RightToLeftMark          = GLib.UTF8.Char (0x200F)
GLib.Unicode.Characters.LeftToRightEmbedding     = GLib.UTF8.Char (0x202A)
GLib.Unicode.Characters.RightToLeftEmbedding     = GLib.UTF8.Char (0x202B)
GLib.Unicode.Characters.PopDirectionalFormatting = GLib.UTF8.Char (0x202C)
GLib.Unicode.Characters.LeftToRightOverride      = GLib.UTF8.Char (0x202D)
GLib.Unicode.Characters.RightToLeftOverride      = GLib.UTF8.Char (0x202E)