# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import strutils
import re
import os
import parseopt
import tables
import algorithm
import json


const IS_DEBUG = false


const colorCodeReset  = "\x1B[0m";
const colorCodesMap = {
    "":        (fg:  0, bg:  0),
    "black":   (fg: 30, bg: 40),
    "red":     (fg: 31, bg: 41),
    "green":   (fg: 32, bg: 42),
    "yellow":  (fg: 33, bg: 43),
    "blue":    (fg: 34, bg: 44),
    "magenta": (fg: 35, bg: 45),
    "cyan":    (fg: 36, bg: 46),
    "white":   (fg: 37, bg: 47),
}.toTable()


type HighlightConfigEntry = ref object of RootObj
    regexp:  string
    colorFg: string
    colorBg: string

type HighlightCommand = ref object of RootObj
    inputFile:          File
    isHelp:             bool
    isDebug:            bool
    isInitConfig:       bool
    isPrintLineNumbers: bool
    configEntries: seq[HighlightConfigEntry]

type Breakpoint = tuple
    pos:     int
    prio:    int
    isReset: bool
    colorFg: string
    colorBg: string


proc newHighlightCommand*(withConfig: bool = true): HighlightCommand =
    result = HighlightCommand()
    result.inputFile = stdin
    result.isDebug   = IS_DEBUG
    if not withConfig:
        return result
    let appConfigFilename = "." & os.extractFilename(os.getAppFilename()) & ".json"
    if os.existsFile(appConfigFilename):
        let jsonApp = json.parseFile(appConfigFilename)
        if jsonApp.hasKey("isDebug"):
            result.isDebug = jsonApp["isDebug"].getBool(false)
        if jsonApp.hasKey("isPrintLineNumbers"):
            result.isPrintLineNumbers = jsonApp["isPrintLineNumbers"].getBool(false)
        if jsonApp.hasKey("colorEntries"):
            let jsonEntries = jsonApp["colorEntries"].getElems()
            for jsonEntry in jsonEntries:
                let entryStr = jsonEntry.getStr()
                let configParts = entryStr.split(':', 3)
                let configEntry = HighlightConfigEntry()
                if configParts.len < 2:
                    assert(false)
                configEntry.regexp = configParts[0]
                if configParts.len > 1 and configParts[1].strip != "":
                    configEntry.colorFg = configParts[1]
                if configParts.len > 2 and configParts[2].strip != "":
                    configEntry.colorBg = configParts[2]
                result.configEntries.add(configEntry)



proc newHighlightCommandFromCliArgs*(args: seq[TaintedString], withConfig: bool = true): HighlightCommand =
    result = newHighlightCommand(withConfig=withConfig)

    var optParser = initOptParser(args)
    for optKind, optKey, optVal in optParser.getopt():
        case optKind:
        of cmdShortOption, cmdLongOption:
            if (optKey == "h" or optKey == "help"):
                result.isHelp = true
            elif (optKey == "e" or optKey == "entry"):
                let configParts = optVal.split(':', 3)
                let configEntry = HighlightConfigEntry()
                if configParts.len < 2:
                    assert(false)
                configEntry.regexp = configParts[0]
                if configParts.len > 1 and configParts[1].strip != "":
                    configEntry.colorFg = configParts[1]
                if configParts.len > 2 and configParts[2].strip != "":
                    configEntry.colorBg = configParts[2]
                result.configEntries.add(configEntry)
            elif (optKey == "n" or optKey == "numbers"):
                result.isPrintLineNumbers = true
            elif (optKey == "i" or optKey == "init"):
                result.isInitConfig = true
            elif (optKey == "d" or optKey == "debug"):
                result.isDebug = true
            else:
                assert(false)
        of cmdArgument:
            assert(false)
        of cmdEnd:
            assert(false) # Should not occour
    return result



proc newHighlightCommandFromCliArgs*(withConfig: bool = true): HighlightCommand =
    return newHighlightCommandFromCliArgs(os.commandLineParams(), withConfig=withConfig)



