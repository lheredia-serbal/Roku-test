function __dtClone(dt as object) as object
  if dt = invalid then return invalid
  c = CreateObject("roDateTime")
  c.FromSeconds(dt.AsSeconds())
  return c
end function

' Obtiene una fecha agregandole segundos
' @param dt: Fecha a modificar
' @param deltaSec: Segundos a agregar
function dtCloneAddSeconds(dt as object, deltaSec as integer) as object
  if dt = invalid then return invalid

  c = CreateObject("roDateTime")
  c.FromSeconds(dt.AsSeconds() + deltaSec)
  return c
end function

' Compara 2 fechas de acuerdo a la diferencia de segundos
' @param a Primera fecha
' @param b Segunda fecha
function dtIsBefore(a as object, b as object) as boolean
  if a = invalid or b = invalid then return false
  return a.AsSeconds() < b.AsSeconds()
end function

function dtIsSame(a as object, b as object) as boolean
  if a = invalid or b = invalid then return false
  return a.AsSeconds() = b.AsSeconds()
end function

function dtDiffSeconds(a as object, b as object) as integer
  if a = invalid or b = invalid then return 0
  return a.AsSeconds() - b.AsSeconds()
end function

' Le da formato al tiempo a mostrar (puede ser negativo)
' @param timeInSec: segundos (integer/float). Si es 0/invalid devuelve ""
function formatTime(timeInSec as dynamic) as string
  if timeInSec = invalid then return ""
  if timeInSec = 0 then return ""

  isNegative = (timeInSec < 0)
  absTime = Abs(Int(timeInSec)) ' trunc similar a floor para positivos

  hours = Int(absTime / 3600)
  minutes = Int((absTime mod 3600) / 60)
  seconds = absTime mod 60

  formattedTime = ""
  if hours > 0 then
    ' zeroPad(hours, 1) => si hours=3 => "3", si hours=12 => "12"
    formattedTime = __zeroPad(hours, 1) + ":"
  end if

  formattedTime = formattedTime + __zeroPad(minutes, 2) + ":" + __zeroPad(seconds, 2)

  if isNegative then
    return "- " + formattedTime
  else
    return formattedTime
  end if
end function

function __zeroPad(num as integer, zeros = 2 as integer) as string
  s = num.toStr()
  while Len(s) < zeros
    s = "0" + s
  end while
  return s
end function

function dtIsAfter(a as object, b as object) as boolean
  if a = invalid or b = invalid then return false
  return a.AsSeconds() > b.AsSeconds()
end function

function dtCloneAddMs(dt as object, deltaMs as integer) as object
  c = __dtClone(dt)
  if c = invalid then return invalid
  ' roDateTime opera en segundos, convertimos ms->sec (redondeo hacia abajo)
  sec = Int(deltaMs / 1000.0)
  c.AddSeconds(sec)
  return c
end function