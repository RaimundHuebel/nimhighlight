## Command containing the Implementation of the CLI-Tool highlighter.
##
## author: Raimund Hübel

import parseopt
import strutils
import sequtils
import algorithm
import re
import os
import tables
import json


# CompileTime-Var to allow Debug-Mode in the Application
# flag: -d:allow_debug_mode
# see: https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-compile-time-define-pragmas
const allow_debug_mode {.booldefine.}: bool = false
const ALLOW_DEBUG_MODE: bool = allow_debug_mode


# Common ASCII Escape-Code to reset the console.
const colorCodeReset  = "\x1B[0m";


# ASCII-Escape-Codes to highlight lines, which does not have a hit ...
#LATER? const colorNumberOfNoHitLine = "\x1B[0;37m"


# Maps the Colornames to its ASCII-Color-Codes for Foreground/Background.
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
    ## Class which describes an colorization-Entry, provided by cli-args or config-file
    regexp:  string
    colorFg: string
    colorBg: string

type HighlightCommand* = ref object of RootObj
    ## HighlighterCommand, representing the Highlighter-Program in Object-Form
    inputFile:          File
    isHelp:             bool
    isInitConfig:       bool
    isPrintLineNumbers: bool
    isPrintVersion:     bool
    isPrintHitsOnly:    bool
    configErrors:       seq[string]
    when ALLOW_DEBUG_MODE:
        isDebug:        bool
    configEntries: seq[HighlightConfigEntry]

type Breakpoint = tuple
    ## Colorbreakpoints which are detected by applying all Regex to an input line.
    pos:     int
    prio:    int
    isReset: bool
    colorFg: string
    colorBg: string



proc newHighlightCommand*(): HighlightCommand =
    ## Provides a HighlighterCommand. The returned Object can then be configured by using the
    ## provided init...-Methods.
    result = HighlightCommand()
    result.inputFile = stdin
    result.configErrors = @[]
    when ALLOW_DEBUG_MODE:
        result.isDebug   = false


proc initWithConfigFile*(
    self: HighlightCommand,
    configFilepath: string
  ): HighlightCommand {.discardable.}  =
    ## Initializes the Command with the given Config-File.
    if not os.existsFile(configFilepath):
        self.configErrors.add("config-file: '" & configFilepath & "' does not exist")
        return
    let jsonApp = json.parseFile(configFilepath)
    when ALLOW_DEBUG_MODE:
        if jsonApp.hasKey("isDebug"):
            self.isDebug = jsonApp["isDebug"].getBool(false)
    if jsonApp.hasKey("isPrintLineNumbers"):
        self.isPrintLineNumbers = jsonApp["isPrintLineNumbers"].getBool(false)
    if jsonApp.hasKey("isPrintHitsOnly"):
        self.isPrintHitsOnly = jsonApp["isPrintHitsOnly"].getBool(false)
    if jsonApp.hasKey("colorEntries"):
        let jsonEntries = jsonApp["colorEntries"].getElems()
        for jsonEntry in jsonEntries:
            let entryStr = jsonEntry.getStr()
            let configParts = entryStr.split(':', 3)
            let configEntry = HighlightConfigEntry()
            if configParts.len < 2:
                self.configErrors.add("invalid color-entry in config-file (" & configFilepath & "): '" & entryStr & "'")
                continue
            configEntry.regexp = configParts[0]
            if configParts.len > 1 and configParts[1].strip != "":
                configEntry.colorFg = configParts[1]
            if configParts.len > 2 and configParts[2].strip != "":
                configEntry.colorBg = configParts[2]
            if configEntry.colorFg == "" and configEntry.colorBg == "":
                self.configErrors.add("invalid color-entry in config-file (" & configFilepath & "): '-" & entryStr & "' - no colors given")
                continue
            if not colorCodesMap.hasKey(configEntry.colorFg) or not colorCodesMap.hasKey(configEntry.colorBg):
                if not colorCodesMap.hasKey(configEntry.colorFg):
                    self.configErrors.add("invalid color-codein config-file (" & configFilepath & "): '" & configEntry.colorFg & "'")
                if not colorCodesMap.hasKey(configEntry.colorBg):
                    self.configErrors.add("invalid color-codein config-file (" & configFilepath & "): '" & configEntry.colorBg & "'")
                continue
            self.configEntries.add(configEntry)
    return self


