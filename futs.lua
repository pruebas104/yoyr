local URL_HONEYPOT = "https://raw.githubusercontent.com/pruebas104/pruebas/refs/heads/main/pruebas.lua"
local contenido_honeypot = nil
local honeypot_hash = nil
local contenido_capturado = false

local print_original = print
local warn_original = warn

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

local print_interceptado = false
local warn_interceptado = false

print = function(...)
    local args = {...}
    for _, arg in ipairs(args) do
        local str = tostring(arg)
        if honeypot_hash and #str > 30 and string.find(str, honeypot_hash:sub(1, 30), 1, true) then
            contenido_capturado = true
            print_interceptado = true
        end
    end
    return print_original(...)
end

warn = function(...)
    local args = {...}
    for _, arg in ipairs(args) do
        local str = tostring(arg)
        if honeypot_hash and #str > 30 and string.find(str, honeypot_hash:sub(1, 30), 1, true) then
            contenido_capturado = true
            warn_interceptado = true
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

local function verificarHoneypot()
    local success_download = pcall(function()
        contenido_honeypot = game:HttpGet(URL_HONEYPOT)
    end)
    
    if not success_download or not contenido_honeypot or #contenido_honeypot < 10 then
        return false
    end
    
    honeypot_hash = tostring(contenido_honeypot):sub(1, 100)
    
    local func_honeypot = loadstring(contenido_honeypot)
    if func_honeypot then
        pcall(func_honeypot)
    end
    
    task.wait(0.1)
    
    if print_interceptado or warn_interceptado then
        contenido_honeypot = nil
        return false
    end
    
    local function verificarString(str)
        if type(str) == "string" and #str > 30 then
            if string.find(str, honeypot_hash:sub(1, 30), 1, true) then
                return true
            end
        end
        return false
    end
    
    local function verificarTabla(tbl, profundidad)
        if profundidad > 3 then return false end
        if type(tbl) ~= "table" then return false end
        
        for k, v in pairs(tbl) do
            if verificarString(k) or verificarString(v) then
                return true
            end
            if type(v) == "table" then
                if verificarTabla(v, profundidad + 1) then
                    return true
                end
            end
        end
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
    
    if getgenv and not contenido_capturado then
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
    
    if shared and type(shared) == "table" and not contenido_capturado then
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
    
    if writefile and readfile and listfiles and not contenido_capturado then
        pcall(function()
            local archivos = listfiles()
            for _, archivo in ipairs(archivos) do
                local success_read, contenido_archivo = pcall(readfile, archivo)
                if success_read and contenido_archivo then
                    if verificarString(contenido_archivo) then
                        contenido_capturado = true
                        break
                    end
                end
            end
        end)
    end
    
    if isfolder and listfiles and not contenido_capturado then
        pcall(function()
            local carpetas = listfiles()
            for _, carpeta in ipairs(carpetas) do
                if isfolder(carpeta) then
                    local archivos_carpeta = listfiles(carpeta)
                    for _, archivo in ipairs(archivos_carpeta) do
                        local success_read, contenido_archivo = pcall(readfile, archivo)
                        if success_read and contenido_archivo then
                            if verificarString(contenido_archivo) then
                                contenido_capturado = true
                                break
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
    
    if contenido_capturado then
        return false
    end
    
    return true
end

if not verificarHoneypot() then
    return
end

print_original("Honeypot pasado - Script principal continua")
