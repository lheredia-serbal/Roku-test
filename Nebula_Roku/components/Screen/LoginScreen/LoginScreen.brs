' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.top.finished = false 
  m.mainContainer = m.top.findNode("mainContainer")
  m.credentialsContainer = m.top.findNode("credentialsContainer")
  m.userField = m.top.findNode("userField")
  m.passwordField = m.top.findNode("passwordField")
  m.passwordLabel = m.top.findNode("passwordLabel")
  m.nextButton = m.top.findNode("nextButton")
  m.prevButton = m.top.findNode("prevButton")
  m.buttonContainer = m.top.findNode("buttonContainer")
  m.keyboard = m.top.findNode("keyboard")
  m.logo = m.top.findNode("logo")
  m.email = m.top.findNode("email")

  m.loginMethodTitle = m.top.findNode("loginMethodTitle")
  m.loginMethodSwitch = m.top.findNode("loginMethodSwitch") 
  m.loginMethodSwitchSelected = m.top.findNode("loginMethodSwitchSelected")
  m.loginMethodPhone = m.top.findNode("loginMethodPhone")
  m.loginMethodKeyboard = m.top.findNode("loginMethodKeyboard")
  m.qrContainer = m.top.findNode("qrContainer")
  m.phoneInstructionsTitle = m.top.findNode("phoneInstructionsTitle")
  m.step1Badge = m.top.findNode("step1Badge")
  m.step1Text = m.top.findNode("step1Text")
  m.qrShortUrlLabel = m.top.findNode("qrShortUrlLabel")
  m.step2Badge = m.top.findNode("step2Badge")
  m.step2Text = m.top.findNode("step2Text")
  m.activationCodeLabel = m.top.findNode("activationCodeLabel")
  m.step3Badge = m.top.findNode("step3Badge")
  m.step3Text = m.top.findNode("step3Text")
  m.qrCodeBackground = m.top.findNode("qrCodeBackground")
  m.qrCodePoster = m.top.findNode("qrCodePoster")
  m.validatePhoneButton = m.top.findNode("validatePhoneButton")

  m.scaleInfo = m.global.scaleInfo
  m.isPhoneQrEnabled = false

  m.scaleInfo = m.global.scaleInfo

  m.keyboard.showTextEditBox = false
  m.keyboard.textEditBox.maxTextLength = 255
  
  m.passwordLabel.opacity = 0.0
  m.passwordField.opacity = 0.0

  m.userField.maxTextLength = 255
  m.passwordField.maxTextLength = 255

  m.userField.hintTextColor = m.global.colors.LIGHT_GRAY
  m.passwordField.hintTextColor = m.global.colors.LIGHT_GRAY

  m.loginMethodTitle.width = scaleValue(900, m.scaleInfo)
  m.loginMethodTitle.height = scaleValue(55, m.scaleInfo)
  m.loginMethodSwitch.width = scaleValue(500, m.scaleInfo)
  m.loginMethodSwitch.height = scaleValue(72, m.scaleInfo)
  m.loginMethodSwitchSelected.width = scaleValue(250, m.scaleInfo)
  m.loginMethodSwitchSelected.height = scaleValue(60, m.scaleInfo)
  m.loginMethodSwitchSelected.translation = scaleSize([6, 6], m.scaleInfo)
  m.loginMethodPhone.width = scaleValue(250, m.scaleInfo)
  m.loginMethodPhone.height = scaleValue(72, m.scaleInfo)
  m.loginMethodPhone.translation = [0, 0]
  m.loginMethodKeyboard.width = scaleValue(250, m.scaleInfo)
  m.loginMethodKeyboard.height = scaleValue(72, m.scaleInfo)
  m.loginMethodKeyboard.translation = scaleSize([250, 0], m.scaleInfo)
  ' Centra horizontalmente el switch respecto al ancho del formulario principal
  m.loginMethodSwitch.translation = [int((scaleValue(910, m.scaleInfo) - m.loginMethodSwitch.width) / 2), 0]

  m.mainContainer.translation = scaleSize([180, 70], m.scaleInfo)
  m.email.width = scaleValue(300, m.scaleInfo)
  m.userField.width = scaleValue(910, m.scaleInfo)
  m.passwordLabel.width = scaleValue(300, m.scaleInfo)
  m.passwordField.width = scaleValue(910, m.scaleInfo)
  m.keyboard.translation = scaleSize([-15,0], m.scaleInfo)
  m.logo.width = scaleValue(200, m.scaleInfo)
  m.logo.height = scaleValue(100, m.scaleInfo)

  m.prevButton.size = scaleSize([150, 40], m.scaleInfo)
  m.nextButton.size = scaleSize([150, 40], m.scaleInfo)

  m.qrContainer.width = scaleValue(1600, m.scaleInfo)
  m.qrContainer.height = scaleValue(760, m.scaleInfo)
  m.phoneInstructionsTitle.width = scaleValue(1120, m.scaleInfo)
  m.phoneInstructionsTitle.translation = scaleSize([0, 0], m.scaleInfo)

  m.step1Badge.width = scaleValue(56, m.scaleInfo)
  m.step1Badge.height = scaleValue(56, m.scaleInfo)
  m.step1Badge.translation = scaleSize([0, 50], m.scaleInfo)
  m.step1Text.width = scaleValue(980, m.scaleInfo)
  m.step1Text.translation = scaleSize([78, 50], m.scaleInfo)
  m.qrShortUrlLabel.width = scaleValue(980, m.scaleInfo)
  m.qrShortUrlLabel.translation = scaleSize([78, 176], m.scaleInfo)

  m.step2Badge.width = scaleValue(56, m.scaleInfo)
  m.step2Badge.height = scaleValue(56, m.scaleInfo)
  m.step2Badge.translation = scaleSize([0, 120], m.scaleInfo)
  m.step2Text.width = scaleValue(980, m.scaleInfo)
  m.step2Text.translation = scaleSize([78, 120], m.scaleInfo)
  m.activationCodeLabel.width = scaleValue(980, m.scaleInfo)
  m.activationCodeLabel.translation = scaleSize([78, 150], m.scaleInfo)

  m.step3Badge.width = scaleValue(56, m.scaleInfo)
  m.step3Badge.height = scaleValue(56, m.scaleInfo)
  m.step3Badge.translation = scaleSize([0, 190], m.scaleInfo)
  m.step3Text.width = scaleValue(980, m.scaleInfo)
  m.step3Text.translation = scaleSize([78, 190], m.scaleInfo)

  m.qrCodeBackground.width = scaleValue(250, m.scaleInfo)
  m.qrCodeBackground.height = scaleValue(250, m.scaleInfo)
  m.qrCodeBackground.translation = scaleSize([850, 40], m.scaleInfo)
  m.qrCodePoster.width = scaleValue(250, m.scaleInfo)
  m.qrCodePoster.height = scaleValue(250, m.scaleInfo)
  m.qrCodePoster.translation = scaleSize([25, 25], m.scaleInfo)

  m.validatePhoneButton.size = scaleSize([220, 62], m.scaleInfo)
  m.validatePhoneButton.translation = scaleSize([400, 350], m.scaleInfo)

  ' Escucha cambios de foco del método Teléfono para alternar visibilidad del formulario
  if m.loginMethodPhone <> invalid then m.loginMethodPhone.observeField("hasFocus", "onLoginMethodFocusChanged")
  ' Escucha cambios de foco del método Teclado para restaurar visibilidad del formulario
  if m.loginMethodKeyboard <> invalid then m.loginMethodKeyboard.observeField("hasFocus", "onLoginMethodFocusChanged")

  if m.global <> invalid then
    m.global.observeField("activeApiUrl", "onActiveApiUrlChanged")
  end if
