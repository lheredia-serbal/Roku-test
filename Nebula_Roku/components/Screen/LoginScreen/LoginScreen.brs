' ****** Funciones Públicas ******

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
  m.loginMethodSwitchLayout = m.top.findNode("loginMethodSwitchLayout")
  m.loginMethodSwitch = m.top.findNode("loginMethodSwitch") 
  m.loginMethodSwitchSelected = m.top.findNode("loginMethodSwitchSelected")
  m.loginMethodPhone = m.top.findNode("loginMethodPhone")
  m.loginMethodKeyboard = m.top.findNode("loginMethodKeyboard")
  m.qrContainer = m.top.findNode("qrContainer")
  m.phoneInstructionsTitle = m.top.findNode("phoneInstructionsTitle")
  m.step1BadgePoster = m.top.findNode("step1BadgePoster")
  m.step1Badge = m.top.findNode("step1Badge")
  m.step1Text = m.top.findNode("step1Text")
  m.qrShortUrlLabel = m.top.findNode("qrShortUrlLabel")
  m.step2BadgePoster = m.top.findNode("step2BadgePoster")
  m.step2Badge = m.top.findNode("step2Badge")
  m.step2Text = m.top.findNode("step2Text")
  m.activationCodeLabel = m.top.findNode("activationCodeLabel")
  m.step3BadgePoster = m.top.findNode("step3BadgePoster")
  m.step3Badge = m.top.findNode("step3Badge")
  m.step3Text = m.top.findNode("step3Text")
  m.qrCodeBackground = m.top.findNode("qrCodeBackground")
  m.qrCodePoster = m.top.findNode("qrCodePoster")
  m.validatePhoneButton = m.top.findNode("validatePhoneButton")
  ' Crea el timer que validará el código de registro periódicamente
  m.validateRegisterCodeTimer = CreateObject("roSGNode", "Timer") 
  ' Configura el intervalo del timer en 10 segundos
  m.validateRegisterCodeTimer.duration = 10 
  m.validateRegisterCodeTimer.repeat = true
  ' Enlaza el evento del timer con el callback del componente
  m.validateRegisterCodeTimer.observeField("fire", "onValidateRegisterCodeTimerFire") 
  ' Agrega el timer al árbol SceneGraph para habilitar su ejecución
  m.top.appendChild(m.validateRegisterCodeTimer) 
  ' Cuenta cuántas ejecuciones reales realizó el timer para cortar el polling al llegar a 20
  m.validateRegisterCodeTimerExecutions = 0 
  m.validateRegisterCodeTimerMaxExecutions = 20
  ' Recuerda si el timer fue pausado manualmente desde el botón Validate
  m.validateRegisterCodeTimerPausedByButton = false 

  m.scaleInfo = m.global.scaleInfo

  m.mainContainer.translation = scaleSize([180, 70], m.scaleInfo)

  ' Configurar el máximo de carácteres que se puede ingresa
  m.keyboard.showTextEditBox = false
  m.keyboard.textEditBox.maxTextLength = 255
  m.userField.maxTextLength = 255
  m.passwordField.maxTextLength = 255
  
  m.passwordLabel.opacity = 0.0
  m.passwordField.opacity = 0.0

  ' Bandera que indica si 
  m.LoginQrisEnabled = false

  ' Setear los estilos de los text inputs
  m.email.width = scaleValue(300, m.scaleInfo)
  m.passwordLabel.width = scaleValue(300, m.scaleInfo)

  m.userField.hintTextColor = m.global.colors.LIGHT_GRAY
  m.userField.width = scaleValue(910, m.scaleInfo)

  m.passwordField.hintTextColor = m.global.colors.LIGHT_GRAY
  m.passwordField.width = scaleValue(910, m.scaleInfo)

  ' Setear los estilos del selector
  m.loginMethodSwitch.blendColor = m.global.colors.PLAYER_TIMEBAR_NOT_FOCUCED
  m.loginMethodSwitchSelected.blendColor = m.global.colors.PRIMARY
  m.loginMethodTitle.width = scaleValue(900, m.scaleInfo)
  m.loginMethodTitle.height = scaleValue(55, m.scaleInfo)
  m.loginMethodSwitchLayout.translation = [150, 0]
  m.loginMethodSwitch.width = scaleValue(370, m.scaleInfo)
  m.loginMethodSwitch.height = scaleValue(45, m.scaleInfo)
  m.loginMethodSwitch.translation = [260, 0] 
  m.loginMethodSwitchSelected.width = scaleValue(180, m.scaleInfo)
  m.loginMethodSwitchSelected.height = scaleValue(33, m.scaleInfo)
  m.loginMethodSwitchSelected.translation = scaleSize([0, 0], m.scaleInfo)
  m.loginMethodPhone.width = scaleValue(180, m.scaleInfo)
  m.loginMethodPhone.height = scaleValue(45, m.scaleInfo)
  m.loginMethodPhone.translation = [0, 2]
  m.loginMethodKeyboard.width = scaleValue(180, m.scaleInfo)
  m.loginMethodKeyboard.height = scaleValue(45, m.scaleInfo)
  m.loginMethodKeyboard.translation = scaleSize([180, 2], m.scaleInfo)
  m.loginSwitchSelectedLeftX = scaleValue(8, m.scaleInfo)
  m.loginSwitchSelectedRightX = scaleValue(180, m.scaleInfo)
  m.loginSwitchSelectedY = scaleValue(6, m.scaleInfo)
  m.loginMethodSwitchHasInitialized = false
  m.lastLoginMethodFocus = "phone"
  
  ' Setear la ubicación del teclado
  m.keyboard.translation = scaleSize([-15,0], m.scaleInfo)

  ' Setear el logo
  m.logo.width = scaleValue(200, m.scaleInfo)
  m.logo.height = scaleValue(100, m.scaleInfo)

  ' Setear los botones anterior y sigueinte
  m.prevButton.size = scaleSize([150, 40], m.scaleInfo)
  m.nextButton.size = scaleSize([150, 40], m.scaleInfo)

  ' Setear el formulario de QR

  m.phoneInstructionsTitle.width = scaleValue(1120, m.scaleInfo)
  m.phoneInstructionsTitle.translation = scaleSize([0, 0], m.scaleInfo)

  stepWidth = 40
  stepHeight = 40
  stepX = 60
  stepY = 60

  m.step1BadgePoster.width = scaleValue(stepWidth, m.scaleInfo)
  m.step1BadgePoster.height = scaleValue(stepHeight, m.scaleInfo)
  m.step1BadgePoster.translation = scaleSize([0, stepY], m.scaleInfo)
  m.step1Badge.width = scaleValue(stepWidth, m.scaleInfo)
  m.step1Badge.height = scaleValue(stepHeight, m.scaleInfo)
  m.step1Badge.translation = scaleSize([0, stepY + 3], m.scaleInfo)
  m.step1Text.width = scaleValue(980, m.scaleInfo)
  m.step1Text.translation = scaleSize([stepX, stepY - 5], m.scaleInfo)
  m.qrShortUrlLabel.width = scaleValue(980, m.scaleInfo)
  m.qrShortUrlLabel.translation = scaleSize([stepX, stepY + 25], m.scaleInfo)

  m.step2BadgePoster.width = scaleValue(stepWidth, m.scaleInfo)
  m.step2BadgePoster.height = scaleValue(stepHeight, m.scaleInfo)
  m.step2BadgePoster.translation = scaleSize([0, stepY + 80], m.scaleInfo)
  m.step2Badge.width = scaleValue(stepWidth, m.scaleInfo)
  m.step2Badge.height = scaleValue(40, m.scaleInfo)
  m.step2Badge.translation = scaleSize([0, stepY + 83], m.scaleInfo)
  m.step2Text.width = scaleValue(980, m.scaleInfo)
  m.step2Text.translation = scaleSize([stepX, stepY + 75], m.scaleInfo)
  m.activationCodeLabel.width = scaleValue(980, m.scaleInfo)
  m.activationCodeLabel.translation = scaleSize([stepX, stepY + 110], m.scaleInfo)

  m.step3BadgePoster.width = scaleValue(stepWidth, m.scaleInfo)
  m.step3BadgePoster.height = scaleValue(stepHeight, m.scaleInfo)
  m.step3BadgePoster.translation = scaleSize([0, stepY + 160], m.scaleInfo)
  m.step3Badge.width = scaleValue(stepWidth, m.scaleInfo)
  m.step3Badge.height = scaleValue(40, m.scaleInfo)
  m.step3Badge.translation = scaleSize([0, stepY + 163], m.scaleInfo)
  m.step3Text.width = scaleValue(980, m.scaleInfo)
  m.step3Text.translation = scaleSize([stepX, stepY + 160], m.scaleInfo)

  m.qrCodeBackground.width = scaleValue(300, m.scaleInfo)
  m.qrCodeBackground.height = scaleValue(300, m.scaleInfo)
  m.qrCodeBackground.translation = scaleSize([750, 0], m.scaleInfo)
  m.qrCodePoster.width = scaleValue(260, m.scaleInfo)
  m.qrCodePoster.height = scaleValue(260, m.scaleInfo)
  m.qrCodePoster.translation = scaleSize([20, 20], m.scaleInfo)

  m.validatePhoneButton.size = scaleSize([150, 40], m.scaleInfo)
  m.validatePhoneButton.translation = scaleSize([450, 350], m.scaleInfo)

  ' Escucha cambios de foco del método Teléfono para alternar visibilidad del formulario
  if m.loginMethodPhone <> invalid then m.loginMethodPhone.observeField("hasFocus", "onLoginMethodFocusChanged")

  if m.global <> invalid then
    m.global.observeField("activeApiUrl", "onActiveApiUrlChanged")
  end if
