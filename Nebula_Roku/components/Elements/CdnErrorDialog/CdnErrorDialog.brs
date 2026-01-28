sub init()
  m.overlay = m.top.findNode("overlay")
  m.dialogContainer = m.top.findNode("dialogContainer")
  m.dialogBackground = m.top.findNode("dialogBackground")
  m.contentLayout = m.top.findNode("contentLayout")
  m.logo = m.top.findNode("logo")
  m.titleLabel = m.top.findNode("titleLabel")
  m.messageLabel = m.top.findNode("messageLabel")
  m.codeLabel = m.top.findNode("codeLabel")
  m.retryButton = m.top.findNode("retryButton")
  m.spinner = m.top.findNode("spinner")

  m.scaleInfo = invalid
  __refreshFromGlobal()

  m.top.observeField("visible", "onVisibleChange")

  onShowSpinnerChange()
  onButtonDisabledChange()
end sub

sub __applyLayout()
  m.overlay.width = m.scaleInfo.width
  m.overlay.height = m.scaleInfo.height

  dialogWidth = scaleValue(700, m.scaleInfo)
  dialogHeight = scaleValue(393, m.scaleInfo)
  padding = scaleSize([350, 180], m.scaleInfo)
  logoWidth = scaleValue(260, m.scaleInfo)
  logoHeight = scaleValue(110, m.scaleInfo)
  spacing = scaleValue(20, m.scaleInfo)

  m.dialogContainer.translation = [((m.scaleInfo.width - dialogWidth) / 2), ((m.scaleInfo.height - dialogHeight) / 2)]
  m.dialogBackground.width = dialogWidth
  m.dialogBackground.height = dialogHeight

  m.contentLayout.translation = padding

  contentWidth = dialogWidth - (padding[0] / 4)
  contentHeight = dialogHeight

  m.logo.width = logoWidth
  m.logo.height = logoHeight
  m.logo.loadWidth = logoWidth
  m.logo.loadHeight = logoHeight

  m.titleLabel.width = contentWidth
  m.messageLabel.width = contentWidth
  m.codeLabel.width = contentWidth

  buttonSize = [scaleValue(240, m.scaleInfo), scaleValue(60, m.scaleInfo)]
  m.retryButton.size = buttonSize

  spinnerX = dialogWidth - (dialogWidth / 2) - scaleValue(30, m.scaleInfo)
  spinnerY = dialogHeight - scaleValue(30, m.scaleInfo)
  m.spinner.translation = [spinnerX, spinnerY]
end sub

sub __applyTexts()
  m.titleLabel.text = i18n_t(m.global.i18n, "shared.errorComponent.cdnError.title")
  m.messageLabel.text = i18n_t(m.global.i18n, "shared.errorComponent.cdnError.message")
  m.retryButton.text = i18n_t(m.global.i18n, "button.tryAgain")

  whiteColor = "0xFFFFFFFF"
  lightGrayColor = "0xB3B3B3FF"
  if m.global.colors <> invalid then
    if m.global.colors.WHITE <> invalid then whiteColor = m.global.colors.WHITE
    if m.global.colors.LIGHT_GRAY <> invalid then lightGrayColor = m.global.colors.LIGHT_GRAY
  end if

  m.titleLabel.color = whiteColor
  m.messageLabel.color = lightGrayColor
  m.codeLabel.color = lightGrayColor
end sub

sub onVisibleChange()
  if m.top.visible then
    __refreshFromGlobal()
    m.retryButton.setFocus(true)
  else
    m.top.retry = false
  end if
end sub

sub onErrorCodeChange()
  codeValue = m.top.errorCode
  if codeValue = invalid or codeValue = "" then codeValue = "--"
  baseText = i18n_t(m.global.i18n, "shared.errorComponent.cdnError.code")
  m.codeLabel.text = baseText.Replace("[Code]", codeValue)
end sub

sub onShowSpinnerChange()
  m.spinner.visible = m.top.showSpinner
end sub

sub onButtonDisabledChange()
  m.retryButton.disable = m.top.buttonDisabled
end sub

sub __refreshFromGlobal()
  if m.global <> invalid and m.global.scaleInfo <> invalid then
    m.scaleInfo = m.global.scaleInfo
  else if m.scaleInfo = invalid
    m.scaleInfo = getScaleInfo(CreateObject("roDeviceInfo"))
  end if

  __applyLayout()
  __applyTexts()
  onErrorCodeChange()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if press and key = "OK" and m.retryButton.isInFocusChain() and not m.retryButton.disable then
    m.top.retry = true
    return true
  end if
  return false
end function