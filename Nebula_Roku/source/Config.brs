'*************************************************************
'*************************************************************
'*************************************************************
'
'  EN ESTE ARCHIVO SE DEFINE LA CONFIGURACION POR CLIENTE
'
'*************************************************************
'*************************************************************
'*************************************************************

function  getAppCode() As String
    return "NebulaRoku"
End function 
 
function  getValidateChangeStorage() As boolean
    '*************************************************************
    '
    '                   ¡¡¡¡¡IMPORTANTE!!!!!
    '
    ' Este metodo solo debe devolver True para el caso las 
    ' aplciaciones que tuvieron problemas con el estorage 
    '*************************************************************
    return false
End function

function getCdnConfigUrls() As Object
    return [
        "https://cdndev.qvixprimary.com/v1/nebulatest.json",
        "https://cdndev.qvixsecondary.com/v1/nebulatest.json"
    ]
end function

' Función para obtener los colores Principales
function getSpecialColors()
    return {
        PRIMARY: "#21acfa",
        SECONDARY: "#ffb522",
    }
end function
