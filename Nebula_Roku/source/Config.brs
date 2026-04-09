function  getAppCode() As String
    return "NebulaRoku"
End function 

function getCdnConfigUrls() As Object
    return [
        "https://d1gbojyyzaqxpn.cloudfront.net/v1/nebulatest.json",
        "https://qvixstatic-g5h3fha4cnh9chff.z03.azurefd.net/static-content/v1/nebulatest.json"
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