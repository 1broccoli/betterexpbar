--[[
LibAboutPanel-2.0: WoW Lua library for displaying addon metadata in Blizzard's Interface Options and AceConfig-3.0 tables.
Supports Classic Era, Classic, and Retail. This file contains the core implementation and helper functions.
--]]

local MAJOR, MINOR = "LibAboutPanel-2.0", 114 -- Library name and version; bump MINOR for each revision
assert(LibStub, MAJOR .. " requires LibStub") -- LibStub is a lightweight lib loader
local AboutPanel, oldMinor = LibStub:NewLibrary(MAJOR, MINOR)
if not AboutPanel then return end -- skip if an equal/newer version is already loaded

-- Persistent tables: preserve state across UI reloads and allow caching for performance
AboutPanel.embeds		= AboutPanel.embeds or {} -- Tracks addons this library has been embedded into
AboutPanel.aboutTable	= AboutPanel.aboutTable or {} -- Caches AceConfig options tables per addon
AboutPanel.aboutFrame	= AboutPanel.aboutFrame or {} -- Caches Blizzard Settings frames per addon

-- Localize frequently used Lua and WoW API functions for performance
local setmetatable, tostring, rawset, pairs, strmatch = setmetatable, tostring, rawset, pairs, strmatch
local GetLocale, CreateFrame = GetLocale, CreateFrame
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata -- retrieves .toc metadata like Title, Notes, Author, etc.
local format, gsub, upper, lower = string.format, string.gsub, string.upper, string.lower

-- Localization shim: returns the key itself if no translation exists.
-- This allows the library to function even if translations are missing.
local L = setmetatable({}, {
	__index = function(tab, key)
		local value = tostring(key)
		rawset(tab, key, value)
		return value
	end
})

-- Load localization tables for supported languages if available
local locale = GetLocale()
if locale == "deDE" then
	L["About"] = "Über"
L["All Rights Reserved"] = "Alle Rechte vorbehalten"
L["Author"] = "Autor"
L["Category"] = "Kategorie"
L["Click and press Ctrl-C to copy"] = "Klicken und Strg-C drücken, um zu kopieren"
L["Copyright"] = "Urheberrecht"
L["Credits"] = "Danksagungen"
L["Date"] = "Datum"
L["Developer Build"] = "Entwicklerversion"
L["Email"] = "E-Mail"
L["License"] = "Lizenz"
L["Localizations"] = "Übersetzungen"
L["on the %s realm"] = "auf dem realm %s"
L["Repository"] = "Repository"
L["Version"] = "Version"
L["Website"] = "Webseite"

elseif locale == "esES" or locale == "esMX" then
	L["About"] = "Sobre"
L["All Rights Reserved"] = "Todos los Derechos Reservados"
L["Author"] = "Autor"
L["Category"] = "Categoría"
L["Click and press Ctrl-C to copy"] = "Clic y pulse Ctrl-C para copiar."
L["Copyright"] = "Derechos de Autor"
L["Credits"] = "Créditos"
L["Date"] = "Fecha"
L["Developer Build"] = "Desarrollador Desarrollar"
L["Email"] = "Email"
L["License"] = "Licencia"
L["Localizations"] = "Idiomas"
L["on the %s realm"] = "en el reino %s"
L["Repository"] = "Repositorio"
L["Version"] = "Versión"
L["Website"] = "Sitio web"

elseif locale == "esMX" then
	L["About"] = "Sobre"
L["All Rights Reserved"] = "Todos los Derechos Reservados"
L["Author"] = "Autor"
L["Category"] = "Categoría"
L["Click and press Ctrl-C to copy"] = "Clic y pulse Ctrl-C para copiar."
L["Copyright"] = "Derechos de Autor"
L["Credits"] = "Créditos"
L["Date"] = "Fecha"
L["Developer Build"] = "Desarrollador Desarrollar"
L["Email"] = "Email"
L["License"] = "Licencia"
L["Localizations"] = "Idiomas"
L["on the %s realm"] = "en el reino %s"
L["Repository"] = "Repositorio"
L["Version"] = "Versión"
L["Website"] = "Sitio web"

elseif locale == "frFR" then
	L["About"] = "À propos"
