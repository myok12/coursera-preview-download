request = require("request")
fs = require("fs")
async = require("async")
path = require("path")

outputDir = "output"
outputPath = path.join(__dirname, "output")

grabVideo = (videoUrl, fileNamePrefix, cb, i, total) ->
    # https://d19vezwu8eufl6.cloudfront.net/algo1/recoded_videos%2F5.1%20djikstra-intro%20%5B6143299e%5D%20.mp4
    # \s*(?:\[.+\])\s*
    descMatches = /recoded_videos\/(.+)\.mp4/.exec(unescape(videoUrl))
    if !descMatches? or descMatches.length<2 then throw new Error "Could not find a video desc. Are you sure you provided the right URL (#{videoUrl})?"
    fileDesc = descMatches[1]
    fileDesc = fileDesc.replace(/\s*\[.+\]\s*/, "")
    fileDesc = fileDesc.trim()

    fileName = "#{fileNamePrefix}_#{fileDesc}.mp4"

    requestFile = ->
        console.log "Grabbing video file #{i} of #{total} from #{videoUrl}"
        request(videoUrl, ->
            cb()
        ).pipe(fs.createWriteStream(path.join(outputPath, fileName)))
    fs.exists outputPath, (exists) ->
        if exists
            requestFile()
        else
            fs.mkdir outputPath, ->
                requestFile()


grabLecture = (lectureUrl, fileName, cb, i, total) ->
    # https://class.coursera.org/algo/lecture/preview_view?lecture_id=65
    console.log "Grabbing lecture from #{lectureUrl}"
    request lectureUrl, (err, res, body) ->
        if err? or res.statusCode!=200 then throw new Error "Could not retreive lecture from #{lectureUrl}"
        body = body.toString()
        videoUrlMatch = /<source type=\"video\/mp4\" src=\"([a-zA-Z0-9-\._~:\/\?\[\]%@!$&\(\)\*\+,;=]+)\">/ig
        # <source type="video/mp4" src="https://d19vezwu8eufl6.cloudfront.net/algo1/recoded_videos%2F5.9%20hash-guts-1%20%5B389ce042%5D%20.mp4">
        videoUrlMatches = videoUrlMatch.exec(body)
        if !videoUrlMatches? or videoUrlMatches.length<2 then throw new Error "Could not find a single video. Are you sure you provided the right URL?"
        videoUrl = videoUrlMatches[1]
        grabVideo videoUrl, fileName, cb, i, total


grabCourse = (courseUrl, cb) ->
    # https://class.coursera.org/algo/lecture/preview/index
    courseNameMatches = /https:\/\/class.coursera.org\/(.+)\/lecture\//i.exec(courseUrl)
    if !courseNameMatches? or courseNameMatches.length<2 then throw new Error "Could not extract lecture name from url #{courseUrl}. Are you sure you provided the right URL ? Should be something like \"https://class.coursera.org/algo/lecture/preview/index\""
    courseName = courseNameMatches[1]
    console.log "Grabbing course index from #{courseUrl}"
    request courseUrl, (err, res, body) ->
        if err? or res.statusCode!=200 then throw new Error "Could not retreive course preview index from #{courseUrl}"
        body = body.toString()
        lectureUrlMatch = ///"(https://class.coursera.org/.+/lecture/preview_view\?lecture_id=\d+)"///ig
        fileIndex = 0
        files = 0
        grabLectureTasks = []
        # https://class.coursera.org/algo/lecture/preview_view?lecture_id=65
        while (lectureUrlMatches = lectureUrlMatch.exec(body))?
            if lectureUrlMatches.length<2 then throw new Error "Could not find a single lecture match. Are you sure you provided the right URL (#{courseUrl})?"
            lectureUrl = lectureUrlMatches[1]
            fileIndex++
            files++
            do (lectureUrl, fileIndex) ->
                grabLectureTasks.push (done) ->
                    grabLecture lectureUrl, "#{courseName}_#{fileIndex}", done, fileIndex, files
        if fileIndex == 0 then throw new Error "Could not find a single lecture. Are you sure you provided the right URL (#{courseUrl})?"
        async.series grabLectureTasks, ->
            cb()


readCourseUrl = (cb) ->
    process.stdin.resume()
    #process.stdin.setEncoding('utf8');

    console.log "Please enter the URL of the coursera course you wish to grab all preview videos,"
    console.log "e.g. \"https://class.coursera.org/algo/lecture/preview/index\" :"

    process.stdin.on 'data', (chunk) ->
        cb chunk.toString()
        process.stdin.pause()

fs.exists outputPath, (exists) ->
    if exists then throw new Error "Output folder #{outputPath} already exists. Please remove it manually and rerun me."
    readCourseUrl (courseUrl) ->
        grabCourse courseUrl, ->
            console.log "Done downloading course. Enjoy."
