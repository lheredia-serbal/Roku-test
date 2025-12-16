sub init()
    m.supportedLangs = { es: true, en: true, pt: true }
    m.top.language = getAppLanguage()
     m.fallbackDict = CreateObject("roAssociativeArray")
    setCurrentDict()
end sub

sub languageChanged()
    setCurrentDict()
end sub

sub setCurrentDict()
    print "Busca los archivos de traducción"
    lang = m.top.language

    if not m.supportedLangs.doesexist(lang) then
        print "i18n: idioma no soportado: "; lang; " → fallback a en"
        lang = "en"
    end if

    m.fallbackDict = loadTranslationsForLang("en")
    if Type(m.fallbackDict) <> "roAssociativeArray" then
        print "i18n: traducción base 'en' inválida, usando diccionario vacío"
        m.fallbackDict = CreateObject("roAssociativeArray")
    end if

    dict = loadTranslationsForLang(lang)
    if Type(dict) <> "roAssociativeArray" then
        print "i18n: no se pudo cargar JSON para "; lang; " → fallback a en"
        dict = m.fallbackDict
    else if dict.Count() = 0 and lang <> "en" then
        print "i18n: diccionario vacío para "; lang; " → fallback a en"
        dict = m.fallbackDict
    end if

    m.currentDict = dict
    m.top.dict    = dict  ' 👈 esto es lo que van a leer otros nodos
     m.top.fallbackDict = m.fallbackDict
end sub
' Devuelve la traducción de una clave (soporta paths tipo "content.menuComponent.exit")
function t(key as string) as string
    if m.currentDict = invalid then return key

    ' Si la clave no tiene ".", intentamos acceso directo
    if key.Instr(".") = -1 then
        if m.currentDict.doesexist(key) and Type(m.currentDict[key]) = "roString" then
            return m.currentDict[key]
        else
            return key
        end if
    end if

    ' Navegar JSON anidado con claves separadas por "."
    parts = key.Split(".")
    node = m.currentDict

    for each part in parts
        if Type(node) <> "roAssociativeArray" then return key
        if not node.doesexist(part) then return key
        node = node[part]
    end for

    if Type(node) = "roString" then
        return node
    else
        return key
    end if
end function