end sub

' Actualiza la imagen del selector según si el foco está en Validate o en el switch de método
sub changeLoginSwitchColor(enabled)
  if enabled  then
    m.loginMethodSwitchSelected.blendColor = m.global.colors.PRIMARY
  else
    m.loginMethodSwitchSelected.blendColor = m.global.colors.LIGHT_GRAY
  end if
end sub

' Inicializa el foco del componente seteando los valores necesarios
sub initFocus()
  if m.top.onFocus then
    __applyTranslations()
    m.sendLoginPost = false
    m.inputFocus = "user"
    m.prevButton.disable = true

    m.keyboard.unobserveField("textEditBox")

    width = m.scaleInfo.width

    m.buttonContainer.translation = [((width - scaleValue(380, m.scaleInfo)) / 2), 400]
    m.logo.translation = [(width - scaleValue(280, m.scaleInfo)), scaleValue(30, m.scaleInfo)]

    ' Reinicia el contador del polling al entrar nuevamente a la pantalla
    m.validateRegisterCodeTimerExecutions = 0 
    __loadQrLoginConfig()
    ' Ubica el módulo de pasos/QR debajo del switch para el flujo por teléfono
    m.qrContainer.translation = [scaleValue(110, m.scaleInfo), scaleValue(220, m.scaleInfo)]
    
    m.keyboard.ObserveField("textEditBox", "onTextBoxManagment")
    ' Posiciona el selector en Teléfono sin animación al entrar
    __animateLoginMethodSwitchSelected(true, false) 
    ' Aplica de inmediato la visibilidad del formulario según el foco inicial
    onLoginMethodFocusChanged()
  end if
