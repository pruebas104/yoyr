local abortar = false
local URL_TEST = "https://pastebin.com/raw/test123"

local contenido_test = nil
local marker_unico = "TESTMARKER_" .. tostring(tick()):gsub("%.", "") .. "_" .. tostring(math.random(100000, 999999))

local globales_iniciales = {}
for k, v in pairs(_G) do
    globales_iniciales[k] = true
end

if getgenv then
    local env = getgenv()
    if env then
        for k, v in pairs(env) do
            globales_iniciales[k] = true
        end
    end
end

local archivos_iniciales = {}
if listfiles then
    pcall(function()
        local archivos = listfiles()
        for _, archivo in ipairs(archivos) do
            archivos_iniciales[archivo] = true
        end
    end)
end

local print_original = print
local warn_original = warn

local print_calls = {}
local warn_calls = {}

print = function(...)
    local args = {...}
    for i, arg in ipairs(args) do
        table.insert(print_calls, tostring(arg))
    end
    return print_original(...)
end

warn = function(...)
    local args = {...}
    for i, arg in ipairs(args) do
        table.insert(warn_calls, tostring(arg))
    end
    return warn_original(...)
end

if getgenv then
    getgenv().print = print
    getgenv().warn = warn
end
_G.print = print
_G.warn = warn

local function buscarMarker(texto)
    if type(texto) ~= "string" then return false end
    if #texto < 20 then return false end
    
    if string.find(texto, marker_unico, 1, true) then
        return true
    end
    
    if string.find(texto, "TESTMARKER_", 1, true) then
        return true
    end
    
    return false
end

local function verificarCaptura()
    task.wait(0.05)
    
    for _, call in ipairs(print_calls) do
        if buscarMarker(call) then
            return false
        end
    end
    
    for _, call in ipairs(warn_calls) do
        if buscarMarker(call) then
            return false
        end
    end
    
    for k, v in pairs(_G) do
        if not globales_iniciales[k] then
            if type(v) == "string" and buscarMarker(v) then
                return false
            end
            if type(v) == "table" then
                for k2, v2 in pairs(v) do
                    if type(v2) == "string" and buscarMarker(v2) then
                        return false
                    end
                    if type(v2) == "table" then
                        for k3, v3 in pairs(v2) do
                            if type(v3) == "string" and buscarMarker(v3) then
                                return false
                            end
                        end
                    end
                end
            end
        end
    end
    
    if getgenv then
        local env = getgenv()
        if env then
            for k, v in pairs(env) do
                if not globales_iniciales[k] then
                    if type(v) == "string" and buscarMarker(v) then
                        return false
                    end
                    if type(v) == "table" then
                        for k2, v2 in pairs(v) do
                            if type(v2) == "string" and buscarMarker(v2) then
                                return false
                            end
                            if type(v2) == "table" then
                                for k3, v3 in pairs(v2) do
                                    if type(v3) == "string" and buscarMarker(v3) then
                                        return false
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    if shared then
        for k, v in pairs(shared) do
            if type(v) == "string" and buscarMarker(v) then
                return false
            end
            if type(v) == "table" then
                for k2, v2 in pairs(v) do
                    if type(v2) == "string" and buscarMarker(v2) then
                        return false
                    end
                end
            end
        end
    end
    
    if listfiles then
        pcall(function()
            local archivos = listfiles()
            for _, archivo in ipairs(archivos) do
                if not archivos_iniciales[archivo] then
                    if readfile then
                        local success, contenido = pcall(readfile, archivo)
                        if success and contenido then
                            if buscarMarker(contenido) then
                                abortar = true
                            end
                        end
                    end
                end
            end
        end)
    end
    
    if abortar then
        return false
    end
    
    return true
end

local function testInterceptor()
    contenido_test = marker_unico .. string.rep("X", 100) .. marker_unico
    
    if not verificarCaptura() then
        return false
    end
    
    local func_test = loadstring("return '" .. marker_unico .. "'")
    if func_test then
        pcall(func_test)
    end
    
    if not verificarCaptura() then
        return false
    end
    
    local test_http = pcall(function()
        local url_fake = "https://raw.githubusercontent.com/test/test/main/test.lua"
        game:HttpGet(url_fake)
    end)
    
    task.wait(0.1)
    
    if not verificarCaptura() then
        return false
    end
    
    contenido_test = nil
    marker_unico = nil
    
    return true
end

if not testInterceptor() then
    return
end

local URL_HONEYPOT = "https://raw.githubusercontent.com/pruebas104/pruebas/refs/heads/main/pruebas.lua"
local contenido_honeypot = nil
local honeypot_hash = nil
local contenido_capturado = false

local marker_honeypot = "HONEYPOT_" .. tostring(tick()):gsub("%.", "") .. "_" .. tostring(math.random(100000, 999999))

print_calls = {}
warn_calls = {}