proc doPrintHelp(highlightCommand: HighlightCommand) =
    let appName = os.extractFilename(os.getAppFilename())
    echo "Usage: " & appName & " [OPTIONS]"
    echo ""
    echo "Colorizes the input given by stdin, according to the privided -e= arguments."
    echo ""
    echo "Options:"
    echo "  -h  | --help        Print this help"
    echo "  -e= | --entry=      Adds a highlight-Entry of the form 'REGEX:FgColor:BgColor' (see Colors section)"
    echo "  -n  | --numbers     Print line numbers"
    echo "  -i  | --init        Creates config file " & appName & ".json with the given arguments"
    echo "  -v  | --version     Print program version"
    echo "  -d  | --debug       Print debug output"
    echo ""
    echo "Colors:"
    echo "  black | white | red | green | blue | yellow | cyan | magenta"
    echo ""
    echo "Example:"
    echo "  $ cat aLogFile.log | highligter -e='^E.*:red' -e='^W.*:yellow -e'^I.*:white' -e='^D.*|^T.*:black' -e='SampleService:blue'"



proc doCreateConfig(self: HighlightCommand) =
    let appConfigFilename = "." & os.extractFilename(os.getAppFilename()) & ".json"
    echo "Erstelle " & appConfigFilename
    let jsonApp = newJObject()
    #if self.isDebug:
    #    jsonApp.add( "isDebug", newJBool(true) )
    if self.isPrintLineNumbers:
        jsonApp.add( "isPrintLineNumbers", newJBool(true) )
    let jsonEntries = newJArray()
    for configEntry in self.configEntries:
        let jsonEntry = newJString(configEntry.regexp & ":" & configEntry.colorFg & ":" & configEntry.colorBg)
        jsonEntries.add(jsonEntry)
    jsonApp.add( "colorEntries", jsonEntries )
    if self.isDebug:
        echo jsonApp.pretty(indent=4)
    writeFile appConfigFilename, jsonApp.pretty(indent=4)
    echo appConfigFilename, " erstellt"



