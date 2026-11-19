local _, ns = ...

-- Color tokens and fonts from the web page (wow-keybinds/index.html), plus small widget
-- builders so every window shares the same dark warlock look.
local function hex(h, a)
  return { tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255, a or 1 }
end
local T = {
  bg = hex("0f0b14"), panel = hex("1a1421"), panel2 = hex("241c2e"), line = hex("3a2f47"),
  ink = hex("f0e9f6"), muted = hex("a99bb7"), fel = hex("93d35a"), void = hex("a77ce8"),
  blood = hex("ef5d55"), brass = hex("d6b066"), keyTop = hex("2b2336"), keyBot = hex("1b1524"),
  keyEdge = hex("08060b"), well = hex("0b0810"), code = hex("d5efbd"),
  moveTop = hex("1e2a25"), moveBot = hex("151e1a"),
}
ns.T = T
ns.WHITE = "Interface\\Buttons\\WHITE8X8"

local DIR = "Interface\\AddOns\\FoilKeybinds\\Media\\Fonts\\"
local FILES = {
  display = DIR .. "GrenzeGotisch-Bold.ttf", body = DIR .. "AlegreyaSans-Medium.ttf",
  bold = DIR .. "AlegreyaSans-Bold.ttf", mono = DIR .. "JetBrainsMono-Bold.ttf",
}
local fonts, offset = {}, 0
local function setFont(o, kind, size)
  local ok = o:SetFont(FILES[kind], size + offset, "")
  if ok == false or not o:GetFont() then o:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size + offset, "") end
end
-- ns.Font("mono", 11) -> a shared Font object. Falls back to the game font if the file fails.
function ns.Font(kind, size)
  local id = kind .. size
  if fonts[id] then return fonts[id].o end
  local o = CreateFont("FoilKeybindsFont_" .. id)
  setFont(o, kind, size)
  o:SetTextColor(unpack(T.ink))
  fonts[id] = { o = o, kind = kind, size = size }
  return o
end

-- Text size setting: every font of the addon grows or shrinks by the same points, live (font
-- strings follow their Font object). Widths measured at build time (chips, check labels) stay.
ns.TEXT_OFFSET = { small = -2, normal = 0, large = 2 }
function ns.SetTextSize(choice)
  local o = ns.TEXT_OFFSET[choice] or 0
  if o == offset then return end
  offset = o
  for _, f in pairs(fonts) do setFont(f.o, f.kind, f.size) end
end

function ns.Text(parent, kind, size, color, layer)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY")
  fs:SetFontObject(ns.Font(kind, size)); fs:SetTextColor(unpack(color or T.ink))
  return fs
end

-- Flat backdrop: 1px border. frame must inherit BackdropTemplate.
function ns.Skin(frame, bg, border, edge)
  frame:SetBackdrop({ bgFile = ns.WHITE, edgeFile = ns.WHITE, edgeSize = edge or 1 })
  frame:SetBackdropColor(unpack(bg or T.panel)); frame:SetBackdropBorderColor(unpack(border or T.line))
end

-- Vertical gradient texture, top color first.
function ns.Gradient(parent, top, bottom, layer, sub)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 1)
  t:SetTexture(ns.WHITE)
  t:SetGradient("VERTICAL", CreateColor(unpack(bottom)), CreateColor(unpack(top)))
  return t
end

-- White shape textures from Media (tools/make_media.py), tinted with SetVertexColor.
-- Round and Dash are sliced (8 px margins) so the corners keep their shape at any size; Dash
-- tiles its edges so the dashes keep their length. A client without slicing gets a flat square box,
-- and the dashed line stretched as one picture.
-- ponytail: no fixed-size variants; add them if a client without slicing ever matters.
local MEDIA = "Interface\\AddOns\\FoilKeybinds\\Media\\"
local SLICE = Enum and Enum.UITextureSliceMode
local warned -- say once in chat when the client cannot slice, so square shapes are not mistaken for the design
function ns.Shape(parent, file, layer, sub)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub)
  local sliced = file == "Round" or file == "Dash"
  if sliced and not (SLICE and t.SetTextureSliceMargins and t.SetTextureSliceMode) then
    t:SetTexture(file == "Dash" and MEDIA .. file or ns.WHITE)
    if not warned and ns.Say then warned = true; ns.Say(ns.L.NO_SLICE) end
    return t
  end
  t:SetTexture(MEDIA .. file)
  if sliced then
    t:SetTextureSliceMargins(8, 8, 8, 8)
    t:SetTextureSliceMode(file == "Dash" and SLICE.Tiled or SLICE.Stretched)
  end
  return t