proc initWithDefaultConfigFiles*(
    self: HighlightCommand,
): HighlightCommand {.discardable.} =
    ## Initializes the Command with the default config files, if existing, which are evaluated in following order:
    ## 1. $APPDIR/.highlight.json
    ## 2. $HOME/.config/highlight/highlight.json
    ## 3. $PWD/.highlight.json
    let appFilename = os.splitFile(os.getAppFilename()).name
    let configFilepaths = @[
        # $APPDIR/.highlight.json
        os.splitFile(os.getAppFilename()).dir & os.DirSep & "." & appFilename & ".json",
        # $HOME/.config/highlight/highlight.json
        os.getConfigDir() & appFilename & os.DirSep & appFilename & ".json",
        # $PWD/.highlight.json
        os.getCurrentDir() & os.DirSep & "." & appFilename & ".json",
      ].deduplicate()
    for configFilepath in configFilepaths:
        if os.existsFile(configFilepath):
            self.initWithConfigFile(configFilepath)
    return self


proc initWithCliArgs*(
    self: HighlightCommand,
    args: seq[TaintedString],
    ignoreArguments: bool = false,
    ignoreUnknownOptions: bool = false
  ): HighlightCommand {.discardable.}  =
    ## Initializes the Command from the given CLI-Args.
    var optParser = initOptParser(args)
    for optKind, optKey, optVal in optParser.getopt():
        case optKind:
        of cmdShortOption, cmdLongOption:
            if (optKey == "h" or optKey == "help"):
                self.isHelp = true
            elif (optKey == "e" or optKey == "entry"):
                let configParts = optVal.split(':', 3)
                if configParts.len < 2:
                    self.configErrors.add("invalid color-entry: '-" & optKey & "=" & optVal & "'")
                    continue
                let configEntry = HighlightConfigEntry()
                configEntry.regexp = configParts[0]
                if configParts.len > 1 and configParts[1].strip != "":
                    configEntry.colorFg = configParts[1]
                if configParts.len > 2 and configParts[2].strip != "":
                    configEntry.colorBg = configParts[2]
                if configEntry.colorFg == "" and configEntry.colorBg == "":
                    self.configErrors.add("invalid color-entry: '-" & optKey & "=" & optVal & "' - no colors given")
                    continue
                if not colorCodesMap.hasKey(configEntry.colorFg) or not colorCodesMap.hasKey(configEntry.colorBg):
                    if not colorCodesMap.hasKey(configEntry.colorFg):
                        self.configErrors.add("invalid color-code: '" & configEntry.colorFg & "'")
                    if not colorCodesMap.hasKey(configEntry.colorBg):
                        self.configErrors.add("invalid color-code: '" & configEntry.colorBg & "'")
                    continue
                self.configEntries.add(configEntry)
            elif (optKey == "n" or optKey == "numbers"):
                self.isPrintLineNumbers = true
            elif (optKey == "i" or optKey == "init"):
                self.isInitConfig = true
            elif (optKey == "v" or optKey == "version"):
                self.isPrintVersion = true
            elif (optKey == "o" or optKey == "only"):
                self.isPrintHitsOnly = true
            elif (optKey == "d" or optKey == "debug"):
                when ALLOW_DEBUG_MODE:
                    self.isDebug = true
            elif not ignoreUnknownOptions:
                if optVal != "":
                    self.configErrors.add("unknown option: " & optKey & "=" & optVal)
                else:
                    self.configErrors.add("unknown option: " & optKey)
        of cmdArgument:
            if not ignoreArguments:
                self.configErrors.add("unknown argument: " & optKey)
        of cmdEnd:
            self.configErrors.add("wtf? cmdEnd should not happen")
    return self