L["All Rights Reserved"] = "Tous Droits Réservés"
L["Author"] = "Auteur"
L["Category"] = "Catégorie"
L["Click and press Ctrl-C to copy"] = "Cliquez et appuyez sur Ctrl-C pour copier"
L["Copyright"] = "Droits d'Auteur"
L["Credits"] = "Crédits"
L["Date"] = "Date"
L["Developer Build"] = "Version de développement"
L["Email"] = "E-mail"
L["License"] = "Licence"
L["Localizations"] = "Traductions"
L["on the %s realm"] = "Sur le serveur %s"
L["Repository"] = "Dépôt"
L["Version"] = "Version"
L["Website"] = "Site web"

elseif locale == "itIT" then
	L["About"] = "Licenza"
L["All Rights Reserved"] = "Tutti i Diritti Riservati"
L["Author"] = "Autore"
L["Category"] = "Category"
L["Click and press Ctrl-C to copy"] = "Fare clic e premere Ctrl-C per copiare"
L["Copyright"] = "Diritto d'Autore"
L["Credits"] = "Credits"
L["Date"] = "Data"
L["Developer Build"] = "Build dello sviluppatore"
L["Email"] = "E-mail"
L["License"] = "Licenza"
L["Localizations"] = "Localizzazioni"
L["on the %s realm"] = "nel reame %s"
L["Repository"] = "Deposito"
L["Version"] = "Versione"
L["Website"] = "Sito Web"

elseif locale == "koKR" then
	L["About"] = "대하여"
L["All Rights Reserved"] = "판권 소유"
L["Author"] = "저작자"
L["Category"] = "분류"
L["Click and press Ctrl-C to copy"] = "클릭하고 Ctrl-C를 눌러 복사"
L["Copyright"] = "저작권"
L["Credits"] = "Credits"
L["Date"] = "날짜"
L["Developer Build"] = "개발자 빌드"
L["Email"] = "전자 우편"
L["License"] = "라이센스"
L["Localizations"] = "현지화"
L["on the %s realm"] = "%s 서버에서"
L["Repository"] = "리포지토리"
L["Version"] = "버전"
L["Website"] = "웹 사이트"

elseif locale == "ptBR" then
	L["About"] = "Sobre"
L["All Rights Reserved"] = "Todos os Direitos Reservados"
L["Author"] = "Autor"
L["Category"] = "Categoria"
L["Click and press Ctrl-C to copy"] = "Clique e pressione Ctrl-C para copiar"
L["Copyright"] = "Direitos Autorais"
L["Credits"] = "Credits"
L["Date"] = "Data"
L["Developer Build"] = "Desenvolvimento do Desenvolvedor"
L["Email"] = "E-mail"
L["License"] = "Licença"
L["Localizations"] = "Localizações"
L["on the %s realm"] = "no reino %s"
L["Repository"] = "Repositório"
L["Version"] = "Versão"
L["Website"] = "Site"

elseif locale == "ruRU" then
	L["About"] = "Об аддоне"
L["All Rights Reserved"] = "Все права защищены"
L["Author"] = "Автор"
L["Category"] = "Категория"
L["Click and press Ctrl-C to copy"] = "ПКМ и нажмите Ctrl-C, чтобы скопировать"
L["Copyright"] = "Авторское право"
L["Credits"] = "Благодарности"
L["Date"] = "Дата"
L["Developer Build"] = "Разработчик сборки"
L["Email"] = "Почта"
L["License"] = "Лицензия"
L["Localizations"] = "Языки"
L["on the %s realm"] = "в игровом мире \\\"%s\\\""
L["Repository"] = "Репозиторий"
L["Version"] = "Версия"
L["Website"] = "Сайт"

elseif locale == "zhCN" then
	L["About"] = "关于"
L["All Rights Reserved"] = "保留所有权利"
L["Author"] = "作者"
L["Category"] = "分类"
L["Click and press Ctrl-C to copy"] = "点击并 Ctrl-C 复制"
L["Copyright"] = "版权"
L["Credits"] = "鸣谢"
L["Date"] = "日期"
L["Developer Build"] = "开发者构筑"
L["Email"] = "电子邮件"
L["License"] = "许可"
L["Localizations"] = "本地化"
L["on the %s realm"] = "在 %s 服务器上"
L["Repository"] = "知识库"
L["Version"] = "版本"
L["Website"] = "网站"

