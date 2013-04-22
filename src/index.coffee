fs = require "fs"

module.exports = class JavaScriptPreprocess
  brunchPlugin: yes
  type: 'javascript'
  extension: 'js'
  statementStack: []

  constructor: (@config) ->
    null

  onCompile: (generatedFiles) ->
    regexExt = /\.js$/
    regexIf = /\/\/ #BRUNCH_IF (.*?)\s/
    regexElse = /\/\/ #BRUNCH_ELSE/
    regexElif = /\/\/ #BRUNCH_ELIF (.*?)\s/
    regexEndIf = /\/\/ #BRUNCH_ENDIF/

    for file in generatedFiles
      do (file) =>
        # Only process js files
        if file.path.search(regexExt) >= 0
          data = fs.readFileSync file.path, "utf8"

          while matchedStmt = this.getNextStatement data
            # Remove the statement from the string
            strBeforeStatement = data.substring(0, matchedStmt.index)
            strAfterStatement = data.substring(matchedStmt.index + matchedStmt.statementLength, data.length).trim()
            data = strBeforeStatement + strAfterStatement

            # Determine whether or not to keep this section
            switch matchedStmt.statement
              when 'if'
                matchedStmt.match = this.evaluateTarget @config.buildTarget, matchedStmt.target
                this.statementStack.push matchedStmt
              when 'elif'
                # If any of the previous statements had a match, then this one gets discarded
                matchedStmt.match = true
                for stmt in this.statementStack
                  if stmt.match
                    matchedStmt.match = false
                    break

                # If a previous statement didn't have a match, evaluate this statement's target
                if matchedStmt.match
                  matchedStmt.match = this.evaluateTarget @config.buildTarget, matchedStmt.target

                this.statementStack.push matchedStmt
              when 'else'
                # If any of the previous statements had a match, then this one gets discarded
                matchedStmt.match = true
                for stmt in this.statementStack
                  if stmt.match
                    matchedStmt.match = false
                    break

                this.statementStack.push matchedStmt
              when 'endif'
                # Remove or keep sections as statements get popped off the stack
                lastIndex = matchedStmt.index
                while this.statementStack.length > 0
                  stmt = this.statementStack.pop()
                  if !stmt.match
                    strBefore = data.substring(0, stmt.index)
                    strAfter = data.substring(lastIndex, data.length)
                    data = strBefore + strAfter

                  # Update index position so next statement that gets processed
                  # will know the bounds of that section
                  lastIndex = stmt.index

          fs.writeFileSync file.path, data

  evaluateTarget: (buildTarget, evalTarget) ->
    # TODO: Any need to parse for &&?
    targets = evalTarget.split('||')
    for target in targets
      target = target.trim()
      if buildTarget == target
        return true

    return false

  getNextStatement: (data) ->
    regexIf = /\/\/ #BRUNCH_IF \((.*?)\)\s/
    regexElse = /\/\/ #BRUNCH_ELSE/
    regexElif = /\/\/ #BRUNCH_ELIF \((.*?)\)\s/
    regexEndif = /\/\/ #BRUNCH_ENDIF/

    lastStmtIndex = 0
    lastStmt = this.getTopElement this.statementStack
    if (lastStmt)
      lastStmtIndex = lastStmt.index

    matchIf = regexIf.exec data
    matchElse = regexElse.exec data
    matchElif = regexElif.exec data
    matchEndif = regexEndif.exec data

    nextStmtObj = null
    nextIndex = Number.POSITIVE_INFINITY;
    statementLength = 0
    if matchIf && matchIf.index > lastStmtIndex && matchIf.index < nextIndex
      nextIndex = matchIf.index
      nextStmtObj =
        statement: 'if'
        statementLength: matchIf[0].length
        index: matchIf.index
        target: matchIf[1]

    if matchElse && matchElse.index > lastStmtIndex && matchElse.index < nextIndex
      nextIndex = matchElse.index
      nextStmtObj =
        statement: 'else'
        statementLength: matchElse[0].length
        index: matchElse.index

    if matchElif && matchElif.index > lastStmtIndex && matchElif.index < nextIndex
      nextIndex = matchElif.index
      nextStmtObj =
        statement: 'elif'
        statementLength: matchElif[0].length
        index: matchElif.index
        target: matchElif[1]

    if matchEndif && matchEndif.index > lastStmtIndex && matchEndif.index < nextIndex
      nextIndex = matchEndif.index
      nextStmtObj =
        statement: 'endif'
        statementLength: matchEndif[0].length
        index: matchEndif.index

    if !nextStmtObj && lastStmt
      throw new Error 'Malformed brunch preprocess conditional. ' + lastStmt.statement + ' statement not closed'

    return nextStmtObj

  getTopElement: (arr) ->
    lastIndex = arr.length - 1
    if lastIndex >= 0
      return arr[lastIndex]
    else
      return null