end

-- Rounded box behind a frame: outline at full size, face 1px inside. Recolor with
-- f.rLine:SetVertexColor / f.rFace:SetVertexColor.
function ns.RoundSkin(f, bg, border)
  f.rLine = ns.Shape(f, "Round", "BACKGROUND", -7); f.rLine:SetAllPoints()
  f.rFace = ns.Shape(f, "Round", "BACKGROUND", -6)
  f.rFace:SetPoint("TOPLEFT", 1, -1); f.rFace:SetPoint("BOTTOMRIGHT", -1, 1)
  f.rLine:SetVertexColor(unpack(border or T.line)); f.rFace:SetVertexColor(unpack(bg or T.panel))
end

-- Dark window: gradient body, title bar with the display font, close button.
function ns.Panel(name, parent, title)
  local p = CreateFrame("Frame", name, parent, "BackdropTemplate")
  ns.Skin(p, T.bg, T.line)
  local wash = ns.Gradient(p, { T.void[1], T.void[2], T.void[3], 0.12 }, { T.bg[1], T.bg[2], T.bg[3], 0 })
  wash:SetPoint("TOPLEFT", 1, -1); wash:SetPoint("TOPRIGHT", -1, -1); wash:SetHeight(180)
  local bar = p:CreateTexture(nil, "BORDER"); bar:SetColorTexture(unpack(T.panel))
  bar:SetPoint("TOPLEFT", 1, -1); bar:SetPoint("TOPRIGHT", -1, -1); bar:SetHeight(26)
  local rule = p:CreateTexture(nil, "BORDER", nil, 2); rule:SetColorTexture(T.brass[1], T.brass[2], T.brass[3], 0.35)
  rule:SetPoint("TOPLEFT", bar, "BOTTOMLEFT"); rule:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT"); rule:SetHeight(1)
  p.wash, p.bar, p.rule = wash, bar, rule -- the cheat sheet fades these with its background opacity
  p.title = ns.Text(p, "display", 17, T.brass)
  p.title:SetPoint("LEFT", bar, "LEFT", 10, 0); p.title:SetText(title or "")
  local x = CreateFrame("Button", nil, p)
  x:SetSize(26, 26); x:SetPoint("TOPRIGHT", -1, -1)
  x.t = ns.Text(x, "mono", 13, T.muted); x.t:SetPoint("CENTER"); x.t:SetText("x")
  x.hl = x:CreateTexture(nil, "BACKGROUND"); x.hl:SetAllPoints(); x.hl:SetColorTexture(T.blood[1], T.blood[2], T.blood[3], 0.25); x.hl:Hide()
  x:SetScript("OnEnter", function(s) s.hl:Show(); s.t:SetTextColor(unpack(T.ink)) end)
  x:SetScript("OnLeave", function(s) s.hl:Hide(); s.t:SetTextColor(unpack(T.muted)) end)
  x:SetScript("OnClick", function() p:Hide() end)
  p.close = x
  return p
end

-- Flat button with hover and pressed states. accent = border/text color when idle (eg T.fel).
function ns.Button(parent, w, h, text, accent)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(w, h)
  ns.Skin(b, T.panel2, accent and { accent[1], accent[2], accent[3], 0.7 } or T.line)
  local fs = ns.Text(b, "mono", 11, accent or T.ink); fs:SetPoint("CENTER")
  b:SetFontString(fs)
  if text then b:SetText(text) end
  local idle = accent and { accent[1], accent[2], accent[3], 0.7 } or T.line
  b:HookScript("OnEnter", function(s) s:SetBackdropBorderColor(unpack(T.brass)); s:SetBackdropColor(unpack(T.keyTop)) end)
  b:HookScript("OnLeave", function(s) s:SetBackdropBorderColor(unpack(idle)); s:SetBackdropColor(unpack(T.panel2)) end)
  b:HookScript("OnMouseDown", function(s) s:SetBackdropColor(unpack(T.well)) end)
  b:HookScript("OnMouseUp", function(s) s:SetBackdropColor(unpack(s:IsMouseOver() and T.keyTop or T.panel2)) end)
  return b
end

