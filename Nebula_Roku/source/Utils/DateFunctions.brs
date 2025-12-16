' Valida si la fecha enviada corresponde a la fecha de hoy. La fecha se deve mandar en segundos.
function IsToday(timeSeconds as Integer) as Boolean
    ' Objeto de fecha actual
    currentDate = CreateObject("roDateTime")
    
    ' Objeto de fecha basado en el tiempo recibido
    testDate = CreateObject("roDateTime")
    testDate.FromSeconds(timeSeconds)
    
    ' Compara año, mes y día
    if currentDate.GetYear() = testDate.GetYear() and currentDate.GetMonth() = testDate.GetMonth() and currentDate.GetDayOfMonth() = testDate.GetDayOfMonth() then
        return true
    else
        return false
    end if
end function

' Se encarga de formatear la fehca recibida por paramentro. Los formatos validos actualmente son: 
' HH:mm, dd/MM/yyyy, dd/MM/yy HH:mm, dd MMMM yyyy hh:mm con sus respectivos cambios por idioma.
' Actualmente, el metodo espera ya el formato por idioma ya que, internamente, el no distingue 
' el idioma en el que esta la aplicacion
function dateConverter(dateTime, format as string) as string
    if format = "" then return ""

    if format = "HH:mm a" then
        hours = dateTime.GetHours()
        minutes = dateTime.GetMinutes()

        hoursStr = "00"
        meridian = "a.m."

        if hours <> invalid then
            if hours >= 0 and hours < 12 then
                hoursStr = __completeDigit(hours)
                meridian = "a.m."
            else if hours = 12 then
                hoursStr = __completeDigit(hours)
                meridian = "p.m."
            else
                hoursStr = __completeDigit(hours - 12)
                meridian = "p.m."
            end if 
        end if

        return hoursStr + ":" + __completeDigit(minutes) + " " + meridian

    else if format = "HH:mm" then
        hours = dateTime.GetHours()
        minutes = dateTime.GetMinutes()

        return __completeDigit(hours) + ":" + __completeDigit(minutes)

    else if format = "MM/dd/yyyy" then
        year = dateTime.GetYear()
        month = dateTime.GetMonth()
        days = dateTime.GetDayOfMonth()
    
        return __completeDigit(month) + "/" + __completeDigit(days) + "/" + year.ToStr()

    else if format = "dd/MM/yyyy" then
        year = dateTime.GetYear()
        month = dateTime.GetMonth()
        days = dateTime.GetDayOfMonth()
        
        return  __completeDigit(days) + "/" + __completeDigit(month) + "/" + year.ToStr()

    else if format = "MM/dd/yy hh:mm a" then
        year = dateTime.GetYear()
        month = dateTime.GetMonth()
        days = dateTime.GetDayOfMonth()
        hours = dateTime.GetHours()
        minutes = dateTime.GetMinutes()

        hoursStr = "00"
        meridian = "a.m."

        if hours <> invalid then
            if hours >= 0 and hours < 12 then
                hoursStr = __completeDigit(hours)
                meridian = "a.m."
            else if hours = 12 then
                hoursStr = __completeDigit(hours)
                meridian = "p.m."
            else
                hoursStr = __completeDigit(hours - 12)
                meridian = "p.m."
            end if 
        end if

        return __completeDigit(month) + "/" + __completeDigit(days) + "/" + year.ToStr() + " " + hoursStr + ":" + __completeDigit(minutes) + " " + meridian

    else if format = "dd/MM/yy HH:mm" then
        year = dateTime.GetYear()
        month = dateTime.GetMonth()
        days = dateTime.GetDayOfMonth()
        hours = dateTime.GetHours()
        minutes = dateTime.GetMinutes()

        return  __completeDigit(days) + "/" + __completeDigit(month) + "/" + year.ToStr() + " " + __completeDigit(hours) + ":" + __completeDigit(minutes)

    else if format = "dd MMMM yyyy hh:mm a" then
        year = dateTime.GetYear()
        month = dateTime.GetMonth()
        days = dateTime.GetDayOfMonth()
        hours = dateTime.GetHours()
        minutes = dateTime.GetMinutes()

        hoursStr = "00"
        meridian = "a.m."

        if hours <> invalid then
            if hours >= 0 and hours < 12 then
                hoursStr = __completeDigit(hours)
                meridian = "a.m."
            else if hours = 12 then
                hoursStr = __completeDigit(hours)
                meridian = "p.m."
            else
                hoursStr = __completeDigit(hours - 12)
                meridian = "p.m."
            end if 
        end if

        return __completeDigit(days) + " " + __getMonth(month) + " " + year.ToStr() + " " + hours.ToStr() + ":" + __completeDigit(minutes) + " " + meridian

    else if format = "dd MMMM yyyy hh:mm" then
        year = dateTime.GetYear()
        month = dateTime.GetMonth()
        days = dateTime.GetDayOfMonth()
        hours = dateTime.GetHours()
        minutes = dateTime.GetMinutes()

        return __completeDigit(days) + " " + __getMonth(month) + " " + year.ToStr() + " " + __completeDigit(hours) + ":" + __completeDigit(minutes)
    
    else if format = "log" then
        month = dateTime.GetMonth()
        days = dateTime.GetDayOfMonth()
        hours = dateTime.GetHours()
        minutes = dateTime.GetMinutes()
        seconds = dateTime.GetSeconds()
        milliseconds = dateTime.GetMilliseconds()

        return  __completeDigit(month) + "-" + __completeDigit(days) + " " + __completeDigit(hours) + ":" + __completeDigit(minutes) + ":" + __completeDigit(seconds) + "." + __completeDigit(milliseconds, 3)
    end if
    return ""
end function

' Metodo privado. Devuelve el nombre del mes de una fecha
function __getMonth(monthNumber) as string
    if monthNumber = 1 then 
        return "january"
    else if monthNumber = 2 then
        return "february"
    else if monthNumber = 3 then
        return "march"
    else if monthNumber = 4 then
        return "april"
    else if monthNumber = 5 then
        return "may"
    else if monthNumber = 6 then
        return "june"
    else if monthNumber = 7 then
        return "july"
    else if monthNumber = 8 then
        return "august"
    else if monthNumber = 9 then
        return "september"
    else if monthNumber = 10 then 
        return "october"
    else if monthNumber = 11 then 
        return "november"
    else if monthNumber = 12 then 
        return "december"
    end if 

    return ""
end function

' Metodo privado. Completa el numero para que tenga el formato XX, 
' y lo devuelve en formato string 
function __completeDigit(value, numberOfDigits = 2) as string
    if (value = invalid) then value = 0

    strValue = value.toStr()
    digitsToPad = numberOfDigits - len(strValue)

    if digitsToPad > 0 then
        padding = string(digitsToPad, "0")
        return padding + strValue
    else
        return strValue
    end if
end function
