fs = require "fs"

module.exports = class JavaScriptPreprocess
  brunchPlugin: yes
  type: 'javascript'
  extension: 'js'

  constructor: (@config) ->
    null

  onCompile: (generatedFiles) ->
    regexExt = /\.js$/
    regexIf = /\/\/ #BRUNCH_IF (.*?)\s/
    regexEndIf = /\/\/ #BRUNCH_ENDIF/

    for file in generatedFiles
      do (file) =>
        # Only process js files
        if file.path.search(regexExt) >= 0
          data = fs.readFileSync file.path, "utf8"

          # Search for first #BRUNCH_IF
          while matchIf = regexIf.exec(data)
            # Find matching #BRUNCH_ENDIF
            matchEndIf = regexEndIf.exec(data)
            if matchEndIf.index <= matchIf.index
              throw new Error 'Malformed Brunch preprocess conditional'

            target = matchIf[1]
            if target == @config.buildTarget
              targetMatches = true
            else
              targetMatches = false

            ifLength = '// #BRUNCH_IF '.length + target.length
            endifLength = '// #BRUNCH_ENDIF'.length
            if targetMatches
              # Remove only the BRUNCH_* lines
              strBeforeIf = data.substring(0, matchIf.index)
              strIfContents = data.substring(matchIf.index + ifLength, matchEndIf.index)
              strAfterIf = data.substring(matchEndIf.index + endifLength, data.length)
              data = strBeforeIf + strIfContents + strAfterIf
            else
              # Remove the BRUNCH_* lines and the content in between
              data = data.substring(0, matchIf.index) + data.substring(matchEndIf.index + endifLength, data.length)

          fs.writeFileSync file.path, data