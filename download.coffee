request = require("request")
fs = require("fs")


grabVideo = (videoUrl, fileName, cb) ->
    console.log "Grabbing video file from #{videoUrl}"
    console.log(fileName)
    request(videoUrl).pipe(fs.createWriteStream(fileName))


grabLecture = (lectureUrl, fileName, cb) ->
    console.log "Grabbing lecture from #{lectureUrl}"
    request lectureUrl, (err, res, body) =>
        if err? or res.statusCode!=200 then throw new Error "Could not retreive lecture from #{lectureUrl}"
        body = body.toString()
        videoUrlMatch = /<source type=\"video\/mp4\" src=\"([a-zA-Z0-9-\._~:\/\?\[\]%@!$&\(\)\*\+,;=]+)\"><\/source>/ig
        videoUrlMatches = videoUrlMatch.exec(body)
        if !videoUrlMatches? then throw new Error "Could not find a single video. Are you sure you provided the right URL?"
        if videoUrlMatches.length<2 then throw new Error "Could not find a single video match. Are you sure you provided the right URL?"
        videoUrl = videoUrlMatches[1]
        grabVideo videoUrl, fileName
        cb()


grabCourse = (courseUrl, cb) ->
    console.log "Grabbing course index from #{courseUrl}"
    request courseUrl, (err, res, body) =>
        if err? or res.statusCode!=200 then throw new Error "Could not retreive course preview index from #{courseUrl}"
        body = body.toString()
        lectureUrlMatch = ///"(https://class.coursera.org/algo/lecture/preview_view\?lecture_id=\d+)"///ig
        fileIndex = 0
        while (lectureUrlMatches = lectureUrlMatch.exec(body))?
            if fileIndex==1 then break
            if lectureUrlMatches.length<2 then throw new Error "Could not find a single lecture match. Are you sure you provided the right URL (#{courseUrl})?"
            lectureUrl = lectureUrlMatches[1]
            grabLecture lectureUrl, "vid#{fileIndex++}.mp4", =>
        if fileIndex == 0 then throw new Error "Could not find a single lecture. Are you sure you provided the right URL (#{courseUrl})?"
        cb()


courseUrl = """https://class.coursera.org/algo/lecture/preview/index"""
grabCourse(courseUrl, =>)