end sub 

' Limpiar la llamada del log
sub onActionLogResponse() 
  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
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

sub onActiveApiUrlChanged()
  __syncApiUrlFromGlobal()
  ' Actualiza los datos del QR cuando cambia el dominio activo
  __loadQrLoginConfig()
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

' Notifica que finalizo las tareas de la pantalla
sub onFinished()
  if m.top.finished then 
    __stopValidateRegisterCodeTimer() ' Agregado: detiene el polling cuando la pantalla termina su flujo
    m.validateRegisterCodeTimerExecutions = 0 ' Agregado: reinicia el contador del polling al finalizar la pantalla
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

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as String, press as Boolean) as Boolean
  if m.top.loading.visible <> false and key <> KeyButtons().BACK then 
    return true
  end if

  handled = false

  if not press then
    ' Foco en siguiente y se presiona arriba
    if m.keyboard.isInFocusChain() and key = KeyButtons().UP then
      m.nextButton.setFocus(true)
      handled = true
    ' Foco en siguiente y se presiona derecha
    else if m.prevButton.isInFocusChain() and key = KeyButtons().RIGHT then
      m.nextButton.setFocus(true)
      handled = true
    ' Foco en anterior y se presiona abajo
    else if m.prevButton.isInFocusChain() and key = KeyButtons().DOWN then
      __focusKeyboard()
      handled = true
    ' Foco en anterior y se presiona arriba
    else if m.prevButton.isInFocusChain() and key = KeyButtons().UP and m.LoginQrisEnabled then
      __focusLoginMethod()
      changeLoginSwitchColor(true)
      handled = true
    ' Foco en anterior y se presiona OK
    else if m.prevButton.isInFocusChain() and key = KeyButtons().OK then
      __prevButtonPressed()
      handled = true
    ' Foco en siguiente y se presiona izquierda
    else if m.nextButton.isInFocusChain() and key = KeyButtons().LEFT then
      if m.inputFocus = "password" then  
        m.prevButton.setFocus(true)
      end if
      handled = true
    ' Foco en siguiente y se presiona abajo
    else if m.nextButton.isInFocusChain() and key = KeyButtons().DOWN then
      __focusKeyboard()
      handled = true
    ' Foco en siguiente y se presiona arriba
    else if m.nextButton.isInFocusChain() and key = KeyButtons().UP and m.LoginQrisEnabled then      
      __focusLoginMethod()
      changeLoginSwitchColor(true)
      handled = true
    ' Foco en siguiente y se presiona Ok
    else if m.nextButton.isInFocusChain() and key = KeyButtons().OK then
      __nextButtonPressed()
      handled = true
    ' Foco en login por QR y se presiona derecha
    else if m.loginMethodPhone <> invalid and m.loginMethodPhone.isInFocusChain() and key = KeyButtons().RIGHT then
      ' Mueve foco a la opción Teclado con botón derecha
      m.loginMethodKeyboard.setFocus(true)
      ' Fuerza animación hacia la derecha al enfocar Teclado
      __animateLoginMethodSwitchSelected(false, true) 
      onLoginMethodFocusChanged()
      handled = true
    ' Foco en login por usuario y se presiona izquierda
    else if m.loginMethodKeyboard <> invalid and m.loginMethodKeyboard.isInFocusChain() and key = KeyButtons().LEFT then
      ' Retorna foco a Teléfono con botón izquierda
      m.loginMethodPhone.setFocus(true) 
      ' Fuerza animación hacia la izquierda al volver a Teléfono
      __animateLoginMethodSwitchSelected(true, true) 
      onLoginMethodFocusChanged()
      handled = true
    ' Foco en login por QR y se presiona abajo
    else if m.loginMethodPhone <> invalid and m.loginMethodPhone.isInFocusChain() and key = KeyButtons().DOWN then
      ' Registra Phone como último foco antes de bajar a Validate
      m.lastLoginMethodFocus = "phone" 
      if m.loginMethodPhone.isInFocusChain() then
        ' Mueve foco al botón Validate con tecla abajo
        m.validatePhoneButton.setFocus(true) 
      else
        __focusKeyboard()
      end if
      changeLoginSwitchColor(false)
      handled = true
    ' Foco en login por usuario y se presiona abajo
    else if m.loginMethodKeyboard <> invalid and m.loginMethodKeyboard.isInFocusChain() and key = KeyButtons().DOWN then
      ' Registra Keyboard como último foco antes de bajar a Validate
      m.lastLoginMethodFocus = "keyboard" 
      if m.loginMethodPhone.isInFocusChain() then
        ' Mueve foco al botón Validate con tecla abajo
        m.validatePhoneButton.setFocus(true) 
      else
        __focusKeyboard()
      end if
      changeLoginSwitchColor(false)
      handled = true
    ' Foco en el botón validar y se presiona arriba
    else if m.validatePhoneButton <> invalid and m.validatePhoneButton.isInFocusChain() and key = KeyButtons().UP then
      __focusLoginMethod()
      changeLoginSwitchColor(true)
      handled = true
    ' Foco en el botón validar y se presiona OK
    else if m.validatePhoneButton <> invalid and m.validatePhoneButton.isInFocusChain() and key = KeyButtons().OK then 
      ' Pausa el timer para priorizar la validación manual desde el botón
      __pauseValidateRegisterCodeTimerForButton() 
      validateRegisterCodeLogin()
      handled = true
    end if
  end if

  return handled
