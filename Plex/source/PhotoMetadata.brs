'itei*
'* Metadata objects for photo data
'*

Function createBasePhotoMetadata(container, item) As Object
    metadata = createBaseMetadata(container, item)

    metadata.ratingKey = item@ratingKey

    ' We never need to fetch and parse additional details for audio metadata
    metadata.HasDetails = True

    return metadata
End Function

Function newPhotoMetadata(container, item, detailed=true) As Object
    photo = createBasePhotoMetadata(container, item)

    photo.Title = item@title
    photo.mediaContainerIdentifier = container.xml@identifier
    photo.ContentType = "photo"
    if photo.Type = invalid then photo.Type = "photo"
    photo.media = ParsePhotoMedia(item)

    if photo.media.Count() > 0 AND photo.media[0].preferredPart <> invalid then
        photo.Url = FullUrl(photo.server.serverUrl, photo.sourceUrl, photo.media[0].preferredPart.key)
    else
        photo.Url = FullUrl(photo.server.serverUrl, photo.sourceUrl, photo.key)
    end if

    photo.TextOverlayUL = photo.Title
    photo.TextOverlayBody = item@summary

    ' If there's no thumb, make a thumb out of the full URL.
    if photo.SDPosterURL = invalid OR Left(photo.SDPosterURL, 4) = "file" then
        sizes = ImageSizes("photos", "photo")
        photo.SDPosterURL = photo.server.TranscodedImage("", photo.Url, sizes.sdWidth, sizes.sdHeight)
        photo.HDPosterURL = photo.server.TranscodedImage("", photo.Url, sizes.hdWidth, sizes.hdHeight)
    end if

    ' Transcode if necessary
    if photo.media.Count() > 0 then
        format = UCase(firstOf(photo.media[0].container, "JPEG"))
        ' JPEG and PNG are documented, GIF appears to work fine
        if format <> "JPEG" AND format <> "PNG" AND format <> "GIF" then
            Debug("Transcoding photo to JPEG from " + format)
            device = CreateObject("roDeviceInfo")
            size = device.GetDisplaySize()
            photo.Url = photo.server.TranscodedImage("", photo.Url, size.w.toStr(), size.h.toStr())
        end if
    end if

    return photo
End Function

Function ParsePhotoMedia(photoItem) As Object
    mediaArray = CreateObject("roArray", 5, true)
    for each MediaItem in photoItem.Media
        media = CreateObject("roAssociativeArray")

        media.identifier = MediaItem@id
        media.container = MediaItem@container
        media.width = MediaItem@width
        media.height = MediaItem@height
        media.aspectratio = MediaItem@aspectRatio

        media.parts = CreateObject("roArray", 2, true)
        for each MediaPart in MediaItem.Part
            part = CreateObject("roAssociativeArray")
            part.id = MediaPart@id
            part.key = MediaPart@key

            media.parts.Push(part)
        next

        media.preferredPart = media.parts[0]
        mediaArray.Push(media)
    next

    return mediaArray
End Function