end sub

sub onLoginMethodFocusChanged()
  ' Evita errores si los contenedores aún no están disponibles
  if m.credentialsContainer = invalid or m.qrContainer = invalid then return

  ' Determina si la opción Teléfono es la que actualmente tiene foco
  isPhoneFocused = m.loginMethodPhone <> invalid and m.loginMethodPhone.isInFocusChain()
  ' Oculta credenciales cuando Teléfono está enfocado y las muestra en cualquier otro caso
  m.credentialsContainer.visible = not isPhoneFocused
  ' Dibuja el bloque visual de pasos/QR únicamente cuando Teléfono está enfocado y hay datos válidos
  m.qrContainer.visible = true ' = (isPhoneFocused and m.isPhoneQrEnabled)
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as String, press as Boolean) as Boolean
  if m.top.loading.visible <> false and key <> KeyButtons().BACK then 
    return true
  end if

  handled = false

  if m.keyboard.isInFocusChain() and key = KeyButtons().UP then
    if not press then 
      m.nextButton.setFocus(true)
    end if
    handled = true
  else if m.prevButton.isInFocusChain() and key = KeyButtons().RIGHT then
    if not press then 
      m.nextButton.setFocus(true)
    end if
    handled = true
  else if m.prevButton.isInFocusChain() and key = KeyButtons().DOWN then
    if not press then 
      __focusKeyboard()
    end if 
    handled = true
  else if m.prevButton.isInFocusChain() and key = KeyButtons().OK then
    if not press then __prevButtonPressed()
    handled = true
  else if m.nextButton.isInFocusChain() and key = KeyButtons().LEFT then
    if not press and m.inputFocus = "password" then  
      m.prevButton.setFocus(true)
    end if
    handled = true
  else if m.nextButton.isInFocusChain() and key = KeyButtons().DOWN then
    __focusKeyboard()
    handled = true
  else if m.nextButton.isInFocusChain() and key = KeyButtons().OK then
    if not press then __nextButtonPressed()
    handled = true
  end if

  return handled
