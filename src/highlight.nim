# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import highlightpkg/colorize
import strutils
import re
import os
import parseopt
import tables
import algorithm
import heapqueue


when isMainModule:

    type HighlightConfigEntry = ref object of RootObj
        regexp:  Regex
        colorFg: string
        colorBg: string
        #colorFgProc: proc (colStr: ColorizedString): ColorizedString
        #colorBgProc: proc (colStr: ColorizedString): ColorizedString

    type HighlightCommand = ref object of RootObj
        inputFile: File
        isHelp:    bool
        configEntries: seq[HighlightConfigEntry]

    type Breakpoint = tuple
        pos:     int
        prio:    int
        isReset: bool
        colorFg: string
        colorBg: string



    proc newHighlightCommandFromCliArgs(args: seq[TaintedString]): HighlightCommand =
        result = HighlightCommand()
        result.inputFile = stdin
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
                    configEntry.regexp = re(configParts[0])
                    if configParts.len > 1 and configParts[1].strip != "":
                        configEntry.colorFg = configParts[1]
                        #configEntry.colorFgProc = fgColorStr2Proc[configParts[1]]
                    if configParts.len > 2 and configParts[2].strip != "":
                        configEntry.colorBg = configParts[2]
                        #configEntry.colorBgProc = bgColorStr2Proc[configParts[2]]
                    result.configEntries.add(configEntry)
                else:
                    assert(false)
            of cmdArgument:
                assert(false)
            of cmdEnd:
                assert(false)
        return result


    let highlightCommand = newHighlightCommandFromCliArgs(os.commandLineParams())


    if highlightCommand.isHelp:
        echo "Usage: " & getAppFilename() & " [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -h | --help         Print this help"
        echo "  -e= | --entry=      Adds a highlight-Entry of the form 'REGEX:FgColor:BgColor' (see section Colors)"
        echo ""
        echo "Colors:"
        echo "  black | white | red | green | blue | yellow | cyan | magenta"
        echo ""
        echo "Example:"
        echo "  $ cat aLogFile.log | highligter -e='^E.*:red' -e='^W.*:yellow -e'^I.*:white' -e='^D.*|^T.*:black' -e='SampleService:blue'"
        system.quit(0)


    for line in highlightCommand.inputFile.lines():

        var breakpoints: seq[Breakpoint] = @[]

        # Get all Breakpoints of all Highlight-Configs ...
        for idxCe in 0 ..< highlightCommand.configEntries.len:
            let configEntry = highlightCommand.configEntries[idxCe]
            var lineStart = 0
            while true:
                let bounds = line.findBounds(configEntry.regexp, start=lineStart)
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
            if a.prio < b.prio:
                return 1
            if a.prio > b.prio:
                return -1
            return 0
        )

        #echo "Vorher:"
        #for breakpoint in breakpoints:
        #    echo "  ", $breakpoint


        # Breakpoint-Liste Reset-Points aufräumen ...
        if breakpoints.len >= 1:
            var newBreakpoints:    seq[Breakpoint] = @[]
            var activeBreakpoints: seq[Breakpoint] = @[]
            for idxBrCurr in 0 ..< breakpoints.len:
                let brCurr = breakpoints[idxBrCurr]
                var brNew: Breakpoint

                if not brCurr.isReset:
                    ## Reguläre Breakpoints immer übernehmen ...
                    activeBreakpoints.add( brCurr )
                    brNew = brCurr

                elif brCurr.isReset and activeBreakpoints.len == 0:
                    ## Resetpunkt, aber kein aktiver Breakpoint vorhanden, reset übernehmen ...
                    brNew = brCurr

                elif brCurr.isReset and activeBreakpoints.len > 0:
                    ## Resetpunkte mit aktiven Colorpoints ...
                    let brLast = activeBreakpoints[activeBreakpoints.len-1]

                    # Wenn der aktuelle reset Breakpoint NICHT mit dem letzten aktiven übereinstimmt, diesen verwerfen ...
                    if brCurr.colorFg != brLast.colorFg or brCurr.colorBg != brLast.colorBg:
                        continue

                    # Der aktuelle reset Breakpoint stimmt dem letzten aktiven überein ...

                    # Letzten aktiven Breakpoint entfernen ...
                    activeBreakpoints.setLen(activeBreakpoints.len-1)

                    if activeBreakpoints.len == 0:
                        # Wenn kein aktiver Breakpoint vorhanden ist, den aktuellen Resetpoint übernehmen ...
                        brNew = brCurr
                    else:
                        brNew = activeBreakpoints[activeBreakpoints.len-1]
                        brNew.pos  = brCurr.pos
                        brNew.prio = brCurr.prio

                # Neuen Farbpunkt verwerfen, wenn der vorherige Farbpunkt die selbe Ausprägung hat ...
                if not brNew.isReset and newBreakpoints.len > 0:
                    let brPrev = newBreakpoints[newBreakpoints.len-1]
                    if not brPrev.isReset and brPrev.colorFg == brNew.colorFg and brPrev.colorBg == brNew.colorBg:
                        continue

                # Neuen Farbpunkt verwerfen, wenn der nachfolgende Punkt auf die gleiche Stelle zeigt ...
                if idxBrCurr < breakpoints.len-1:
                    let brNext = breakpoints[idxBrCurr+1]
                    if brNext.pos == brNew.pos:
                        continue

                # Neuen Punkt übernehmen ...
                newBreakpoints.add( brNew )

            breakpoints = newBreakpoints


        #echo "Nacher:"
        #for breakpoint in breakpoints:
        #    echo "  ", $breakpoint

        #echo "Test:"
        #block:
        #    var lineStart = 0
        #    for breakpoint in breakpoints:
        #        let linePart = line[lineStart..<breakpoint.pos]
        #        stdout.write linePart
        #        lineStart = breakpoint.pos
        #        stdout.write "|"
        #    let linePart = line[lineStart..<line.len]
        #    stdout.write linePart
        #    stdout.write "\n"

        const colorCodesMap = {
            # Reset
            ":":   "\x1B[0m",
            # Only Foreground ...
            "black:":   "\x1B[0;30m",
            "red:":     "\x1B[0;31m",
            "green:":   "\x1B[0;32m",
            "yellow:":  "\x1B[0;33m",
            "blue:":    "\x1B[0;34m",
            "magenta:": "\x1B[0;35m",
            "cyan:":    "\x1B[0;36m",
            "white:":   "\x1B[0;37m",
            # Only Background ...
            ":black":   "\x1B[0;40m",
            ":red":     "\x1B[0;41m",
            ":green":   "\x1B[0;42m",
            ":yellow":  "\x1B[0;43m",
            ":blue":    "\x1B[0;44m",
            ":magenta": "\x1B[0;45m",
            ":cyan":    "\x1B[0;46m",
            ":white":   "\x1B[0;47m",
        }.toTable()


        block:
            var lineStart = 0
            for breakpoint in breakpoints:
                let linePart = line[lineStart..<breakpoint.pos]
                stdout.write linePart
                lineStart = breakpoint.pos
                #stdout.write "|"
                var colorCode: string = colorCodesMap[":"]
                if not breakpoint.isReset:
                    colorCode = colorCodesMap[breakpoint.colorFg & ":" & breakpoint.colorBg]
                stdout.write(colorCode)
            let linePart = line[lineStart..<line.len]
            stdout.write linePart
            stdout.write "\n"
