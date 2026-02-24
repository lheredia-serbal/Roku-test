function  getAppCode() As String
    return "NebulaRoku"
End function 

function getCdnConfigUrls() As Object
    return [
        "https://cdndev.qvixprimary.com/v1/nebuladev.json",
        "https://cdndev.qvixsecondary.com/v1/nebuladev.json"
    ]
end function

function getSimulateCdnFirstFailure() As Boolean
    return false
end function

' Función para obtener los colores Principales
function getSpecialColors()
    return {
        PRIMARY: "#21acfa",
        SECONDARY: "#ffb522",
    }
end function

'*************************************************************
'  EN ESTE ARCHIVO SE DEFINE LA CONFIGURACION POR CLIENTE
'*************************************************************