proc initWithCliArgs*(
    self: HighlightCommand,
    ignoreArguments: bool = false,
    ignoreUnknownOptions: bool = false
  ): HighlightCommand {.discardable.}  =
    ## Initializes the Command with the CLI-Args when the program was executed.
    self.initWithCliArgs(
        os.commandLineParams(),
        ignoreArguments,
        ignoreUnknownOptions
    )
    return self



proc hasConfigErrors*(self: HighlightCommand): bool =
    ## Tells if there are errors in the configuration of this command.
    ## This can either happen through errors in CLI-Args or errors in the Config-Files.
    ## If this Method returns true, then the execution of the Command is stopped,
    ## and the Errors are printed to the user.
    return self.configErrors.len > 0


proc doPrintConfigErrors(self: HighlightCommand) =
    echo "The are config errors:"
    for errorLine in self.configErrors:
        echo "  - ", errorLine
    echo "Use --help to get informations how to use this command."


proc doPrintHelp(highlightCommand: HighlightCommand) =
    ## Prints the Help of the Application to the console.
    let appName = os.extractFilename(os.getAppFilename())
    echo "Usage: ", appName, " [OPTIONS]"
    echo ""
    echo "Colorizes the input given by stdin, according to the privided -e= arguments."
    echo ""
    echo "Options:"
    echo "  -h  | --help        Print this help"
    echo "  -e= | --entry=      Adds a highlight-Entry of the form 'REGEX:FgColor:BgColor' (see Colors section)"
    echo "  -n  | --numbers     Print line numbers"
    echo "  -o  | --only        Print only lines which have a hit of at least one color entry"
    echo "  -i  | --init        Creates config file ", appName, ".json with the given arguments"
    echo "  -v  | --version     Print program version"
    when ALLOW_DEBUG_MODE:
        echo "  -d  | --debug       Print debug output"
    echo ""
    echo "Colors:"
    echo "  black | white | red | green | blue | yellow | cyan | magenta"
    echo ""
    echo "Example:"
    echo "  $ cat aLogFile.log | highligter -e='^E.*:red' -e='^W.*:yellow -e'^I.*:white' -e='^D.*|^T.*:black' -e='SampleService:blue'"



when true:
    template currSourceDirectory(): string =
        os.normalizedPath(instantiationInfo(-1, true).filename / "..")

    proc getVersionString(): string {.compiletime.} =
        let execFile: string = os.normalizedPath(currSourceDirectory() / ".." / ".." / "scripts" / "get_version_string.sh" )
        let versionStr = staticExec(execFile)
        return versionStr

    const VERSION_STR: string = getVersionString()


proc doPrintVersion(highlightCommand: HighlightCommand) =
    ## Prints the Version of the Application to the console.
    echo VERSION_STR



proc doCreateConfig(self: HighlightCommand) =
    ## Creates a config file in the current working directory with the name '.highlight.json'.
    let appConfigFilename = "." & os.extractFilename(os.getAppFilename()) & ".json"
    echo "Erstelle " & appConfigFilename
    let jsonApp = newJObject()
    when ALLOW_DEBUG_MODE:
        if self.isDebug:
            jsonApp.add( "isDebug", newJBool(true) )
    if self.isPrintLineNumbers:
        jsonApp.add( "isPrintLineNumbers", newJBool(true) )
    if self.isPrintHitsOnly:
        jsonApp.add( "isPrintHitsOnly", newJBool(true) )
    let jsonEntries = newJArray()
    for configEntry in self.configEntries:
        let jsonEntry = newJString(configEntry.regexp & ":" & configEntry.colorFg & ":" & configEntry.colorBg)
        jsonEntries.add(jsonEntry)
    jsonApp.add( "colorEntries", jsonEntries )
    when ALLOW_DEBUG_MODE:
        if self.isDebug:
            echo jsonApp.pretty(indent=4)
    writeFile appConfigFilename, jsonApp.pretty(indent=4)
    echo appConfigFilename, " erstellt"