-- Small square check with a fel fill when on, label to the right; keeps CheckButton API (.text).
function ns.Check(parent, text)
  local c = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
  c:SetSize(14, 14); ns.Skin(c, T.well, T.line)
  local on = c:CreateTexture(nil, "ARTWORK"); on:SetColorTexture(unpack(T.fel))
  on:SetPoint("TOPLEFT", 3, -3); on:SetPoint("BOTTOMRIGHT", -3, 3); c:SetCheckedTexture(on)
  c.text = ns.Text(c, "body", 13, T.ink); c.text:SetPoint("LEFT", c, "RIGHT", 6, 0)
  c.text:SetText(text or "")
  c:SetHitRectInsets(0, -(c.text:GetStringWidth() + 8), -4, -4) -- label is clickable too
  c:HookScript("OnEnter", function(s) s:SetBackdropBorderColor(unpack(T.brass)) end)
  c:HookScript("OnLeave", function(s) s:SetBackdropBorderColor(unpack(T.line)) end)
  c:SetScript("OnDisable", function(s) s:SetAlpha(0.35) end)
  c:SetScript("OnEnable", function(s) s:SetAlpha(1) end)
  return c
end

-- Keyboard-key style chip (modifier combos, level, key caps).
function ns.Chip(parent, kind, size, color)
  local c = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  ns.Skin(c, T.keyBot, T.line)
  local edge = c:CreateTexture(nil, "BORDER"); edge:SetColorTexture(unpack(T.keyEdge))
  edge:SetPoint("BOTTOMLEFT", 1, 1); edge:SetPoint("BOTTOMRIGHT", -1, 1); edge:SetHeight(2)
  c.text = ns.Text(c, kind or "mono", size or 10, color or T.ink); c.text:SetPoint("CENTER", 0, 1)
  function c:Set(s, pad) self.text:SetText(s); self:SetSize(math.max(self.text:GetStringWidth() + (pad or 10), 18), (size or 10) + 8) end
  return c
end

-- 1px dark + brass frame around an icon texture, like the page's .ico.
function ns.IconFrame(parent, sz)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetSize(sz, sz); ns.Skin(f, T.keyEdge, { T.brass[1], T.brass[2], T.brass[3], 0.55 })
  f.tex = f:CreateTexture(nil, "ARTWORK"); f.tex:SetPoint("TOPLEFT", 1, -1); f.tex:SetPoint("BOTTOMRIGHT", -1, 1)
  f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- crop the baked-in icon border
  return f
end

-- Labeled slider: label left, value text right (fmt(v)), flat track with a fel fill and a brass thumb.
-- Values snap to r = { min, max, step }. f:Set(v) moves it without calling f.onChange (no write back).
function ns.Slider(parent, w, label, r, fmt)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(w, 34)
  f.label = ns.Text(f, "body", 13); f.label:SetPoint("TOPLEFT"); f.label:SetText(label)
  f.value = ns.Text(f, "mono", 11, T.brass); f.value:SetPoint("TOPRIGHT")
  local s = CreateFrame("Slider", nil, f, "BackdropTemplate")
  s:SetPoint("BOTTOMLEFT", 0, 2); s:SetPoint("BOTTOMRIGHT", 0, 2); s:SetHeight(10)
  ns.Skin(s, T.well, T.line)
  s:SetOrientation("HORIZONTAL"); s:SetMinMaxValues(r[1], r[2]); s:SetValueStep(r[3]); s:SetObeyStepOnDrag(true)
  local thumb = s:CreateTexture(nil, "OVERLAY"); thumb:SetColorTexture(unpack(T.brass)); thumb:SetSize(8, 16)
  s:SetThumbTexture(thumb)
  local fill = s:CreateTexture(nil, "ARTWORK"); fill:SetColorTexture(T.fel[1], T.fel[2], T.fel[3], 0.45)
  fill:SetPoint("TOPLEFT", 1, -1); fill:SetPoint("BOTTOMLEFT", 1, 1); fill:SetPoint("RIGHT", thumb, "CENTER")
  s:SetHitRectInsets(0, 0, -6, -6)
  s:EnableMouseWheel(true)
  s:SetScript("OnMouseWheel", function(self, d) self:SetValue(self:GetValue() + d * r[3]) end)
  s:SetScript("OnValueChanged", function(_, v)
    v = ns.Snap(v, r); f.value:SetText(fmt(v))
    if not f.quiet and f.onChange and v ~= f.last then f.last = v; f.onChange(v) end
  end)
  s:HookScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(T.brass)) end)
  s:HookScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(T.line)) end)
  function f:Set(v) self.quiet, self.last = true, v; s:SetValue(v); self.value:SetText(fmt(v)); self.quiet = false end
  return f