end function

' Recibir la respuesta del servicio que inserta la instalación
sub onLoadInstallationByDeviceResponse()

  if m.apiInstallationRequestManager = invalid then
    __loadInstallationByDevice()
    return
  else 
    if validateStatusCode(m.apiInstallationRequestManager.statusCode) then

      removePendingAction(m.apiInstallationRequestManager.requestId)

      data = ParseJson(m.apiInstallationRequestManager.response)

      registerCode = data.data.formattedRegisterCode
      m.activationCodeLabel.text = registerCode

      ' Actualiza la variable global device con la data devuelta por Installations
      addAndSetFields(m.global, {device: data.data} ) 
      if data.data.token <> invalid and data.data.token <> "" then  setDeviceToken(data.data.token)

      ' Lee la URL remota de la imagen QR
      loginByCodeUrlQr = getConfigVariable(m.global.configVariablesKeys.LOGIN_BY_CODE_URL_QR)

      activationCode = loginByCodeUrlQr.replace("[RegistrationCode]", registerCode)
      m.qrCodePoster.uri = "https://api.qrserver.com/v1/create-qr-code/?size=256x260&data=" + activationCode 

      __showLoginMethod(true)

    else 
      m.LoginQrisEnabled = false

      if m.apiInstallationRequestManager.serverError then
        statusCode = m.apiInstallationRequestManager.statusCode
        setCdnErrorCodeFromStatus(statusCode, ApiType().CLIENTS_API_URL)
        changeStatusAction(m.apiInstallationRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiInstallationRequestManager.requestId)
        if m.resultCodes = invalid then m.resultCodes = getResultCodes()
        m.top.loading.visible = false
      end if
    end if 
    onLoginMethodFocusChanged()
    m.apiInstallationRequestManager = clearApiRequest(m.apiInstallationRequestManager)
  end if