proc doColorizeInputLines(highlightCommand: HighlightCommand) =
    ## Reads the lines from stdin and colorizes it.
    ## Additionally does print line numbers if wished.
    var lineNumber = 0

    proc printLineNumber(isHit: bool) =
        if lineNumber <  10: stdout.write " "
        if lineNumber < 100: stdout.write " "
        #LATER? if not isHit:
        #LATER?     stdout.write colorNumberOfNoHitLine
        stdout.write $lineNumber
        stdout.write ": "
        #LATER? if not isHit:
        #LATER?     stdout.write colorCodeReset

    for line in highlightCommand.inputFile.lines():
        lineNumber += 1

        # Wenn es keine ConfigEntries gibt dann, einfach die Zeile ausgeben, falls gewünscht ...
        if highlightCommand.configEntries.len == 0:
            if not highlightCommand.isPrintHitsOnly:
                # Zeilennummer ausgeben, falls gewünscht ...
                if highlightCommand.isPrintLineNumbers:
                    printLineNumber(isHit=false)
                # Zeile ausgeben ...
                stdout.write(line)
                stdout.write("\n")
            continue

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

        # Wenn es nichts anzuwenden gibt dann und nur die Zeilen mit Treffer erlaubt sind, dann Abbruch ...
        if highlightCommand.isPrintHitsOnly and highlightCommand.configEntries.len == 0:
            break

        # Wenn es nichts anzuwenden gibt, dann die Zeile (falls gewünscht) und nächste ...
        if breakpoints.len == 0:
            if not highlightCommand.isPrintHitsOnly:
                # Zeilennummer ausgeben, falls gewünscht ...
                if highlightCommand.isPrintLineNumbers:
                    printLineNumber(isHit=false)
                # Zeile ausgeben ...
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

        when ALLOW_DEBUG_MODE:
            if highlightCommand.isDebug:
                stdout.write "Vorher:\n"
                for breakpoint in breakpoints:
                    stdout.write "  ", $breakpoint, "\n"

        when ALLOW_DEBUG_MODE:
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

                when ALLOW_DEBUG_MODE:
                    if highlightCommand.isDebug:
                        echo "  +++ ", brNew

                # Neuen Punkt übernehmen ...
                newBreakpoints.add( brNew )

                # end for each breakpoint

            breakpoints = newBreakpoints

        when ALLOW_DEBUG_MODE:
            if highlightCommand.isDebug:
                stdout.write "Nacher:\n"
                for breakpoint in breakpoints:
                    stdout.write "  ", $breakpoint, "\n"

        block:
            # Zeilennummer ausgeben, falls gewünscht ...
            if highlightCommand.isPrintLineNumbers:
                printLineNumber(isHit=true)

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
                if   colorCodeFg.fg != 0 and colorCodeBg.bg != 0:
                    stdout.write "\x1B[0;" & $colorCodeFg.fg & ";" & $colorCodeBg.bg & "m"
                elif colorCodeFg.fg != 0 and colorCodeBg.bg == 0:
                    stdout.write "\x1B[0;" & $colorCodeFg.fg & "m"
                elif colorCodeFg.fg != 0 and colorCodeBg.bg != 0:
                    stdout.write "\x1B[0;" & $colorCodeBg.bg & "m"
                elif colorCodeFg.fg == 0 and colorCodeBg.bg == 0:
                    stdout.write(colorCodeReset)
                when ALLOW_DEBUG_MODE:
                    if highlightCommand.isDebug:
                        stdout.write "|"
            if lineStart < line.len:
                let linePart = line[lineStart..<line.len]
                stdout.write linePart
            #stdout.write colorCodeReset
            stdout.write "\n"



proc doExecute*(self: HighlightCommand): int =
    ## Executes the Command according to its configuration.
    if self.isPrintVersion:
        self.doPrintVersion()
        return 0
    elif self.isHelp:
        self.doPrintHelp()
        return 0
    elif self.hasConfigErrors():
        self.doPrintConfigErrors()
        return 1
    elif self.isInitConfig:
        self.doCreateConfig()
        return 0
    else:
        self.doColorizeInputLines()
        return 0
