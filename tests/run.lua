-- Plain assert-based runner. Run from repo root: luajit tests/run.lua
local core = dofile("FoilKeybinds/Core.lua")
local tests, failed = {}, 0
local function test(name, fn) tests[#tests + 1] = { name, fn } end

test("normal slot spell gives #showtooltip + /cast", function()
  local got = core.MacroText({ normal = "Shadow Bolt" })
  assert(got == "#showtooltip\n/cast Shadow Bolt", ("got %q"):format(got))
end)

for _, t in ipairs(tests) do
  local ok, err = pcall(t[2])
  print((ok and "ok   " or "FAIL ") .. t[1] .. (ok and "" or ("\n     " .. tostring(err))))
  if not ok then failed = failed + 1 end
end
print(("%d tests, %d failed"):format(#tests, failed))
os.exit(failed == 0 and 0 or 1)