end sub

' Ocultar o mostrar el formuarlio de Login por QR
sub onLoginMethodFocusChanged()

  if (m.LoginQrisEnabled) then
    ' Determina si la opción Teléfono es la que actualmente tiene foco
    isPhoneFocused = m.loginMethodPhone <> invalid and m.loginMethodPhone.isInFocusChain()
    ' Guarda foco actual para retorno desde Validate
    m.lastLoginMethodFocus = "keyboard" 
    if isPhoneFocused then m.lastLoginMethodFocus = "phone"
    ' Anima selector en cambios de foco izquierda/derecha
    __animateLoginMethodSwitchSelected(isPhoneFocused, m.loginMethodSwitchHasInitialized) 
    ' Habilita animaciones luego de la primera sincronización
    m.loginMethodSwitchHasInitialized = true 
    ' Muestra credenciales únicamente cuando el foco está en la opción Teclado
    m.credentialsContainer.visible = not isPhoneFocused
    ' Muestra QR únicamente cuando el foco está en la opción Teléfono
    m.qrContainer.visible = isPhoneFocused
  else
    m.credentialsContainer.visible = true
    m.qrContainer.visible = false
    m.loginMethodSwitch.visible = false
    m.loginMethodTitle.visible = false

    'Envía el foco al teclado cuando el flujo QR queda deshabilitado
    __focusKeyboard()
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

      resp = ParseJson(m.apiRequestManager.response)
      
      addAndSetFields(m.global, {device: resp.device, organization: resp.organization, contact: resp.contact, variables: resp.variables} )
      
      saveNextUpdateVariables()

      SetDevice(resp.device)
      saveTokens(resp)

      actionLog = getActionLog({ actionCode: ActionLogCode().LOGIN_BY_CREDENTIALS })
      __saveActionLog(actionLog)

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