end

-- Dropdown: a flat button showing the current choice; click opens the game menu with radio rows.
-- choices = { { value, label }, ... }. b:Set(v) shows v; picking a row calls b.onChange(value).
function ns.Dropdown(parent, w, choices)
  local b = ns.Button(parent, w, 22)
  b:GetFontString():ClearAllPoints(); b:GetFontString():SetPoint("LEFT", 8, 0)
  local arrow = b:CreateTexture(nil, "OVERLAY"); arrow:SetSize(12, 12); arrow:SetPoint("RIGHT", -6, 0)
  arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up"); arrow:SetVertexColor(unpack(T.muted))
  function b:Set(v)
    self.current = v
    for _, c in ipairs(choices) do if c[1] == v then self:SetText(c[2]) end end
  end
  b:SetScript("OnClick", function(self)
    MenuUtil.CreateContextMenu(self, function(_, root)
      for _, c in ipairs(choices) do
        local function pick() if self.onChange then self.onChange(c[1]) end end
        if root.CreateRadio then root:CreateRadio(c[2], function() return self.current == c[1] end, pick)
        else root:CreateButton(c[2], pick) end
      end
    end)
  end)
  return b
end

-- One dialog for every popup (repair, Apply preview, master switch). buttons, right to left:
-- { { label, fn, accent }, ... }. A click closes it unless fn returns true (stay open, e.g. in combat).
-- combat: close when combat starts. Esc and x close it with no action (cancel).
local dlg
function ns.Popup(title, text, buttons, combat)
  if not dlg then
    dlg = ns.Panel("FoilKeybindsPopup", UIParent, "")
    dlg:SetPoint("CENTER"); dlg:SetFrameStrata("DIALOG"); dlg:SetClampedToScreen(true)
    dlg:SetMovable(true); dlg:EnableMouse(true); dlg:RegisterForDrag("LeftButton")
    dlg:SetScript("OnDragStart", dlg.StartMoving); dlg:SetScript("OnDragStop", dlg.StopMovingOrSizing)
    dlg.scroll = CreateFrame("ScrollFrame", nil, dlg, "UIPanelScrollFrameTemplate") -- long Apply previews
    dlg.scroll:SetPoint("TOPLEFT", 16, -38); dlg.scroll:SetPoint("BOTTOMRIGHT", -32, 46)
    dlg.body = CreateFrame("Frame", nil, dlg.scroll); dlg.body:SetSize(452, 10); dlg.scroll:SetScrollChild(dlg.body)
    dlg.text = ns.Text(dlg.body, "body", 13); dlg.text:SetPoint("TOPLEFT"); dlg.text:SetWidth(452)
    dlg.text:SetJustifyH("LEFT"); dlg.text:SetSpacing(2)
    dlg.cache = {} -- one button per label and colour: accents are set at creation
    dlg:SetScript("OnEvent", dlg.Hide)
    dlg:SetScript("OnHide", function(self) self:UnregisterEvent("PLAYER_REGEN_DISABLED") end)
    tinsert(UISpecialFrames, "FoilKeybindsPopup")
  end
  dlg:Hide()
  dlg.title:SetText(title); dlg.text:SetText(text)
  for _, b in pairs(dlg.cache) do b:Hide() end
  local prev
  for _, spec in ipairs(buttons) do
    local id = spec[1] .. tostring(spec[3])
    local b = dlg.cache[id]
    if not b then
      b = ns.Button(dlg, 90, 24, spec[1], spec[3])
      b:SetWidth(math.max(90, b:GetFontString():GetStringWidth() + 24))
      dlg.cache[id] = b
    end
    b:ClearAllPoints()
    if prev then b:SetPoint("RIGHT", prev, "LEFT", -8, 0) else b:SetPoint("BOTTOMRIGHT", -14, 12) end
    b:SetScript("OnClick", function() if not (spec[2] and spec[2]()) then dlg:Hide() end end)
    b:Show(); prev = b
  end
  local h = dlg.text:GetStringHeight()
  dlg.body:SetHeight(h); dlg.scroll:SetVerticalScroll(0)
  dlg:SetSize(500, math.min(h, 420) + 90)
  if combat then dlg:RegisterEvent("PLAYER_REGEN_DISABLED") end
  dlg:Show()
end
