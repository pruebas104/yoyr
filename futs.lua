print("=== Iniciando protección anti-captura ===")
local proteccion_activa = true
local advertencias = {}
local function agregarAdvertencia(msg)
    table.insert(advertencias, msg)
    warn("⚠ ADVERTENCIA:", msg)
end
local loadstring_original = loadstring
local http_original = game.HttpGet
local hash_loadstring = tostring(loadstring):sub(-10)
local hash_httpget = tostring(game.HttpGet):sub(-10)
local codigo_capturado = false
local variables_sospechosas = {}
local function verificarEntorno()
    if loadstring ~= loadstring_original then
        agregarAdvertencia("loadstring fue modificado - Posible captura de código")
        proteccion_activa = false
        return false
    end
    if tostring(loadstring):sub(-10) ~= hash_loadstring then
        agregarAdvertencia("Hash de loadstring cambió - Hook detectado")
        proteccion_activa = false
        return false
    end
    if game.HttpGet ~= http_original then
        agregarAdvertencia("HttpGet fue modificado - Interceptación de red")
        proteccion_activa = false
        return false
    end
    if tostring(game.HttpGet):sub(-10) ~= hash_httpget then
        agregarAdvertencia("Hash de HttpGet cambió - Hook detectado")
        proteccion_activa = false
        return false
    end
    return true
end
local function detectarVariablesCaptura()
    if _G.captured_code or _G.intercepted or _G.hooked_code then
        agregarAdvertencia("Variables de captura detectadas en _G")
        return true
    end
    if getgenv then
        local env = getgenv()
        if env.captured_code or env.intercepted or env.hooked_code then
            agregarAdvertencia("Variables de captura detectadas en getgenv()")
            return true
        end
    end
    return false
end
local function verificarHooksActivos()
    if hookfunction or hookmetamethod then
        local info_loadstring = debug and debug.getinfo and debug.getinfo(loadstring)
        if info_loadstring and info_loadstring.what ~= "C" then
            agregarAdvertencia("loadstring fue hookeado - what: " .. info_loadstring.what)
            return true
        end
    end
    return false
end
local url = 'https://raw.githubusercontent.com/Colato6/Prueba.1/refs/heads/main/Farm.lua'
print("Verificando entorno antes de descargar...")
if not verificarEntorno() then
    error("⛔ EJECUCIÓN BLOQUEADA: Entorno comprometido", 0)
end
if detectarVariablesCaptura() then
    error("⛔ EJECUCIÓN BLOQUEADA: Variables de captura detectadas", 0)
end
if verificarHooksActivos() then
    error("⛔ EJECUCIÓN BLOQUEADA: Hooks activos detectados", 0)
end
print("✓ Entorno limpio, descargando código...")
local codigo_original = game:HttpGet(url)
if not verificarEntorno() then
    codigo_original = nil
    error("⛔ EJECUCIÓN BLOQUEADA: Entorno modificado durante descarga", 0)
end
local hash_codigo = tostring(codigo_original):len()
print("✓ Código descargado, verificando integridad...")
task.wait(0.05)
if detectarVariablesCaptura() then
    codigo_original = nil
    error("⛔ EJECUCIÓN BLOQUEADA: Intento de captura detectado", 0)
end
local codigo_encriptado = codigo_original
codigo_original = nil
print("✓ Preparando ejecución...")
if not verificarEntorno() then
    codigo_encriptado = nil
    error("⛔ EJECUCIÓN BLOQUEADA: Modificación detectada antes de ejecutar", 0)
end
local funcion_cargada = loadstring(codigo_encriptado)
local hash_check = tostring(codigo_encriptado):len()
codigo_encriptado = nil
if hash_check ~= hash_codigo then
    funcion_cargada = nil
    error("⛔ EJECUCIÓN BLOQUEADA: Código fue modificado", 0)
end
if not funcion_cargada then
    error("⛔ ERROR: No se pudo cargar el código", 0)
end
if not verificarEntorno() then
    funcion_cargada = nil
    error("⛔ EJECUCIÓN BLOQUEADA: Modificación detectada después de cargar", 0)
end
task.spawn(function()
    while proteccion_activa do
        task.wait(0.5)
        if not verificarEntorno() then
            error("⛔ PROTECCIÓN: Hook detectado durante ejecución", 0)
        end
        if detectarVariablesCaptura() then
            error("⛔ PROTECCIÓN: Captura detectada durante ejecución", 0)
        end
    end
end)
print("✓ Ejecutando código protegido...")
local success, err = pcall(funcion_cargada)
funcion_cargada = nil
if not success then
    warn("Error durante ejecución:", err)
end
proteccion_activa = false
if #advertencias > 0 then
    print("\n⚠ ADVERTENCIAS DURANTE EJECUCIÓN:")
    for i, adv in ipairs(advertencias) do
        print(i .. ".", adv)
    end
else
    print("✓ Ejecución completada sin advertencias")
end