' Procesa e imprime la respuesta del polling de RegisterCodeLogin
sub onValidateRegisterCodeLoginResponse() 
  if m.apiRegisterCodeRequestManager = invalid then return
  ' Procesa el flujo exitoso de RegisterCodeLogin
  if validateStatusCode(m.apiRegisterCodeRequestManager.statusCode) then 
    ' Corta el timer para evitar nuevas ejecuciones luego del login exitoso
    __stopValidateRegisterCodeTimer() 
    ' Limpia la acción pendiente cuando la respuesta es exitosa
    removePendingAction(m.apiRegisterCodeRequestManager.requestId) 
    ' Completa el login con la respuesta del RegisterCodeLogin exitoso
    __finishLoginWithApiResponse() 
    ' Libera el manager dedicado luego de finalizar el login
    m.apiRegisterCodeRequestManager = clearApiRequest(m.apiRegisterCodeRequestManager) 
  else
    m.apiRegisterCodeRequestManager = clearApiRequest(m.apiRegisterCodeRequestManager)
    if m.validateRegisterCodeTimerPausedByButton and m.validateRegisterCodeTimerExecutions < m.validateRegisterCodeTimerMaxExecutions then 
      ' Reanuda el timer luego de priorizar la validación manual si todavía quedan ejecuciones disponibles
      __startValidateRegisterCodeTimer() 
    end if
  end if
end sub

' Callback del timer de validación periódica
sub onValidateRegisterCodeTimerFire() 
  ' Evita disparar otra validación si ya hay una petición en curso
  if m.apiRegisterCodeRequestManager <> invalid then return 
  ' Corta el timer cuando ya alcanzó el máximo de 10 ejecuciones
  if m.validateRegisterCodeTimerExecutions >= m.validateRegisterCodeTimerMaxExecutions then __stopValidateRegisterCodeTimer() : return 
  ' Registra una nueva ejecución real provocada por el timer
  m.validateRegisterCodeTimerExecutions = m.validateRegisterCodeTimerExecutions + 1 
  ' Ejecuta la validación del código de registro cada vez que dispara el timer
  validateRegisterCodeLogin() 
end sub

' Ejecuta el servicio RegisterCodeLogin con el payload solicitado
sub validateRegisterCodeLogin() 
  ' Asegura que los datos base del request estén cargados antes de llamar al servicio
  __initData() 
  if m.apiUrl = invalid or m.apiUrl = "" then return
  if m.global = invalid or m.global.device = invalid then return
  ' Previene llamadas concurrentes si la validación anterior sigue en curso
  if m.apiRegisterCodeRequestManager <> invalid then return 

  ' Genera un identificador para reutilizar la lógica estándar de requests del componente
  requestId = createRequestId() 
  registerCodeLoginPayload = {
    productCode: m.productCode 
    platformCode: m.platformCode
    environment: m.enviroment
    device: m.global.device
  }

  action = {
    apiRequestManager: m.apiRegisterCodeRequestManager 
    url: urlRegisterCode(m.apiUrl)
    method: "POST"
    responseMethod: "onValidateRegisterCodeLoginResponse" 
    body: FormatJson(registerCodeLoginPayload)
    token: invalid
    publicApi: true
    requestId: requestId 
    dataAux: invalid 
    run: function() as Object 
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux) 
      return { success: true, error: invalid } 
    end function
  }

  runAction(requestId, action, ApiType().AUTH_API_URL) 
  m.apiRegisterCodeRequestManager = action.apiRequestManager
end sub

' ****** Funciones privadas ******