end function

' Inicializa el foco del componente seteando los valores necesarios
sub initFocus()
  if m.top.onFocus then
    __applyTranslations()
    m.sendLoginPost = false
    m.inputFocus = "user"
    m.prevButton.disable = true

    m.keyboard.unobserveField("textEditBox")

    width = m.scaleInfo.width

    m.buttonContainer.translation = [((width - scaleValue(380, m.scaleInfo)) / 2), 0]
    m.logo.translation = [(width - scaleValue(280, m.scaleInfo)), scaleValue(30, m.scaleInfo)]

    ' Sincroniza las variables remotas para mostrar/ocultar el bloque QR
    __loadQrLoginConfig()
    ' Ubica el módulo de pasos/QR debajo del switch para el flujo por teléfono
    m.qrContainer.translation = [scaleValue(110, m.scaleInfo), scaleValue(250, m.scaleInfo)]
    
    m.keyboard.ObserveField("textEditBox", "onTextBoxManagment")
    ' Al iniciar, el foco debe quedar en la opción de login por teléfono
    m.loginMethodPhone.setFocus(true)
    ' Aplica de inmediato la visibilidad del formulario según el foco inicial
    onLoginMethodFocusChanged()
    
  end if
end sub 

' Procesa la respuesta al tratar de loguear al usuario a traves de credenciales
sub onLoginResponse()

  if m.apiRequestManager = invalid then
    user = m.userField.text
    password = m.passwordField.text
    __login(user, password)
    return
  else 
    if validateStatusCode(m.apiRequestManager.statusCode) then

      removePendingAction(m.apiRequestManager.requestId)

      actionLog = getActionLog({ actionCode: ActionLogCode().LOGIN_BY_CREDENTIALS })
      __saveActionLog(actionLog)

      resp = ParseJson(m.apiRequestManager.response)
      
      addAndSetFields(m.global, {device: resp.device, organization: resp.organization, contact: resp.contact, variables: resp.variables} )
      
      saveNextUpdateVariables()

      SetDevice(resp.device)
      saveTokens(resp)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      m.keyboard.unobserveField("textEditBox")
      m.sendLoginPost = false
      m.top.finished = true
    else 
      if m.apiRequestManager.serverError then
        statusCode = m.apiRequestManager.statusCode
        setCdnErrorCodeFromStatus(statusCode, ApiType().CLIENTS_API_URL)
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)
        if m.resultCodes = invalid then m.resultCodes = getResultCodes()
        m.top.loading.visible = false

        error = ParseJson(m.apiRequestManager.errorResponse)

        errorAPI = ""

        if error.code = m.resultCodes.UNAUTHORIZED then
          errorAPI = i18n_t(m.global.i18n, "loginPage.errorForm.unAuthorized")
        else if error.code = m.resultCodes.NOT_CONFIRMED then
          errorAPI = i18n_t(m.global.i18n, "loginPage.errorForm.notConfirmed")
        else if error.code = m.resultCodes.NOT_ACTIVATED then
          errorAPI = i18n_t(m.global.i18n, "loginPage.errorForm.notActivated")
        else if error.code = m.resultCodes.REQUESTTIMEOUT then
          errorAPI = i18n_t(m.global.i18n, "shared.errorComponent.connection")
        else 
          errorAPI = i18n_t(m.global.i18n, "loginPage.errorForm.unhandled")
        end if
          
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
        __showDialog(errorAPI)
      end if
    end if 
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  end if
end sub

