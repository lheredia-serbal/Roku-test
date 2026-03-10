' Convierte la lógica de validateImagesUrl de TypeScript a BrightScript.
sub validateImagesUrl(state as Object)
  if state = invalid then return
  if state._resources = invalid then return

  checks = []

  for each item in state._resources
    if shouldValidateImageUrl(item) then
      checks.push(item)
    end if
  end for

  for each item in checks
    ' En Roku con errores TLS (-60), validar existencia por HTTPS puede ser no confiable.
    ' Si la política declara TLS_ERROR + USE_HTTP, aplicamos fallback directo a HTTP.
    if item <> invalid and hasUseHttpAction(item) then
      if item.primary <> invalid then
        item.primary = replaceHttpsScheme(item.primary)
      end if

      if item.secondary <> invalid then
        item.secondary = replaceHttpsScheme(item.secondary)
      end if
    end if
  end for
end sub

function shouldValidateImageUrl(item as Object) as Boolean
  if item = invalid then return false

  hasPrimaryToCheck = false
  if getHealthCheckPrimary(item) <> "" then
    hasPrimaryToCheck = true
  else if item.primary <> invalid and item.primary <> "" then
    hasPrimaryToCheck = true
  end if

  if hasPrimaryToCheck = false then return false
  if item.on_failure = invalid then return false
  if item.on_failure.actions = invalid then return false
  if item.on_failure.actions.Count() = 0 then return false

  for each actionInfo in item.on_failure.actions
    if LCase(actionInfo.when) = "tls_error" and LCase(actionInfo.action) = "use_http" then
      return true
    end if
  end for

  return false
end function

function hasUseHttpAction(item as Object) as Boolean
  if item = invalid then return false
  if item.on_failure = invalid then return false
  if item.on_failure.actions = invalid then return false

  for each actionInfo in item.on_failure.actions
    if LCase(actionInfo.action) = "use_http" then
      return true
    end if
  end for

  return false
end function

function replaceHttpsScheme(url as String) as String
  if Left(url, 5) = "https" then
    return "http" + Mid(url, 6)
  end if

  return url
end function

function getHealthCheckPrimary(item as Object) as String
  if item = invalid then return ""
  if item.health_check = invalid then return ""
  if type(item.health_check) <> "roAssociativeArray" then return ""
  if item.health_check.target = invalid then return ""
  if item.health_check.target.primary = invalid then return ""
  return item.health_check.target.primary
end function

function getHealthCheckSecondary(item as Object) as String
  if item = invalid then return ""
  if item.health_check = invalid then return ""
  if type(item.health_check) <> "roAssociativeArray" then return ""
  if item.health_check.target = invalid then return ""
  if item.health_check.target.secondary = invalid then return ""
  return item.health_check.target.secondary
end function

' Equivalente BrightScript de:
' private testImageUrl(item): Promise<{ item, result }>
' 1) Prueba health_check.target.primary
' 2) Si falla, prueba health_check.target.secondary (si existe)
' 3) Agrega ?t=<timestamp> para evitar cache
function testImageUrl(item as Object) as Object
  result = { item: item, result: false }
  if item = invalid then return result
  primaryUrl = getHealthCheckPrimary(item)
  if primaryUrl = "" and item.primary <> invalid then primaryUrl = item.primary

  secondaryUrl = getHealthCheckSecondary(item)
  if secondaryUrl = "" and item.secondary <> invalid then secondaryUrl = item.secondary

  if primaryUrl = "" then return result

  if imageUrlExists(addCacheBuster(primaryUrl)) or imageUrlExists(primaryUrl) then
    result.result = true
    return result
  end if

  if secondaryUrl <> invalid and secondaryUrl <> "" then
    if imageUrlExists(addCacheBuster(secondaryUrl)) or imageUrlExists(secondaryUrl) then
      result.result = true
      return result
    end if
  end if

  return result
end function

function addCacheBuster(url as String) as String
  if url = invalid or url = "" then return ""

  now = CreateObject("roDateTime")
  now.Mark()
  ts = now.AsSeconds().toStr()

  if Instr(1, url, "?") > 0 then
    return url + "&t=" + ts
  end if

  return url + "?t=" + ts
end function

' Validación rápida de existencia de imagen por URL (sin componentes).
function imageUrlExists(url as String, timeoutMs = 3000 as Integer) as Boolean
  if url = invalid or url = "" then return false

  ' Estrategia 1: GET mínimo (Range bytes=0-0) para validar existencia sin bajar todo.
  status = __requestUrlStatus(url, timeoutMs)
  if __isSuccessStatus(status) then return true

  ' Estrategia 2: algunos servidores/CDN reaccionan distinto a ToFile vs ToString.
  statusFile = __requestUrlStatusToFile(url, timeoutMs)
  if __isSuccessStatus(statusFile) then return true

  ' Estrategia 3: fallback a HTTP para entornos Roku con TLS -60.
  if status = -60 or statusFile = -60 then
    fallbackUrl = replaceHttpsScheme(url)
    if fallbackUrl <> url then
      fallbackStatus = __requestUrlStatus(fallbackUrl, timeoutMs)
      if __isSuccessStatus(fallbackStatus) then return true

      fallbackStatusFile = __requestUrlStatusToFile(fallbackUrl, timeoutMs)
      if __isSuccessStatus(fallbackStatusFile) then return true
    end if
  end if

  return false
end function

function __requestUrlStatus(url as String, timeoutMs as Integer) as Integer
  transfer = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  if transfer = invalid or port = invalid then return -1

  transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  transfer.InitClientCertificates()
  transfer.SetPort(port)
  transfer.RetainBodyOnError(true)
  transfer.AddHeader("Accept", "image/*,*/*")
  transfer.AddHeader("Range", "bytes=0-0")
  transfer.SetURL(url)

  if transfer.AsyncGetToString() then
    event = wait(timeoutMs, port)
    if event <> invalid and type(event) = "roUrlEvent" then
      return event.GetResponseCode()
    end if
  end if

  return -1
end function


function __requestUrlStatusToFile(url as String, timeoutMs as Integer) as Integer
  transfer = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  if transfer = invalid or port = invalid then return -1

  transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  transfer.InitClientCertificates()
  transfer.SetPort(port)
  transfer.RetainBodyOnError(true)
  transfer.AddHeader("Accept", "image/*,*/*")
  transfer.SetURL(url)

  now = CreateObject("roDateTime")
  now.Mark()
  targetFile = "tmp:/img-probe-" + now.AsSeconds().toStr() + ".bin"

  if transfer.AsyncGetToFile(targetFile) then
    event = wait(timeoutMs, port)
    if event <> invalid and type(event) = "roUrlEvent" then
      return event.GetResponseCode()
    end if
  end if

  return -1
end function

function __isSuccessStatus(code as Integer) as Boolean
  return (code >= 200 and code < 400) or code = 206
end function
