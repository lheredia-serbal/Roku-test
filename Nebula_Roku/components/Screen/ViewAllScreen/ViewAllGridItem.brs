sub init()
  m.scaleInfo = m.global.scaleInfo
  m.itemBackground = m.top.findNode("itemBackground")
  m.itemImage = m.top.findNode("itemImage")
  m.itemTitle = m.top.findNode("itemTitle")
  m.metadataGroup = m.top.findNode("metadataGroup")
  m.metadataGradient = m.top.findNode("metadataGradient")
  m.metadataLabels = m.top.findNode("metadataLabels")
  m.programName = m.top.findNode("programName")
  m.programCategory = m.top.findNode("programCategory")
  m.progressGroup = m.top.findNode("progressGroup")
  m.progressLeft = m.top.findNode("progressLeft")
  m.progressRight = m.top.findNode("progressRight")

  m.hasMetadataContent = false
  m.hasProgressContent = false
  m.squareFeaturedItem = invalid
  m.squareFeaturedItemComponentName = invalid

  if m.global.colors <> invalid then
    if m.global.colors.LIGHT_GRAY <> invalid then m.programCategory.color = m.global.colors.LIGHT_GRAY
    if m.global.colors.PROGRESS <> invalid then m.progressLeft.color = m.global.colors.PROGRESS
    if m.global.colors.PROGRESS_BG <> invalid then m.progressRight.color = m.global.colors.PROGRESS_BG
  end if
end sub

sub onItemContentChanged()
  if m.top.itemContent = invalid then return

  itemSize = __getItemSize()

    if m.top.itemContent.style = getCarouselStyles().SQUARE_FEATURED then
    __showSquareFeaturedCarouselItem(itemSize)
    return
  end if

  __hideSquareFeaturedCarouselItem()
  __showBaseItem()

  m.itemBackground.width = itemSize[0]
  m.itemBackground.height = itemSize[1]

  imageSize = itemSize
  imageTranslation = [0, 0]
  m.itemTitle.visible = false
  __hideMetadata()

  if m.top.itemContent.style = getCarouselStyles().SQUARE_STANDARD then
    imageSize = scaleSize([60, 60], m.scaleInfo)
    imageTranslation = [
      (itemSize[0] - imageSize[0]) / 2,
      scaleValue(6, m.scaleInfo)
    ]

    m.itemTitle.text = m.top.itemContent.title
    m.itemTitle.width = itemSize[0]
    titleY = scaleValue(52, m.scaleInfo)
    m.itemTitle.height = itemSize[1] - titleY
    m.itemTitle.translation = [0, titleY]
    m.itemTitle.visible = true
  else
    __showMetadata(itemSize)
  end if

  m.itemImage.width = imageSize[0]
  m.itemImage.height = imageSize[1]
  m.itemImage.translation = imageTranslation

  if m.top.itemContent.imageURL <> invalid then
    m.itemImage.uri = m.top.itemContent.imageURL
  else if m.top.itemContent.HDPosterUrl <> invalid then
    m.itemImage.uri = m.top.itemContent.HDPosterUrl
  end if
end sub

function __getItemSize() as Object
  if m.top.itemContent <> invalid and m.top.itemContent.size <> invalid then return m.top.itemContent.size
  return scaleSize([140, 140], m.scaleInfo)
end function

sub __hideMetadata()
  m.hasMetadataContent = false
  m.hasProgressContent = false
  if m.metadataGroup <> invalid then m.metadataGroup.visible = false
  if m.metadataGradient <> invalid then m.metadataGradient.visible = false
  if m.metadataLabels <> invalid then m.metadataLabels.visible = false
  if m.programName <> invalid then m.programName.visible = false
  if m.programCategory <> invalid then m.programCategory.visible = false
  if m.progressLeft <> invalid then m.progressLeft.width = 0
  if m.progressRight <> invalid then m.progressRight.width = 0
end sub