' Notifica que finalizo las tareas de la pantalla
sub onFinished()
  if m.top.finished then 
    m.sendLoginPost = false
    m.inputFocus = "user"
    m.prevButton.disable = true

    m.keyboard.text = ""
    m.inputFocus = "user"
    m.userField.text = invalid
    m.passwordField.text = invalid
    m.passwordLabel.opacity = 0.0
    m.passwordField.opacity = 0.0
    m.prevButton.disable = true
  end if 
end sub 

' Procesa el evento de cierre del dialogo y realiza la accion pertinente
sub onDialogClosed(_event)
  ' Eliminar el diálogo cuando el usuario cierra la ventana
  m.dialog.visible = false
  m.dialog.unobserveField("buttonSelected")
  m.top.removeChild(m.dialog)
  m.dialog = invalid
  m.sendLoginPost = false
  __focusKeyboard()
end sub

' Administrar el uso de los Inputs anidando el input posicionado en pantalla con el que usa internamente el teclado.
sub onTextBoxManagment()
  if m.inputFocus = "user" then 
    m.userField.cursorPosition = m.keyboard.textEditBox.cursorPosition
    m.userField.text = m.keyboard.textEditBox.text
    m.userField.active = m.keyboard.textEditBox.active
  else
    m.passwordField.cursorPosition = m.keyboard.textEditBox.cursorPosition
    m.passwordField.text = m.keyboard.textEditBox.text
    m.passwordField.active = m.keyboard.textEditBox.active
  end if
end sub

' Aplicar las traducciones en el componente
sub __applyTranslations()
    if m.global.i18n = invalid then return

    m.email.text = i18n_t(m.global.i18n, "loginPage.titleUser")
    m.loginMethodTitle.text = i18n_t(m.global.i18n, "loginPage.titleQR")
    m.loginMethodPhone.text = i18n_t(m.global.i18n, "loginPage.optionPhone")
    m.loginMethodKeyboard.text = i18n_t(m.global.i18n, "loginPage.optionKeyboard")
    m.passwordLabel.text = i18n_t(m.global.i18n, "loginPage.password")
    m.prevButton.text = i18n_t(m.global.i18n, "button.previous")
    m.nextButton.text = i18n_t(m.global.i18n, "button.next")
    m.userField.hintText = i18n_t(m.global.i18n, "loginPage.enterYourUser")
    m.passwordField.hintText = i18n_t(m.global.i18n, "loginPage.enterYourPassword")

    m.phoneInstructionsTitle.text = i18n_t(m.global.i18n, "loginPage.qrStepsTitle")
    m.step1Badge.text = "1"
    m.step1Badge.color = "#FFFFFFFF"
    m.step1Text.text = i18n_t(m.global.i18n, "loginPage.qrStep1Description")
    m.step2Badge.text = "2"
    m.step2Badge.color = "#FFFFFFFF"
    m.step2Text.text = i18n_t(m.global.i18n, "loginPage.qrStep2Description") 
    m.activationCodeLabel.text = "TMRALL"
    m.step3Badge.text = "3"
    m.step3Badge.color = "#FFFFFFFF"
    m.step3Text.text = i18n_t(m.global.i18n, "loginPage.qrStep3Description") 
    m.validatePhoneButton.text = i18n_t(m.global.i18n, "button.validateRegisterCode") 