elseif locale == "zhTW" then
	L["About"] = "關於"
L["All Rights Reserved"] = "保留所有權利"
L["Author"] = "作者"
L["Category"] = "類別"
L["Click and press Ctrl-C to copy"] = "左鍵點擊並按下 Ctrl-C 以複製字串"
L["Copyright"] = "版權"
L["Credits"] = "貢獻者"
L["Date"] = "日期"
L["Developer Build"] = "開發版"
L["Email"] = "電子郵件"
L["License"] = "授權"
L["Localizations"] = "本地化"
L["on the %s realm"] = "在「%s」伺服器"
L["Repository"] = "程式碼存放庫"
L["Version"] = "版本"
L["Website"] = "網站"

end

-- -----------------------------------------------------
-- Helper functions to standardize metadata lookups and parsing from .toc files
-- -----------------------------------------------------

-- Converts a string to title case (e.g., "john DOE" -> "John Doe")
local function TitleCase(str)
	return str and gsub(str, "(%a)(%a+)", function(a, b) return upper(a) .. lower(b) end)
end

-- Fetches metadata from the addon .toc, using localized fields if available
local function GetMeta(addon, field, localized)
	if localized and locale ~= "enUS" then
		local v = GetAddOnMetadata(addon, field .. "-" .. locale)
		if v then return v end
	end
	return GetAddOnMetadata(addon, field)
end

local function GetTitle(addon)		return GetMeta(addon, "Title", true) end
local function GetNotes(addon)		return GetMeta(addon, "Notes", true) end
local function GetCredits(addon)	return GetAddOnMetadata(addon, "X-Credits") end
local function GetCategory(addon)	return GetAddOnMetadata(addon, "X-Category") end

-- Parses and normalizes date fields from .toc, handling repo keyword expansion
local function GetAddOnDate(addon)
	local date = GetAddOnMetadata(addon, "X-Date") or GetAddOnMetadata(addon, "X-ReleaseDate")
	if not date then return end

	date = date:gsub("%$Date: (.-) %$", "%1")
	date = date:gsub("%$LastChangedDate: (.-) %$", "%1")
	return date
end

-- Formats author field, appending guild/server/faction info if present
local function GetAuthor(addon)
	local author = GetAddOnMetadata(addon, "Author")
	if not author then return end
	author = TitleCase(author)

	local server	= GetAddOnMetadata(addon, "X-Author-Server")
	local guild		= GetAddOnMetadata(addon, "X-Author-Guild")
	local faction	= GetAddOnMetadata(addon, "X-Author-Faction")

	if server then
		author = author .. " " .. format(L["on the %s realm"], TitleCase(server)) .. "."
	end
	if guild then
		author = author .. " <" .. guild .. ">"
	end
	if faction then
		faction = TitleCase(faction)
		faction = gsub(faction, "Alliance", FACTION_ALLIANCE)
		faction = gsub(faction, "Horde", FACTION_HORDE)
		author = author .. " (" .. faction .. ")"
	end
	return author
end

-- Parses version field, handling repo keywords and developer build tags
local function GetVersion(addon)
	local version = GetAddOnMetadata(addon, "Version")
	if not version then return end

	version = gsub(version, "%.?%$Revision: (%d+) %$", " -rev.%1")
	version = gsub(version, "%.?%$Rev: (%d+) %$", " -rev.%1")
	version = gsub(version, "%.?%$LastChangedRevision: (%d+) %$", " -rev.%1")
	version = gsub(version, "r2", L["Repository"])
	version = gsub(version, "wowi:revision", L["Repository"])
	version = gsub(version, "@.+", L["Developer Build"])

	local revision = GetAddOnMetadata(addon, "X-Project-Revision")
	if revision then version = version .. " -rev." .. revision end
	return version
end

-- Normalizes and translates license/copyright fields
local function GetLicense(addon)
	local license = GetAddOnMetadata(addon, "X-License") or GetAddOnMetadata(addon, "X-Copyright")
	if not license then return end

	if not (strmatch(license, "^MIT") or strmatch(license, "^GNU")) then
		license = TitleCase(license)
	end
	license = gsub(license, "Copyright", L["Copyright"] .. " ©")
	license = gsub(license, "%([cC]%)", "©")
	license = gsub(license, "© ©", "©")
	license = gsub(license, "  ", " ")
	license = gsub(license, "[aA]ll [rR]ights [rR]eserved", L["All Rights Reserved"])
	return license