sub __showMetadata(itemSize as Object)
  if m.metadataGroup = invalid then return

  padding = scaleValue(8, m.scaleInfo)
  progressHeight = scaleValue(3, m.scaleInfo)
  progressBottom = scaleValue(8, m.scaleInfo)
  labelsBottomPadding = scaleValue(6, m.scaleInfo)
  metadataWidth = itemSize[0] - (padding * 2)
  if metadataWidth < 0 then metadataWidth = 0

  m.metadataGradient.width = itemSize[0]
  m.metadataGradient.height = itemSize[1]
  m.metadataLabels.translation = [padding, itemSize[1] - scaleValue(20, m.scaleInfo)]
  m.programName.width = metadataWidth
  m.programCategory.width = metadataWidth

  hasMetadata = false
  if m.top.itemContent.title <> invalid and m.top.itemContent.title <> "" then
    m.programName.text = m.top.itemContent.title
    m.programName.visible = true
    hasMetadata = true
  end if

  if m.top.itemContent.category <> invalid and m.top.itemContent.category <> "" then
    m.programCategory.text = m.top.itemContent.category
    m.programCategory.visible = true
    hasMetadata = true
  end if

  m.hasMetadataContent = hasMetadata

  m.progressLeft.height = progressHeight
  m.progressRight.height = progressHeight
  m.progressGroup.translation = [padding, itemSize[1] - progressBottom]

  progressWidth = metadataWidth
  if m.top.itemContent.percentageElapsed <> invalid and m.top.itemContent.percentageElapsed > 0 then
    elapsed = m.top.itemContent.percentageElapsed
    if elapsed > 100 then elapsed = 100
    widthLeft = (elapsed * progressWidth) / 100
    m.progressLeft.width = widthLeft
    m.progressRight.width = progressWidth - widthLeft
    m.hasProgressContent = true
  else
    m.progressLeft.width = 0
    m.progressRight.width = 0
    m.hasProgressContent = false
  end if

  if m.metadataGroup <> invalid then m.metadataGroup.visible = (m.hasMetadataContent or m.hasProgressContent)
  __applyFocusedMetadataVisibility()
end sub

sub onFocusPercentChanged()
  if m.squareFeaturedItem <> invalid and m.squareFeaturedItem.visible then m.squareFeaturedItem.focusPercent = m.top.focusPercent

  __applyFocusedMetadataVisibility()
end sub

sub __applyFocusedMetadataVisibility()
  hasFocus = false
  if m.top.focusPercent <> invalid and m.top.focusPercent >= 0.95 then hasFocus = true
  showFocusedMetadata = (m.hasMetadataContent and hasFocus)

  if m.metadataGradient <> invalid then m.metadataGradient.visible = showFocusedMetadata
  if m.metadataLabels <> invalid then m.metadataLabels.visible = showFocusedMetadata
end sub

sub __showSquareFeaturedCarouselItem(itemSize as Object)
  componentName = "SquareFeaturedItem"
  if m.top.itemContent.contentType = getCarouselContentType().PROGRAMS then
    m.metadataGroup.width = scaleValue(100, m.scaleInfo)
    componentName = "SquareFeaturedProgramItem"
  else 
    
  end if

  if m.squareFeaturedItem = invalid or m.squareFeaturedItemComponentName <> componentName then
    if m.squareFeaturedItem <> invalid then m.top.removeChild(m.squareFeaturedItem)
    m.squareFeaturedItem = m.top.createChild(componentName)
    m.squareFeaturedItemComponentName = componentName
  end if

  __hideBaseItem()

  m.squareFeaturedItem.visible = true
  m.squareFeaturedItem.itemContent = m.top.itemContent
  m.squareFeaturedItem.currRect = { x: 0, y: 0, width: itemSize[0], height: itemSize[1] }
  m.squareFeaturedItem.focusPercent = m.top.focusPercent
end sub

sub __hideSquareFeaturedCarouselItem()
  if m.squareFeaturedItem <> invalid then m.squareFeaturedItem.visible = false
end sub

sub __hideBaseItem()
  if m.itemBackground <> invalid then m.itemBackground.visible = false
  if m.itemImage <> invalid then m.itemImage.visible = false
  if m.itemTitle <> invalid then m.itemTitle.visible = false
  __hideMetadata()
end sub

sub __showBaseItem()
  if m.itemBackground <> invalid then m.itemBackground.visible = true
  if m.itemImage <> invalid then m.itemImage.visible = true
end sub