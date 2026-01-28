function  getAppCode() As String
    return "NexosRoku"
End function 

function getUrl() As String
    return "https://nexos-api.qvixprimary.com/api"
End function 

' Función para obtener los colores Principales
function getSpecialColors()
    return {
        PRIMARY: "#FF0061",
        SECONDARY: "#ffb522",
        PROGRESS: "#ff4700",
        PLAYER_TIMEBAR_NOT_FOCUCED: "#FF0061",
        PLAYER_TIMEBAR_NOT_FOCUCED: "#bb4c76",
    }
end function

'*************************************************************
'  EN ESTE ARCHIVO SE DEFINE LA CONFIGURACION POR CLIENTE
'*************************************************************