local function buscarHoneypot(texto)
    if type(texto) ~= "string" then return false end
    if #texto < 50 then return false end
    
    if honeypot_hash and string.find(texto, honeypot_hash, 1, true) then
        return true
    end
    
    if string.find(texto, "HONEYPOT_", 1, true) then
        return true
    end
    
    return false
end

local function verificarHoneypot()
    local success_download = pcall(function()
        contenido_honeypot = game:HttpGet(URL_HONEYPOT)
    end)
    
    if not success_download or not contenido_honeypot or #contenido_honeypot < 10 then
        return false
    end
    
    honeypot_hash = contenido_honeypot:sub(1, 50)
    contenido_honeypot = marker_honeypot .. contenido_honeypot .. marker_honeypot
    
    local func_honeypot = loadstring(contenido_honeypot)
    if func_honeypot then
        pcall(func_honeypot)
    end
    
    task.wait(0.1)
    
    for _, call in ipairs(print_calls) do
        if buscarHoneypot(call) then
            contenido_capturado = true
        end
    end
    
    for _, call in ipairs(warn_calls) do
        if buscarHoneypot(call) then
            contenido_capturado = true
        end
    end
    
    if contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    for k, v in pairs(_G) do
        if not globales_iniciales[k] then
            if type(v) == "string" and buscarHoneypot(v) then
                contenido_capturado = true
                break
            end
            if type(v) == "table" then
                for k2, v2 in pairs(v) do
                    if type(v2) == "string" and buscarHoneypot(v2) then
                        contenido_capturado = true
                        break
                    end
                    if type(v2) == "table" then
                        for k3, v3 in pairs(v2) do
                            if type(v3) == "string" and buscarHoneypot(v3) then
                                contenido_capturado = true
                                break
                            end
                        end
                    end
                    if contenido_capturado then break end
                end
            end
        end
        if contenido_capturado then break end
    end
    
    if contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    if getgenv then
        pcall(function()
            local env = getgenv()
            if env and type(env) == "table" then
                for k, v in pairs(env) do
                    if not globales_iniciales[k] then
                        if type(v) == "string" and buscarHoneypot(v) then
                            contenido_capturado = true
                        end
                        if type(v) == "table" then
                            for k2, v2 in pairs(v) do
                                if type(v2) == "string" and buscarHoneypot(v2) then
                                    contenido_capturado = true
                                end
                                if type(v2) == "table" then
                                    for k3, v3 in pairs(v2) do
                                        if type(v3) == "string" and buscarHoneypot(v3) then
                                            contenido_capturado = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    
    if contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    if shared and type(shared) == "table" then
        pcall(function()
            for k, v in pairs(shared) do
                if type(v) == "string" and buscarHoneypot(v) then
                    contenido_capturado = true
                end
                if type(v) == "table" then
                    for k2, v2 in pairs(v) do
                        if type(v2) == "string" and buscarHoneypot(v2) then
                            contenido_capturado = true
                        end
                    end
                end
            end
        end)
    end
    
    if contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    if listfiles and readfile then
        pcall(function()
            local archivos = listfiles()
            local revisados = 0
            for _, archivo in ipairs(archivos) do
                revisados = revisados + 1
                if revisados > 100 then break end
                
                if string.find(archivo, ".lua") or string.find(archivo, ".txt") then
                    local success_read, contenido_archivo = pcall(readfile, archivo)
                    if success_read and contenido_archivo then
                        if buscarHoneypot(contenido_archivo) then
                            contenido_capturado = true
                            break
                        end
                    end
                end
            end
        end)
    end
    
    if contenido_capturado then
        contenido_honeypot = nil
        return false
    end
    
    if isfolder and listfiles then
        pcall(function()
            local carpetas = listfiles()
            local carpetas_revisadas = 0
            
            for _, carpeta in ipairs(carpetas) do
                carpetas_revisadas = carpetas_revisadas + 1
                if carpetas_revisadas > 30 then break end
                
                if isfolder(carpeta) then
                    local archivos_carpeta = listfiles(carpeta)
                    local archivos_revisados = 0
                    
                    for _, archivo in ipairs(archivos_carpeta) do
                        archivos_revisados = archivos_revisados + 1
                        if archivos_revisados > 50 then break end
                        
                        if string.find(archivo, ".lua") or string.find(archivo, ".txt") then
                            local success_read, contenido_archivo = pcall(readfile, archivo)
                            if success_read and contenido_archivo then
                                if buscarHoneypot(contenido_archivo) then
                                    contenido_capturado = true
                                    break
                                end
                            end
                        end
                    end
                end
                if contenido_capturado then break end
            end
        end)
    end
    
    contenido_honeypot = nil
    honeypot_hash = nil
    marker_honeypot = nil
    
    if contenido_capturado then
        return false
    end
    
    return true
end

if not verificarHoneypot() then
    return
end

print_original("[✓] Test de interceptor: PASADO")
print_original("[✓] Honeypot behavioral: PASADO")
print_original("[✓] Verificación de archivos: PASADO")
print_original("[→] Script principal continúa...")