end

-- Maps locale abbreviations to Blizzard's global language constants
local localeMap = {
	["enUS"] = LFG_LIST_LANGUAGE_ENUS, ["deDE"] = LFG_LIST_LANGUAGE_DEDE,
	["esES"] = LFG_LIST_LANGUAGE_ESES, ["esMX"] = LFG_LIST_LANGUAGE_ESMX,
	["frFR"] = LFG_LIST_LANGUAGE_FRFR, ["itIT"] = LFG_LIST_LANGUAGE_ITIT,
	["koKR"] = LFG_LIST_LANGUAGE_KOKR, ["ptBR"] = LFG_LIST_LANGUAGE_PTBR,
	["ruRU"] = LFG_LIST_LANGUAGE_RURU, ["zhCN"] = LFG_LIST_LANGUAGE_ZHCN,
	["zhTW"] = LFG_LIST_LANGUAGE_ZHTW
}
local function GetLocalizations(addon)
	local translations = GetAddOnMetadata(addon, "X-Localizations")
	if translations then
		for k, v in pairs(localeMap) do
			translations = translations:gsub(k, v)
		end
	end
	return translations
end

-- Retrieves website and email fields, formatting for display/copy
local function GetWebsite(addon)
	local site = GetAddOnMetadata(addon, "X-Website")
	return site and "|cff77ccff" .. gsub(site, "https?://", "")
end

local function GetEmail(addon)
	local email = GetAddOnMetadata(addon, "X-Email") or GetAddOnMetadata(addon, "Email") or GetAddOnMetadata(addon, "eMail")
	return email and "|cff77ccff" .. email
end

-- -----------------------------------------------------
-- Shared editbox UI for copying fields (email, website) in About panel
-- -----------------------------------------------------
local editbox = CreateFrame("EditBox", nil, nil, "InputBoxTemplate") -- WoW API: creates an input box UI element
editbox:Hide()
editbox:SetFontObject("GameFontHighlightSmall")
editbox:SetScript("OnEscapePressed", editbox.Hide)
editbox:SetScript("OnEnterPressed", editbox.Hide)
editbox:SetScript("OnEditFocusLost", editbox.Hide)
editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
editbox:SetScript("OnTextChanged", function(self)
	self:SetText(self:GetParent().value) -- always reset to original
	self:HighlightText() -- auto-select text for copy
end)
AboutPanel.editbox = editbox

local function OpenEditbox(self)
	editbox:SetParent(self)
	editbox:SetAllPoints(self)
	editbox:SetText(self.value)
	editbox:Show()
end

local function ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(L["Click and press Ctrl-C to copy"])
end
local function HideTooltip() GameTooltip:Hide() end