' Anima (o posiciona) el selector visual del switch de login según la opción activa
sub __animateLoginMethodSwitchSelected(isPhoneSelected as Boolean, withAnimation as Boolean)
  if m.loginMethodSwitchSelected = invalid then return

  targetX = m.loginSwitchSelectedRightX
  if isPhoneSelected then targetX = m.loginSwitchSelectedLeftX

  targetPosition = [targetX, m.loginSwitchSelectedY]

  if not withAnimation then
    m.loginMethodSwitchSelected.translation = targetPosition
    return
  end if

  if m.loginMethodSwitchAnimation = invalid then
    m.loginMethodSwitchAnimation = CreateObject("roSGNode", "Animation") 
    m.loginMethodSwitchAnimation.duration = 0.18
    ' Solo una transición por interacción
    m.loginMethodSwitchAnimation.repeat = false 
    m.loginMethodSwitchInterpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
    m.loginMethodSwitchInterpolator.key = [0.0, 1.0]
     ' Campo objetivo del interpolador
    m.loginMethodSwitchInterpolator.fieldToInterp = "loginMethodSwitchSelected.translation"
    ' Conecta interpolador a la animación
    m.loginMethodSwitchAnimation.appendChild(m.loginMethodSwitchInterpolator) 
    m.top.appendChild(m.loginMethodSwitchAnimation)
  end if

  currentPosition = m.loginMethodSwitchSelected.translation
  ' Define origen y destino del desplazamiento
  m.loginMethodSwitchInterpolator.keyValue = [currentPosition, targetPosition] 
  ' Reinicia animación previa antes de arrancar la nueva
  m.loginMethodSwitchAnimation.control = "stop" 
  ' Ejecuta el desplazamiento animado
  m.loginMethodSwitchAnimation.control = "start" 
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
    m.step1Text.text = i18n_t(m.global.i18n, "loginPage.qrStep1Description")
    m.step2Text.text = i18n_t(m.global.i18n, "loginPage.qrStep2Description") 
    m.step3Text.text = i18n_t(m.global.i18n, "loginPage.qrStep3Description") 
    m.validatePhoneButton.text = i18n_t(m.global.i18n, "button.validateRegisterCode") 
end sub

' Centraliza la finalización del login usando la respuesta HTTP disponible en m.apiRegisterCodeRequestManager
sub __finishLoginWithApiResponse() 
  resp = ParseJson(m.apiRegisterCodeRequestManager.response)

  ' Guarda en global los datos devueltos por el login exitoso
  addAndSetFields(m.global, {device: resp.device, organization: resp.organization, contact: resp.contact, variables: resp.variables} ) 

  ' Persiste la programación de actualización de variables remotas
  saveNextUpdateVariables() 

  ' Actualiza el dispositivo persistido localmente
  SetDevice(resp.device) 
  ' Guarda los tokens entregados por la autenticación
  saveTokens(resp) 

  ' Envianvía el log del login exitoso
  actionLog = getActionLog({ actionCode: ActionLogCode().LOGIN_BY_CREDENTIALS }) 
  __saveActionLog(actionLog) 

  ' Cierra la pantalla al completar correctamente el login
  m.top.finished = true 
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

' Setear el foco en la opción de login seleccionada
sub __focusLoginMethod()
  ' Retorna al último foco en Keyboard cuando aplica
  if m.lastLoginMethodFocus = "keyboard" then 
    m.loginMethodKeyboard.setFocus(true)
    ' Sincroniza selector al volver a Keyboard
    __animateLoginMethodSwitchSelected(false, true) 
  else
    ' Retorna por defecto a Phone
    m.loginMethodPhone.setFocus(true) 
    ' Sincroniza selector al volver a Phone
    __animateLoginMethodSwitchSelected(true, true) 
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

' Llama al servicio para registrar la instalación
sub __loadInstallationByDevice()
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
  if m.apiUrl = invalid or m.apiUrl = "" then return
  if m.global = invalid or m.global.device = invalid then return

  requestId = createRequestId()

  action = {
    apiRequestManager: m.apiInstallationRequestManager
    url: urlInstallation(m.apiUrl)
    method: "POST"
    responseMethod: "onLoadInstallationByDeviceResponse"
    body: FormatJson(m.global.device)
    token: invalid
    publicApi: true
    requestId: requestId
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux) 
      return { success: true, error: invalid }
    end function
  }

  runAction(requestId, action, ApiType().CLIENTS_API_URL) ' Agregado: reutiliza la lógica de ejecución y reintento estándar del componente
  m.apiInstallationRequestManager = action.apiRequestManager ' Agregado: sincroniza el manager local luego de lanzar la acción