proc doColorizeInputLines(highlightCommand: HighlightCommand) =
    var lineNumber = 0

    for line in highlightCommand.inputFile.lines():

        # Zeilennummer ausgeben ...
        if highlightCommand.isPrintLineNumbers:
            lineNumber += 1
            if lineNumber <  10: stdout.write " "
            if lineNumber < 100: stdout.write " "
            stdout.write $lineNumber
            stdout.write ": "

        var breakpoints: seq[Breakpoint] = @[]

        # Get all Breakpoints of all Highlight-Configs ...
        for idxCe in 0 ..< highlightCommand.configEntries.len:
            let configEntry = highlightCommand.configEntries[idxCe]
            let configRegex = re(configEntry.regexp)
            var lineStart = 0
            while true:
                let bounds = line.findBounds(configRegex, start=lineStart)
                if bounds.first == -1:
                    break
                lineStart = bounds.last + 1
                breakpoints.add((
                    pos:     bounds.first,
                    prio:    idxCe,
                    isReset: false,
                    colorFg: configEntry.colorFg,
                    colorBg: configEntry.colorBg
                ))
                breakpoints.add((
                    pos:     bounds.last + 1,
                    prio:    idxCe,
                    isReset: true,
                    colorFg: configEntry.colorFg,
                    colorBg: configEntry.colorBg
                ))

        # Wenn es nichts anzuwenden gibt, dann die Zeile ausgeben und nächste ...
        if breakpoints.len == 0:
            stdout.write(line)
            stdout.write("\n")
            continue

        # Sortiere Line-Configs nach Anfagspos, dann nach Endpos ...
        breakpoints.sort(proc (a, b: Breakpoint): int =
            if a.pos < b.pos:
                return -1
            if a.pos > b.pos:
                return 1
            if a.isReset != b.isReset:
                if b.isReset:
                    return 1
                else:
                    return -1
            if a.prio < b.prio:
                return -1
            else:
                return 1
            return 0
        )

        if highlightCommand.isDebug:
            stdout.write "Vorher:\n"
            for breakpoint in breakpoints:
                stdout.write "  ", $breakpoint, "\n"

        if highlightCommand.isDebug:
            echo "Simplifying:"

        # Breakpoint-Liste Reset-Points aufräumen ...
        if breakpoints.len >= 1:
            var newBreakpoints:    seq[Breakpoint] = @[]
            var activeBreakpoints: seq[Breakpoint] = @[]
            for idxBrCurr in 0 ..< breakpoints.len:
                let brCurr = breakpoints[idxBrCurr]
                var brNew: Breakpoint

                if not brCurr.isReset:
                    ## Reguläre Farbpunkte immer übernehmen, aber aufsteigend sortiert nach Priorität ...
                    activeBreakpoints.add( brCurr )
                    activeBreakpoints.sort(proc (a, b: Breakpoint): int =
                        return -1 * (a.prio < b.prio).int  +  1 * (a.prio >= b.prio).int
                    )
                    #if highlightCommand.isDebug:
                    #    stdout.write "Active Breakpoints:\n"
                    #    for breakpoint in activeBreakpoints:
                    #        stdout.write "  ", $breakpoint, "\n"
                    brNew = activeBreakpoints[activeBreakpoints.len-1]
                    brNew.pos  = brCurr.pos
                    #brNew.prio = brCurr.prio

                elif brCurr.isReset and activeBreakpoints.len == 0:
                    ## Resetpunkt, aber keine Farbe aktiv -> reset übernehmen ...
                    brNew = brCurr

                elif brCurr.isReset and activeBreakpoints.len > 0:
                    # Farbpunkt aus der Liste der aktiven Farbpunkte entfernen ...
                    var idxBrActive = activeBreakpoints.len-1
                    while idxBrActive >= 0:
                        var isEqual = true
                        isEqual = isEqual and activeBreakpoints[idxBrActive].prio == brCurr.prio
                        if isEqual:
                            break
                        idxBrActive.dec
                    if idxBrActive >= 0:
                        activeBreakpoints.delete(idxBrActive)

                    # Der aktuelle Resetpoint stimmt mit der aktuellen Farbe überein ...
                    if activeBreakpoints.len > 0:
                        brNew = activeBreakpoints[activeBreakpoints.len-1]
                        brNew.pos = brCurr.pos
                    elif activeBreakpoints.len == 0:
                        # Wenn kein aktiver Breakpoint vorhanden ist, den aktuellen Resetpoint übernehmen ...
                        brNew = brCurr

                # Neuen Farbpunkt verwerfen, wenn der vorherige Farbpunkt die selbe Ausprägung hat ...
                if not brNew.isReset and newBreakpoints.len > 0:
                    let brPrev = newBreakpoints[newBreakpoints.len-1]
                    if not brPrev.isReset and brPrev.colorFg == brNew.colorFg and brPrev.colorBg == brNew.colorBg:
                        continue

                ## Neuen Farb-/Resetpunkt verwerfen, wenn der nachfolgender Farb-/Resetpunkt auf die gleiche Stelle zeigt ...
                if idxBrCurr < breakpoints.len-1:
                    let brNext = breakpoints[idxBrCurr+1]
                    if brNext.pos == brNew.pos:
                        continue

                if highlightCommand.isDebug:
                    echo "  +++ ", brNew

                # Neuen Punkt übernehmen ...
                newBreakpoints.add( brNew )

                # end for each breakpoint

            breakpoints = newBreakpoints

        if highlightCommand.isDebug:
            stdout.write "Nacher:\n"
            for breakpoint in breakpoints:
                stdout.write "  ", $breakpoint, "\n"

        block:
            var lineStart = 0
            for breakpoint in breakpoints:
                if lineStart < breakpoint.pos:
                    let linePart = line[lineStart..<breakpoint.pos]
                    stdout.write linePart
                lineStart = breakpoint.pos
                if breakpoint.isReset:
                    stdout.write(colorCodeReset)
                    continue
                let colorCodeFg = colorCodesMap[breakpoint.colorFg]
                let colorCodeBg = colorCodesMap[breakpoint.colorBg]
                if   colorCodeFg.fg == 0 and colorCodeBg.bg != 0:
                    stdout.write "\x1B[0;" & $colorCodeFg.fg & ";" & $colorCodeBg.bg & "m"
                elif colorCodeFg.fg != 0 and colorCodeBg.bg == 0:
                    stdout.write "\x1B[0;" & $colorCodeFg.fg & "m"
                elif colorCodeFg.fg != 0 and colorCodeBg.bg != 0:
                    stdout.write "\x1B[0;" & $colorCodeBg.bg & "m"
                elif colorCodeFg.fg == 0 and colorCodeBg.bg == 0:
                    stdout.write(colorCodeReset)
                if highlightCommand.isDebug:
                    stdout.write "|"
            if lineStart < line.len:
                let linePart = line[lineStart..<line.len]
                stdout.write linePart
            #stdout.write colorCodeReset
            stdout.write "\n"



proc doExecute*(highlightCommand: HighlightCommand): int =
    if highlightCommand.isHelp:
        highlightCommand.doPrintHelp()
        return 0
    elif highlightCommand.isInitConfig:
        highlightCommand.doCreateConfig()
        return 0
    else:
        highlightCommand.doColorizeInputLines()
        return 0



when isMainModule:
    proc highlight_main() =
        let highlightCommand = newHighlightCommandFromCliArgs()
        let execResult = highlightCommand.doExecute()
        system.quit(execResult)
    highlight_main()
