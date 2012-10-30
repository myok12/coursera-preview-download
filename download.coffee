request = require("request")
fs = require("fs")
async = require("async")
path = require("path")

outputDir = "output"
outputPath = path.join(__dirname, "output")

grabVideo = (videoUrl, fileNamePrefix, cb) ->
    # https://d19vezwu8eufl6.cloudfront.net/algo1/recoded_videos%2F5.1%20djikstra-intro%20%5B6143299e%5D%20.mp4
    descMatches = /recoded_videos\/\d+\.+\d+\s+(.+)\s+\[.+\]\s+\.mp4/.exec(unescape(videoUrl))
    if !descMatches? or descMatches.length<2 then throw new Error "Could not find a video desc. Are you sure you provided the right URL (#{videoUrl}?"
    fileName = "#{fileNamePrefix}_#{descMatches[1]}.mp4"
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
        if !videoUrlMatches? or videoUrlMatches.length<2 then throw new Error "Could not find a single video. Are you sure you provided the right URL?"
        videoUrl = videoUrlMatches[1]
        grabVideo videoUrl, fileName, cb


grabCourse = (courseUrl, cb) ->
    # https://class.coursera.org/algo/lecture/preview/index
    courseNameMatches = /https:\/\/class.coursera.org\/(.+)\/lecture\//i.exec(courseUrl)
    if !courseNameMatches? or courseNameMatches.length<2 then throw new Error "Could not extract lecture name from url #{courseUrl}. Are you sure you provided the right URL ? Should be something like \"https://class.coursera.org/algo/lecture/preview/index\""
    courseName = courseNameMatches[1]
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
                    grabLecture lectureUrl, "#{courseName}#{fileIndex}.mp4", done
        if fileIndex == 0 then throw new Error "Could not find a single lecture. Are you sure you provided the right URL (#{courseUrl})?"
        async.series grabLectureTasks, =>
            cb()


courseUrl = """https://class.coursera.org/algo/lecture/preview/index"""
fs.exists outputPath, (exists) =>
    if exists then throw new Error "Output folder #{outputPath} already exists. Please remove it manually and rerun me."
    fs.mkdir outputPath, =>
        grabCourse courseUrl, =>
            console.log "Done download course. Enjoy."
