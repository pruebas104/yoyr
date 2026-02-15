print("🔒 Loader Simple Anti-Captura")
local loadstring_real = loadstring
getgenv().loadstring = function() return function() end end
loadstring = function() return function() end end
print("✓ Bloqueando capturadores...")
local code = game:HttpGet('https://raw.githubusercontent.com/pruebas104/pruebas/refs/heads/main/pruebas.lua')
print("✓ Código descargado")
getgenv().loadstring = loadstring_real
loadstring = loadstring_real
print("✓ Restaurando loadstring...")
task.wait(0.1)
local func = loadstring_real(code)
code = nil
print("✓ Ejecutando...")
func()