end sub

' Carga la configuración de login por código y actualiza el estado del módulo QR
sub __loadQrLoginConfig()
  ' Lee si el login por código está habilitado desde variables de configuración
  enableLoginByCode = getConfigVariable(m.global.configVariablesKeys.ENABLE_LOGIN_BY_CODE)

  m.LoginQrisEnabled = (enableLoginByCode = 1)

  if m.LoginQrisEnabled then 
    ' Consulta Installations cuando el login por código está habilitado
    __loadInstallationByDevice()
  else 
    __showLoginMethod(false)
  end if
end sub

' Determinar si debe mostrar el método de login de QR
sub __showLoginMethod(showQr as boolean)

  m.mainContainer.visible = true

  if showQr then

    m.loginMethodSwitchLayout.visible = true
    m.qrContainer.visible = true
    m.loginMethodTitle.visible = true
    m.credentialsContainer.visible = false

    loginByCodeUrlQr = getConfigVariable(m.global.configVariablesKeys.LOGIN_BY_CODE_URL_QR)

    ' Lee la URL corta que se muestra como alternativa manual
    loginByCodeUrlShort = getConfigVariable(m.global.configVariablesKeys.LOGIN_BY_CODE_URL_SHORT)

    m.qrShortUrlLabel.text = loginByCodeUrlShort

    ' Activa el polling según la configuración remota
    __startValidateRegisterCodeTimer()

    ' Al iniciar, el foco debe quedar en la opción de login por teléfono
    m.loginMethodPhone.setFocus(true)
  else
    ' Oculta el switch de método cuando el login por código no está habilitado
    m.loginMethodSwitchLayout.visible = false
    m.qrContainer.visible = false
    m.loginMethodTitle.visible = false
    m.credentialsContainer = true
    'Envía el foco al teclado cuando el flujo QR queda deshabilitado
    __focusKeyboard()
  end if
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

' Valida y realiza las acciones pertinentes al precionar el boton Next de la pantalla 
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

' Helper para pausar el timer cuando el usuario prioriza el botón Validate
sub __pauseValidateRegisterCodeTimerForButton() 
  if m.validateRegisterCodeTimer = invalid then return
  ' Marca que la pausa provino del botón manual
  m.validateRegisterCodeTimerPausedByButton = true
  ' Pausa el timer para dar prioridad a la validación manual
  m.validateRegisterCodeTimer.control = "stop" 
end sub

' Valida y realiza las acciones pertinentes al precionar el boton Previus de la pantalla 
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

' Helper para iniciar el timer de polling
sub __startValidateRegisterCodeTimer() 
  if m.validateRegisterCodeTimer = invalid then return
  ' Impide reiniciar el timer si ya alcanzó su máximo de ejecuciones
  if m.validateRegisterCodeTimerExecutions >= m.validateRegisterCodeTimerMaxExecutions then return 
  ' Limpia el estado de pausa manual antes de reiniciar el timer
  m.validateRegisterCodeTimerPausedByButton = false 
  ' Reinicia el timer antes de volver a arrancarlo
  m.validateRegisterCodeTimer.control = "stop" 
  ' Inicia el polling periódico del servicio RegisterCodeLogin
  m.validateRegisterCodeTimer.control = "start" 
end sub

' Helper para detener el timer de polling
sub __stopValidateRegisterCodeTimer() 
  if m.validateRegisterCodeTimer = invalid then return 
  ' Limpia el estado de pausa manual al detener el polling
  m.validateRegisterCodeTimerPausedByButton = false 
  ' Detiene el polling cuando el flujo QR no está habilitado
  m.validateRegisterCodeTimer.control = "stop" 
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

' Muestra el modal con el mensaje de error pasado por parametro.
sub __showDialog(errorAPI as String)
  m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.unhandled"), errorAPI, "onDialogClosed")
end sub

' Obtiene el ApiUrl si este fue actualizado
sub __syncApiUrlFromGlobal()
  if m.global.activeApiUrl <> invalid and m.global.activeApiUrl <> "" then
    m.apiUrl = m.global.activeApiUrl
  end if
end sub