end sub


' Valdia y realiza las acciones pertinentes al precionar el boton Previus de la pantalla 
sub __prevButtonPressed()
  if m.inputFocus = "password" then
    m.keyboard.text = m.userField.text
    m.inputFocus = "user"
    m.passwordField.text = invalid
    m.nextButton.setFocus(true)
    m.passwordLabel.opacity = 0.0
    m.passwordField.opacity = 0.0
    m.prevButton.disable = true
  end if  
end sub

' Valdia y realiza las acciones pertinentes al precionar el boton Next de la pantalla 
sub __nextButtonPressed()
  if m.inputFocus = "user" then
    if m.userField.text <> invalid and m.userField.text <> "" then 
      m.passwordLabel.opacity = 1.0
      m.passwordField.opacity = 1.0
      m.prevButton.disable = false
      m.inputFocus = "password"
      m.keyboard.text = invalid
    else
      __showDialog(i18n_t(m.global.i18n, "loginPage.errorForm.userRequired"))
    end if
  else if m.inputFocus = "password" then
    if m.passwordField.text <> invalid and m.passwordField.text <> "" then 
      if m.sendLoginPost = false then
        m.sendLoginPost = true
        user = m.userField.text
        password = m.passwordField.text
        __initData()
        
        if user = "" or password = "" then      
          m.sendLoginPost = false
          __showDialog(i18n_t(m.global.i18n, "loginPage.errorForm.invalidAccount"))
          return
        end if
        __login(user, password)
      end if
    else
      __showDialog(i18n_t(m.global.i18n, "loginPage.errorForm.passwordRequired"))
    end if 
  end if
end sub

' Carga los datos de componente
sub __initData()
  if m.productCode = invalid then m.productCode = getConfigVariable(m.global.configVariablesKeys.PRODUCT_CODE)
  if m.platformCode = invalid then m.platformCode = getConfigVariable(m.global.configVariablesKeys.PLATFORM_CODE)
  if m.enviroment = invalid then m.enviroment = getConfigVariable(m.global.configVariablesKeys.ENVIRONMENT) 
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
  if m.beaconUrl = invalid then m.beaconUrl = getConfigVariable(m.global.configVariablesKeys.BEACON_URL) 
end sub

' Realiza la peticion de logueo del usuario con las credenciales cargadas y los datos propios de la aplicaicon, 
' como la infromacion del dispositivo.
sub __login(user as String, password as String)
  if m.top.loading.visible = false then 
    credentials = {
      user: user,
      password: password,
      productCode: m.productCode,
      platformCode: m.platformCode,
      environment: m.enviroment,
      keepLoggedIn: true,
      device: m.global.device
    }
    
    m.top.loading.visible = true  
    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiRequestManager
      url: urlAuthCredentialsLogin(m.apiUrl)
      method: "POST"
      responseMethod: "onLoginResponse"
      body: FormatJson(credentials)
      token: invalid
      publicApi: true
      requestId: requestId
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, invalid, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().AUTH_API_URL)
    m.apiRequestManager = action.apiRequestManager
  end if 
end sub

' Muestra el modal con el mensaje de error pasado por parametro.
sub __showDialog(errorAPI as String)
  m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.unhandled"), errorAPI, "onDialogClosed")
end sub

