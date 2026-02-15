print("🔍 Verificando si hay hooks instalados...")

local hooksInstalados = false

-- Guardar referencias ORIGINALES al inicio
local loadstring_ref = loadstring
local httpget_ref = game.HttpGet
local hash_load = tostring(loadstring):sub(-10)
local hash_http = tostring(game.HttpGet):sub(-10)

-- Test 1: Comparar hashes (si cambiaron = fueron hookeados)
if tostring(loadstring):sub(-10) ~= hash_load then
    print("🔴 loadstring FUE MODIFICADO")
    hooksInstalados = true
end

if tostring(game.HttpGet):sub(-10) ~= hash_http then
    print("🔴 HttpGet FUE MODIFICADO")
    hooksInstalados = true
end

-- Test 2: Verificar si fueron envueltos con newcclosure
if debug and debug.getinfo then
    local info_load = debug.getinfo(loadstring)
    if info_load and info_load.what ~= "C" then
        print("🔴 loadstring fue envuelto (no es función C nativa)")
        hooksInstalados = true
    end
    
    local info_http = debug.getinfo(game.HttpGet)
    if info_http and info_http.what ~= "C" then
        print("🔴 HttpGet fue envuelto (no es función C nativa)")
        hooksInstalados = true
    end
end

-- Test 3: Verificar metatable de game
local mt = getrawmetatable(game)
local readonly = isreadonly(mt)

if not readonly then
    print("🔴 Metatable de game NO es readonly (fue modificada)")
    hooksInstalados = true
end

-- Test 4: Comparar __namecall actual vs hash original
if mt.__namecall then
    local hash_namecall_actual = tostring(mt.__namecall):sub(-10)
    -- Ejecutar test y guardar hash
    local test_nc = mt.__namecall
    local hash_test = tostring(test_nc):sub(-10)
    
    -- Si el hash es diferente cada vez = newcclosure usado
    if hash_namecall_actual ~= hash_test then
        print("🔴 __namecall fue hookeado con newcclosure")
        hooksInstalados = true
    end
end

-- Test 5: Intentar detectar variables de captura persistentes
local testVars = {
    "_G.",
    "_G.", 
    "_G.",
    "_G."
}

for _, varName in ipairs(testVars) do
    if _G[varName:match("%.(.+)")] then
        print("🔴 Variable de captura encontrada: " .. varName)
        hooksInstalados = true
    end
end

print(string.rep("═", 60))

if hooksInstalados then
    print("🔴 HAY HOOKS INSTALADOS Y ACTIVOS")
    print("⚠️ Tu código está siendo interceptado")
    print("❌ EJECUCIÓN BLOQUEADA POR SEGURIDAD")
    print(string.rep("═", 60))
    return
else
    print("✅ NO HAY HOOKS INSTALADOS")
    print("✓ Entorno limpio y seguro")
    print("▶️ Ejecutando script...")
    print(string.rep("═", 60))
    
    loadstring(game:HttpGet('https://raw.githubusercontent.com/Colato6/Prueba.1/refs/heads/main/Farm.lua'))()
end
