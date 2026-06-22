sub init()
  m.scaleInfo = m.global.scaleInfo
  m.itemBackground = m.top.findNode("itemBackground")
  m.itemImage = m.top.findNode("itemImage")
  m.itemTitle = m.top.findNode("itemTitle")
end sub

sub onItemContentChanged()
  if m.top.itemContent = invalid then return

  itemSize = __getItemSize()
  m.itemBackground.width = itemSize[0]
  m.itemBackground.height = itemSize[1]

  imageSize = itemSize
  imageTranslation = [0, 0]
  m.itemTitle.visible = false

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