' Entrega el foco al Teclado y actualiza la posicion del cursor.
sub __focusKeyboard()
  if m.inputFocus = "user" then 
    m.keyboard.textEditBox.cursorPosition = m.userField.text.Len()
  else
    m.keyboard.textEditBox.cursorPosition = m.passwordField.text.Len()
  end if
  m.keyboard.setFocus(true)
end sub

' Guardar el log cuandos se cambia una opción del menú 
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and m.apiUrl <> invalid then
    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogsToken(m.apiUrl)
      method: "GET"
      responseMethod: "onActionLogTokenResponse"
      body: invalid
      token: invalid
      publicApi: false
      requestId: requestId
      dataAux: FormatJson(actionLog)
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, invalid, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    runAction(requestId, action, ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  else
      __sendActionLog(actionLog)
  end if
end sub

' Obtener el beacon token
sub onActionLogTokenResponse() 

  resp = ParseJson(m.apiLogRequestManager.response)
  actionLog = ParseJson(m.apiLogRequestManager.dataAux)

  setBeaconToken(resp.actionsLogToken)

  now = CreateObject("roDateTime")
  now.ToLocalTime()
  m.global.beaconTokenExpiresIn = now.asSeconds() + ((resp.expiresIn - 60) * 1000)

  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager) 
  __sendActionLog(actionLog)
end sub

' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  if (beaconToken <> invalid and m.beaconUrl <> invalid)
    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogs(m.beaconUrl)
      method: "POST"
      responseMethod: "onActionLogResponse"
      body: FormatJson(actionLog)
      token: beaconToken
      publicApi: false
      dataAux: invalid
      requestId: requestId
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, invalid, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    runAction(requestId, action, ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  end if
end sub

' Limpiar la llamada del log
sub onActionLogResponse() 
  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
end sub

sub onActiveApiUrlChanged()
  __syncApiUrlFromGlobal()
  ' Actualiza los datos del QR cuando cambia el dominio activo
  __loadQrLoginConfig()
end sub

' Carga la configuración de login por código y actualiza el estado del módulo QR
sub __loadQrLoginConfig()
  ' Lee si el login por código está habilitado desde variables de configuración
  enableLoginByCode = getConfigVariable(m.global.configVariablesKeys.ENABLE_LOGIN_BY_CODE)
  ' Lee la URL remota de la imagen QR
  loginByCodeUrlQr = getConfigVariable(m.global.configVariablesKeys.LOGIN_BY_CODE_URL_QR)
  ' Lee la URL corta que se muestra como alternativa manual
  loginByCodeUrlShort = getConfigVariable(m.global.configVariablesKeys.LOGIN_BY_CODE_URL_SHORT)

  ' Normaliza el flag remoto para soportar distintos formatos (true/"true"/1)
  isEnabled = (enableLoginByCode = 1)
  ' Valida que exista una URL QR utilizable
  hasQrUrl = (loginByCodeUrlQr <> invalid and loginByCodeUrlQr <> "")

    ' Conserva el estado para que la visibilidad final dependa también del foco del selector
  m.isPhoneQrEnabled = (isEnabled and hasQrUrl)

  if m.isPhoneQrEnabled then
    ' Asigna la URL remota del código QR al poster
    m.qrCodePoster.uri = loginByCodeUrlQr

    if loginByCodeUrlShort <> invalid and loginByCodeUrlShort <> "" then
      ' Muestra la URL corta en la línea destacada del paso 1
      m.qrShortUrlLabel.text = loginByCodeUrlShort
    else
      m.qrShortUrlLabel.text = ""
    end if
  else
    ' Limpia la URL para evitar mostrar contenido obsoleto
    m.qrCodePoster.uri = ""
    m.qrShortUrlLabel.text = ""
  end if

  onLoginMethodFocusChanged()
end sub

sub __syncApiUrlFromGlobal()
  if m.global.activeApiUrl <> invalid and m.global.activeApiUrl <> "" then
    m.apiUrl = m.global.activeApiUrl
  end if
end sub