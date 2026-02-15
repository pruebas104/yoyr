local abortar = false

local function verificarHooksActivos()
    local mt = getrawmetatable(game)
    local original_namecall = mt.__namecall
    local original_index = mt.__index
    
    local hash_namecall = tostring(original_namecall)
    local hash_index = tostring(original_index)
    
    if string.find(hash_namecall, "cclosure") or string.find(hash_index, "cclosure") then
        return false
    end
    
    local info_namecall = debug.getinfo(original_namecall)
    if info_namecall and info_namecall.what ~= "C" then
        return false
    end
    
    local test_loadstring = loadstring
    local hash_loadstring = tostring(test_loadstring)
    if string.find(hash_loadstring, "cclosure") then
        return false
    end
    
    local info_loadstring = debug.getinfo(loadstring)
    if info_loadstring and info_loadstring.what ~= "C" then
        return false
    end
    
    if getgenv then
        local env = getgenv()
        if env.loadstring and env.loadstring ~= loadstring then
            return false
        end
        if env.captured or env.intercept or env.logger then
            return false
        end
    end
    
    if _G.captured or _G.intercept or _G.logger then
        return false
    end
    
    if shared and (shared.captured or shared.intercept or shared.logger) then
        return false
    end
    
    return true
end

if not verificarHooksActivos() then
    return
end

local URL_HONEYPOT = "https://raw.githubusercontent.com/pruebas104/pruebas/refs/heads/main/pruebas.lua"
local contenido_honeypot = nil
local honeypot_hash = nil
local honeypot_hash_corto = nil
local contenido_capturado = false

local globales_iniciales = {}
for k, v in pairs(_G) do
    globales_iniciales[k] = true
end

if getgenv then
    local env = getgenv()
    for k, v in pairs(env) do
        globales_iniciales[k] = true
    end
end

local print_original = print
local warn_original = warn
local print_interceptado = false
local warn_interceptado = false

print = function(...)
    local args = {...}
    for _, arg in ipairs(args) do
        local str = tostring(arg)
        if honeypot_hash_corto and #str > 20 and string.find(str, honeypot_hash_corto, 1, true) then
            contenido_capturado = true
            print_interceptado = true
            abortar = true
        end
        if honeypot_hash and #str > 50 and string.find(str, honeypot_hash:sub(1, 50), 1, true) then
            contenido_capturado = true
            print_interceptado = true
            abortar = true
        end
    end
    return print_original(...)
end

warn = function(...)
    local args = {...}
    for _, arg in ipairs(args) do
        local str = tostring(arg)
        if honeypot_hash_corto and #str > 20 and string.find(str, honeypot_hash_corto, 1, true) then
            contenido_capturado = true
            warn_interceptado = true
            abortar = true
        end
        if honeypot_hash and #str > 50 and string.find(str, honeypot_hash:sub(1, 50), 1, true) then
            contenido_capturado = true
            warn_interceptado = true
            abortar = true
        end
    end
    return warn_original(...)
end

if getgenv then
    getgenv().print = print
    getgenv().warn = warn
end
_G.print = print
_G.warn = warn

local function verificarString(str)
    if type(str) ~= "string" then return false end
    if #str < 20 then return false end
    
    if honeypot_hash_corto and string.find(str, honeypot_hash_corto, 1, true) then
        return true
    end
    if honeypot_hash and #str > 50 and string.find(str, honeypot_hash:sub(1, 50), 1, true) then
        return true
    end
    return false
end

local function verificarTabla(tbl, profundidad, visitadas)
    if profundidad > 4 then return false end
    if type(tbl) ~= "table" then return false end
    
    visitadas = visitadas or {}
    if visitadas[tbl] then return false end
    visitadas[tbl] = true
    
    local keys_checked = 0
    for k, v in pairs(tbl) do
        keys_checked = keys_checked + 1
        if keys_checked > 100 then break end
        
        if verificarString(k) or verificarString(v) then
            return true
        end
        
        if type(v) == "table" then
            if verificarTabla(v, profundidad + 1, visitadas) then
                return true
            end
        end
    end
    return false
end

