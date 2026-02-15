print("🔍 Verificando hooks instalados...")
local hooksInstalados = false
local loadstring_original = loadstring
local httpget_original = game.HttpGet
local hash_loadstring = tostring(loadstring):sub(-10)
local hash_httpget = tostring(game.HttpGet):sub(-10)
if tostring(loadstring):sub(-10) ~= hash_loadstring then
    print("🔴 loadstring hash cambió")
    hooksInstalados = true
end
if tostring(game.HttpGet):sub(-10) ~= hash_httpget then
    print("🔴 HttpGet hash cambió")
    hooksInstalados = true
end
if loadstring ~= loadstring_original then
    print("🔴 loadstring fue reemplazado")
    hooksInstalados = true
end
if game.HttpGet ~= httpget_original then
    print("🔴 HttpGet fue reemplazado")
    hooksInstalados = true
end
if debug and debug.getinfo then
    local info_ls = debug.getinfo(loadstring)
    if info_ls then
        if info_ls.what ~= "C" then
            print("🔴 loadstring NO es tipo C")
            hooksInstalados = true
        end
        if info_ls.nparams then
            print("🔴 loadstring tiene parámetros envueltos")
            hooksInstalados = true
        end
        if info_ls.source and info_ls.source ~= "=[C]" then
            print("🔴 loadstring source no es [C]")
            hooksInstalados = true
        end
    end
    local info_http = debug.getinfo(game.HttpGet)
    if info_http then
        if info_http.what ~= "C" then
            print("🔴 HttpGet NO es tipo C")
            hooksInstalados = true
        end
        if info_http.source and info_http.source ~= "=[C]" then
            print("🔴 HttpGet source no es [C]")
            hooksInstalados = true
        end
    end
end
local mt = getrawmetatable(game)
if not isreadonly(mt) then
    print("🔴 Metatable NO es readonly")
    hooksInstalados = true
end
if mt.__namecall then
    local info_nc = debug and debug.getinfo and debug.getinfo(mt.__namecall)
    if info_nc then
        if info_nc.what ~= "C" then
            print("🔴 __namecall hookeado")
            hooksInstalados = true
        end
        if info_nc.source and info_nc.source ~= "=[C]" then
            print("🔴 __namecall source modificado")
            hooksInstalados = true
        end
    end
end
if mt.__index then
    local info_idx = debug and debug.getinfo and debug.getinfo(mt.__index)
    if info_idx and info_idx.what ~= "C" then
        print("🔴 __index hookeado")
        hooksInstalados = true
    end
end
if _G.loadstring and _G.loadstring ~= loadstring then
    print("🔴 _G.loadstring modificado")
    hooksInstalados = true
end
local env = getfenv(1)
if env.loadstring and env.loadstring ~= loadstring_original then
    print("🔴 entorno loadstring modificado")
    hooksInstalados = true
end
local test_func = loadstring("return 123")
if test_func then
    local result = test_func()
    if result ~= 123 then
        print("🔴 loadstring retorna valores incorrectos")
        hooksInstalados = true
    end
end
local test_http = pcall(function()
    return game:HttpGet("https://httpbin.org/status/200")
end)
if not test_http then
    print("🔴 HttpGet falló en test básico")
    hooksInstalados = true
end
print(string.rep("═", 60))
if hooksInstalados then
    print("🔴 HOOKS DETECTADOS")
    print("⚠️ Código interceptado")
    print("❌ BLOQUEADO")
    print(string.rep("═", 60))
    return
else
    print("✅ ENTORNO LIMPIO")
    print("▶️ Ejecutando...")
    print(string.rep("═", 60))
    loadstring(game:HttpGet('https://raw.githubusercontent.com/Colato6/Prueba.1/refs/heads/main/Farm.lua'))()
end