-- -----------------------------------------------------
-- Creates the About panel in Blizzard's Interface Options (Settings UI)
-- -----------------------------------------------------
function AboutPanel:CreateAboutPanel(addon, parent)
	addon = addon:gsub(" ", "") -- some APIs don't like spaces in addon name
	addon = parent or addon

	local frame = AboutPanel.aboutFrame[addon]
	if frame then return frame end -- reuse cached

	frame = CreateFrame("Frame", addon.."AboutPanel", UIParent) -- UIParent makes this a global frame
	local title_str = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title_str:SetPoint("TOPLEFT", 16, -16)
	title_str:SetText((parent and GetTitle(addon) or addon) .. " - " .. L["About"])

	-- Add notes paragraph if present
	local notes = GetNotes(addon)
	local notes_str
	if notes then
		notes_str = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		notes_str:SetHeight(32)
		notes_str:SetPoint("TOPLEFT", title_str, "BOTTOMLEFT", 0, -8)
		notes_str:SetPoint("RIGHT", frame, -32, 0)
		notes_str:SetNonSpaceWrap(true)
		notes_str:SetJustifyH("LEFT")
		notes_str:SetText(notes)
	end

	-- Dynamically stack info fields
	local i = 0
	local prev_label = nil
	local function SetAboutInfo(field, text, editable)
		if not text then return end
		i = i + 1
		local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", (i == 1 and (notes and notes_str or title_str) or prev_label), "BOTTOMLEFT", i == 1 and -2 or 0, -10)
		label:SetWidth(80)
		label:SetJustifyH("RIGHT")
		label:SetText(field)
		prev_label = label

		local detail = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		detail:SetPoint("TOPLEFT", label, "TOPRIGHT", 4, 0)
		detail:SetPoint("RIGHT", frame, -16, 0)
		detail:SetJustifyH("LEFT")
		detail:SetText(text)

		if editable then
			local button = CreateFrame("Button", nil, frame)
			button:SetAllPoints(detail)
			button.value = text
			button:SetScript("OnClick", OpenEditbox)
			button:SetScript("OnEnter", ShowTooltip)
			button:SetScript("OnLeave", HideTooltip)
		end
	end

	-- Add fields (conditionally if metadata exists)
	SetAboutInfo(L["Version"],			GetVersion(addon))
	SetAboutInfo(L["Author"],			GetAuthor(addon))
	SetAboutInfo(L["Email"],			GetEmail(addon), true)
	SetAboutInfo(L["Date"],				GetAddOnDate(addon))
	SetAboutInfo(L["Category"],			GetCategory(addon))
	SetAboutInfo(L["License"],			GetLicense(addon))
	SetAboutInfo(L["Credits"],			GetCredits(addon))
	SetAboutInfo(L["Website"],			GetWebsite(addon), true)
	SetAboutInfo(L["Localizations"],	GetLocalizations(addon))

	-- Register with Blizzard's modern Settings system (Dragonflight+)
	frame.name = not parent and addon or L["About"]
	frame.parent = parent
	Settings.RegisterCanvasLayoutCategory(frame)

	AboutPanel.aboutFrame[addon] = frame
	return frame
end

-- -----------------------------------------------------
-- Creates an AceConfig-3.0 options table for About info (alternative UI)
-- -----------------------------------------------------
function AboutPanel:AboutOptionsTable(addon)
	assert(LibStub("AceConfig-3.0"), "LibAboutPanel-2.0: API 'AboutOptionsTable' requires AceConfig-3.0", 2)
	addon = addon:gsub(" ", "")

	local Table = AboutPanel.aboutTable[addon]
	if Table then return Table end

	Table = {
		name = L["About"],
		type = "group",
		args = {
			title = {
				order = 1,
				name = "|cffe6cc80" .. (GetTitle(addon) or addon) .. "|r",
				type = "description",
				fontSize = "large",
			}
		}
	}

	-- helper to add fields
	local function addField(order, label, text, asInput)
		if not text then return end
		if asInput then
			Table.args[label] = {
				order = order,
				name = "|cffe6cc80" .. L[label] .. ": |r",
				desc = L["Click and press Ctrl-C to copy"],
				type = "input", -- AceConfig input box
				width = "full",
				get = function() return text end,
			}
		else
			Table.args[label] = {
				order = order,
				name = "|cffe6cc80" .. L[label] .. ": |r" .. text,
				type = "description",
			}
		end
	end

	-- Add optional fields
	local notes = GetNotes(addon)
	if notes then
		Table.args.blank = { order = 2, name = "", type = "description" }
		Table.args.notes = { order = 3, name = notes, type = "description", fontSize = "medium" }
	end

	addField(5,		"Version",			GetVersion(addon))
	addField(6,		"Author",			GetAuthor(addon))
	addField(7,		"Email",			GetEmail(addon), true)
	addField(8,		"Date",				GetAddOnDate(addon))
	addField(9,		"Category",			GetCategory(addon))
	addField(10,	"License",			GetLicense(addon))
	addField(11,	"Credits",			GetCredits(addon))
	addField(12,	"Website",			GetWebsite(addon), true)
	addField(13,	"Localizations",	GetLocalizations(addon))

	AboutPanel.aboutTable[addon] = Table
	return Table
end

-- -----------------------------------------------------
-- Embeds AboutPanel API into target addon object for easy usage
-- -----------------------------------------------------
local mixins = { "CreateAboutPanel", "AboutOptionsTable" }
function AboutPanel:Embed(target)
	for _, name in pairs(mixins) do
		target[name] = self[name]
	end
	self.embeds[target] = true
	return target
end

-- Upgrades previously embedded addons if a new version of the library is loaded
for target, _ in pairs(AboutPanel.embeds) do
	AboutPanel:Embed(target)
end