local function verificarHoneypot()
    if not verificarHooksActivos() then
        return false
    end
    
    local success_download = pcall(function()
        contenido_honeypot = game:HttpGet(URL_HONEYPOT)
    end)
    
    if abortar or contenido_capturado then
        return false
    end
    
    if not success_download or not contenido_honeypot or #contenido_honeypot < 10 then
        return false
    end
    
    honeypot_hash = tostring(contenido_honeypot)
    honeypot_hash_corto = honeypot_hash:sub(1, 30)
    
    task.wait(0.05)
    
    if abortar or print_interceptado or warn_interceptado or contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    local func_honeypot = loadstring(contenido_honeypot)
    if func_honeypot then
        pcall(func_honeypot)
    end
    
    task.wait(0.1)
    
    if abortar or print_interceptado or warn_interceptado or contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    for k, v in pairs(_G) do
        if not globales_iniciales[k] then
            if verificarString(k) or verificarString(v) then
                contenido_capturado = true
                break
            end
            if type(v) == "table" then
                if verificarTabla(v, 0) then
                    contenido_capturado = true
                    break
                end
            end
        end
    end
    
    if abortar or contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    if getgenv then
        pcall(function()
            local env = getgenv()
            if env and type(env) == "table" then
                for k, v in pairs(env) do
                    if not globales_iniciales[k] then
                        if verificarString(k) or verificarString(v) then
                            contenido_capturado = true
                        end
                        if type(v) == "table" then
                            if verificarTabla(v, 0) then
                                contenido_capturado = true
                            end
                        end
                    end
                end
            end
        end)
    end
    
    if abortar or contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    if shared and type(shared) == "table" then
        pcall(function()
            for k, v in pairs(shared) do
                if verificarString(k) or verificarString(v) then
                    contenido_capturado = true
                end
                if type(v) == "table" then
                    if verificarTabla(v, 0) then
                        contenido_capturado = true
                    end
                end
            end
        end)
    end
    
    if abortar or contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    if writefile and readfile and listfiles then
        pcall(function()
            local archivos = listfiles()
            local archivos_revisados = 0
            
            for _, archivo in ipairs(archivos) do
                archivos_revisados = archivos_revisados + 1
                if archivos_revisados > 50 then break end
                
                if string.find(archivo, ".lua") or string.find(archivo, ".txt") then
                    local success_read, contenido_archivo = pcall(readfile, archivo)
                    if success_read and contenido_archivo then
                        if verificarString(contenido_archivo) then
                            contenido_capturado = true
                            break
                        end
                    end
                end
            end
        end)
    end
    
    if abortar or contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    if isfolder and listfiles then
        pcall(function()
            local carpetas = listfiles()
            local carpetas_revisadas = 0
            
            for _, carpeta in ipairs(carpetas) do
                carpetas_revisadas = carpetas_revisadas + 1
                if carpetas_revisadas > 20 then break end
                
                if isfolder(carpeta) then
                    local archivos_carpeta = listfiles(carpeta)
                    local archivos_revisados = 0
                    
                    for _, archivo in ipairs(archivos_carpeta) do
                        archivos_revisados = archivos_revisados + 1
                        if archivos_revisados > 30 then break end
                        
                        if string.find(archivo, ".lua") or string.find(archivo, ".txt") then
                            local success_read, contenido_archivo = pcall(readfile, archivo)
                            if success_read and contenido_archivo then
                                if verificarString(contenido_archivo) then
                                    contenido_capturado = true
                                    break
                                end
                            end
                        end
                    end
                end
                if contenido_capturado or abortar then break end
            end
        end)
    end
    
    contenido_honeypot = nil
    honeypot_hash = nil
    honeypot_hash_corto = nil
    
    if abortar or contenido_capturado then
        return false
    end
    
    return true
end

if not verificarHoneypot() then
    return
end

if not verificarHooksActivos() then
    return
end

print_original("[✓] Sistema anti-hook: PASADO")
print_original("[✓] Honeypot: PASADO")
print_original("[✓] Verificación de archivos: PASADO")
print_original("[→] Script principal continúa...")
