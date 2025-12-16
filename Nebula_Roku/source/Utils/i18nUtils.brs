' ===== i18nUtils.brs =====
' Funciones de idioma + helpers para cargar JSON de traducciones

' Detecta el idioma del dispositivo y lo normaliza a es/en/pt
function getAppLanguage() as string
    di = CreateObject("roDeviceInfo")
    locale = di.GetCurrentLocale()  ' ej: "es_AR", "en_US", "pt_BR"

    if locale = invalid then return "en"

    parts = locale.Split("_")
    lang = parts[0]  ' "es", "en", "pt", etc.

    supported = ["es", "en", "pt"]
    for each s in supported
        if LCase(s) = LCase(lang) then
            return s
        end if
    end for

    return "en"
end function

' Carga un archivo JSON desde pkg:/ y lo parsea a un roAssociativeArray
function loadJsonFile(path as string) as object
    emptyDict = CreateObject("roAssociativeArray")

    text = invalid
    try
        text = ReadAsciiFile(path)
    catch e
        print "i18n: error leyendo archivo JSON: "; path; " → "; e.message
        return emptyDict
    end try

    if text = invalid then
        print "i18n: archivo de traducción no encontrado o vacío en "; path
        return emptyDict
    end if

    dict = invalid
    try
        dict = ParseJson(text)
    catch e
        print "i18n: error parseando JSON en "; path; " → "; e.message
        return emptyDict
    end try

    if Type(dict) <> "roAssociativeArray" then
        print "i18n: estructura JSON inválida en "; path; " (se esperaba roAssociativeArray)"
        return emptyDict
    end if

    return dict
end function

' Carga traducciones para un idioma específico desde /locale/<lang>.json
function loadTranslationsForLang(lang as string) as object
    path = "pkg:/source/locale/" + lang + ".json"
    return loadJsonFile(path)
end function

' Traduce usando el nodo i18n y una clave (soporta "a.b.c")
function i18n_t(i18nNode as Object, key as string) as string
    if i18nNode = invalid then return key

   primary = i18n_lookupValue(i18nNode.dict, key)
    if primary <> invalid then return primary

    fallbackDict = invalid
    if GetInterface(i18nNode, "ifSGNodeField") <> invalid and i18nNode.hasfield("fallbackDict") then
        fallbackDict = i18nNode.fallbackDict
    end if

    fallback = i18n_lookupValue(fallbackDict, key)
    if fallback <> invalid then return fallback

    return key
end function

' Busca una clave en un diccionario, soportando paths tipo "a.b.c". Devuelve invalid si no existe.
function i18n_lookupValue(dict as Object, key as string) as dynamic
    if Type(dict) <> "roAssociativeArray" then return invalid

    if key.Instr(".") = -1 then
        if dict.doesexist(key) and Type(dict[key]) = "roString" then
            return dict[key]
        else
            return invalid
        end if
    end if

    parts = key.Split(".")
    node = dict

    for each part in parts
        if Type(node) <> "roAssociativeArray" then return invalid
        if not node.doesexist(part) then return invalid
        node = node[part]
    end for

    if Type(node) = "roString" then
        return node
    end if

    return invalid
end function