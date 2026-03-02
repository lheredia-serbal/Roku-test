function getCarouselImagesTypes() as Object
    return {
        NONE: 0,
        POSTER_PORTRAIT: 1,
        POSTER_LANDSCAPE: 2,
        SCENIC_PORTRAIT: 3,
        SCENIC_LANDSCAPE: 4,
    }
end function

function getCarouselStyles() as Object
    return {
        PORTRAIT_STANDARD: 1,
        PORTRAIT_FEATURED: 2,
        LANDSCAPE_STANDARD: 3,
        LANDSCAPE_FEATURED: 4,
        NEWS: 5,
        SQUARE_STANDARD: 6,
        CREDIT_STANDARD: 7,
        SQUARE_FEATURED: 8
    }
end function

function getCarouselContentType() as Object
    return {
        NONE: 0,
        NEWS: 1,
        CHANNELS: 2,
        PROGRAMS: 3,
        ON_DEMAND: 4,
        PREDEFINED: 5
    }
end function
