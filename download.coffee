request = require("request")
fs = require("fs")
async = require("async")
path = require("path")

outputDir = "output"
outputPath = path.join(__dirname, "output")

grabVideo = (videoUrl, fileName, cb) ->
    console.log "Grabbing video file from #{videoUrl}"
    request(videoUrl, =>
        cb()
    ).pipe(fs.createWriteStream(path.join(outputPath, fileName)))


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
        grabVideo videoUrl, fileName, cb


grabCourse = (courseUrl, cb) ->
    console.log "Grabbing course index from #{courseUrl}"
    request courseUrl, (err, res, body) =>
        if err? or res.statusCode!=200 then throw new Error "Could not retreive course preview index from #{courseUrl}"
        body = body.toString()
        lectureUrlMatch = ///"(https://class.coursera.org/algo/lecture/preview_view\?lecture_id=\d+)"///ig
        fileIndex = 0
        grabLectureTasks = []
        while (lectureUrlMatches = lectureUrlMatch.exec(body))?
            if lectureUrlMatches.length<2 then throw new Error "Could not find a single lecture match. Are you sure you provided the right URL (#{courseUrl})?"
            lectureUrl = lectureUrlMatches[1]
            fileIndex++
            do (lectureUrl, fileIndex) =>
                grabLectureTasks.push (done) =>
                    grabLecture lectureUrl, "vid#{fileIndex}.mp4", done
        if fileIndex == 0 then throw new Error "Could not find a single lecture. Are you sure you provided the right URL (#{courseUrl})?"
        async.series grabLectureTasks, =>
            cb()


courseUrl = """https://class.coursera.org/algo/lecture/preview/index"""
fs.exists outputPath, (exists) =>
    if exists then throw new Error "Output folder #{outputPath} already exists. Please remove it manually and rerun me."
    fs.mkdir outputPath, =>
        grabCourse courseUrl, =>
            console.log "Done download course. Enjoy."
