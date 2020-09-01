# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import highlightpkg/colorize
import strutils
import re
import os
import parseopt
import tables
import algorithm


when isMainModule:

    type HighlightConfigEntry = ref object of RootObj
        regexp:      Regex
        colorFgProc: proc (colStr: ColorizedString): ColorizedString
        colorBgProc: proc (colStr: ColorizedString): ColorizedString

    type HighlightCommand = ref object of RootObj
        inputFile: File
        configEntries: seq[HighlightConfigEntry]


    const fgColorStr2Proc = {
        "black":   proc (colStr: ColorizedString): ColorizedString = colStr.black(),
        "red":     proc (colStr: ColorizedString): ColorizedString = colStr.red(),
        "green":   proc (colStr: ColorizedString): ColorizedString = colStr.green(),
        "yellow":  proc (colStr: ColorizedString): ColorizedString = colStr.yellow(),
        "blue":    proc (colStr: ColorizedString): ColorizedString = colStr.blue(),
        "magenta": proc (colStr: ColorizedString): ColorizedString = colStr.magenta(),
        "cyan":    proc (colStr: ColorizedString): ColorizedString = colStr.cyan(),
        "white":   proc (colStr: ColorizedString): ColorizedString = colStr.white()
    }.toTable()

    const bgColorStr2Proc = {
        "black":   proc (colStr: ColorizedString): ColorizedString = colStr.onBlack(),
        "red":     proc (colStr: ColorizedString): ColorizedString = colStr.onRed(),
        "green":   proc (colStr: ColorizedString): ColorizedString = colStr.onGreen(),
        "yellow":  proc (colStr: ColorizedString): ColorizedString = colStr.onYellow(),
        "blue":    proc (colStr: ColorizedString): ColorizedString = colStr.onBlue(),
        "magenta": proc (colStr: ColorizedString): ColorizedString = colStr.onMagenta(),
        "cyan":    proc (colStr: ColorizedString): ColorizedString = colStr.onCyan(),
        "white":   proc (colStr: ColorizedString): ColorizedString = colStr.onWhite()
    }.toTable()


    proc newHighlightCommandFromCliArgs(args: seq[TaintedString]): HighlightCommand =
        result = HighlightCommand()
        result.inputFile = stdin
        var optParser = initOptParser(args)
        for optKind, optKey, optVal in optParser.getopt():
            case optKind:
            of cmdShortOption, cmdLongOption:
                if (optKey == "e" or optKey == "entry"):
                    let configParts = optVal.split(':', 3)
                    let configEntry = HighlightConfigEntry()
                    if configParts.len < 2:
                        assert(false)
                    configEntry.regexp = re(configParts[0])
                    if configParts.len > 1 and configParts[1].strip != "":
                        configEntry.colorFgProc = fgColorStr2Proc[configParts[1]]
                    if configParts.len > 2 and configParts[2].strip != "":
                        configEntry.colorBgProc = bgColorStr2Proc[configParts[2]]
                    result.configEntries.add(configEntry)
            of cmdArgument:
                assert(false)
            of cmdEnd:
                assert(false)
        return result


    let highlightCommand = newHighlightCommandFromCliArgs(os.commandLineParams())
    #echo $highlightCommand.inputFile.getFileHandle()
    #for configEntry in highlightCommand.configEntries:
    #    echo configEntry.regexp, ": fg=", configEntry.colorFg, ", bg=", configEntry.colorBg


    for line in highlightCommand.inputFile.lines():
        type LineConfig = tuple[
            first:  int,
            last:   int,
            fgProc: proc (colStr: ColorizedString): ColorizedString,
            bgProc: proc (colStr: ColorizedString): ColorizedString
        ]

        var gLineConfigs: seq[LineConfig] = @[]

        var lineStart = 0
        var newLine = ""
        var restLine = line
        while true:

            var lineConfigs: seq[LineConfig] = @[]

            # Get line Configs for Rest of Line ...
            for configEntry in highlightCommand.configEntries:
                let bounds = line.findBounds(configEntry.regexp, start=lineStart)
                if bounds.first == -1:
                    continue
                let lineConfig = (
                    first:  bounds.first,
                    last:   bounds.last,
                    fgProc: configEntry.colorFgProc,
                    bgProc: configEntry.colorBgProc
                )
                lineConfigs.add(lineConfig)

            #echo lineConfigs.len

            # Wenn es nichts anzuwenden gibt, dann den rest vollständig übernehmen ...
            if lineConfigs.len < 1:
                break

            # Wenn es genau ein Treffer gibt, dann dann diesen normal übernehmen ...
            if lineConfigs.len == 1:
                gLineConfigs.add(lineConfigs[0])
                break

            # Sortiere Line-Configs nach ersten treffer ...
            lineConfigs.sort(proc (a, b: LineConfig): int =
                if a.first < b.first:
                    return -1
                if a.first > b.first:
                    return 1
                return 0
            )

            # Wenn es mehrere Treffer gibt, dann den ersten und zweiten Treffer mergen, falls notwendig ...
            if lineConfigs[0].last < lineConfigs[1].first:
                gLineConfigs.add(lineConfigs[0])
            else: # if lineConfigs[0].last >= lineConfigs[1].first
                gLineConfigs.add((
                    first:  lineConfigs[0].first,
                    last:   lineConfigs[1].first - 1,
                    fgProc: lineConfigs[0].fgProc,
                    bgProc: lineConfigs[0].bgProc
                ))
                if lineConfigs[0].last < lineConfigs[1].last:
                    gLineConfigs.add((
                        first:  lineConfigs[1].first,
                        last:   lineConfigs[0].last,
                        fgProc: lineConfigs[1].fgProc,
                        bgProc: lineConfigs[1].bgProc
                    ))
                if lineConfigs[0].last < lineConfigs[1].last:
                    gLineConfigs.add((
                        first:  lineConfigs[0].last + 1,
                        last:   lineConfigs[1].last,
                        fgProc: lineConfigs[0].fgProc,
                        bgProc: lineConfigs[0].bgProc
                    ))

            let lastLineConfig = gLineConfigs[gLineConfigs.len - 1]
            lineStart = lastLineConfig.last + 1

#            # Formatiere nach ersten Treffer ...
#            let lineConfig = lineConfigs[0]
#
#            # Formatiere nach ersten Treffer ...
#            var before  = restLine[0..<lineConfig.first]
#            var colWord = newColorizedString(restLine[lineConfig.first..lineConfig.last])
#            if lineConfig.fgProc != nil:
#                colWord = lineConfig.fgProc(colWord)
#            if lineConfig.bgProc != nil:
#                colWord = lineConfig.bgProc(colWord)
#            restLine = restLine[lineConfig.last+1..<restLine.len]
#            newLine = newLine & before
#            newLine = newLine & $colWord

            #let bounds = restLine.findBounds(highlightCommand.configEntries[0].regexp)
            #let fgColProc = highlightCommand.configEntries[0].colorFgProc
            #let bgColProc = highlightCommand.configEntries[0].colorBgProc
            #if bounds.first != -1:
            #    var before  = restLine[0..<bounds.first]
            #    var colWord = newColorizedString(restLine[bounds.first..bounds.last])
            #    if fgColProc != nil:
            #        colWord = fgColProc(colWord)
            #    if bgColProc != nil:
            #        colWord = bgColProc(colWord)
            #    restLine   = restLine[bounds.last+1..<restLine.len]
            #    newLine = newLine & before
            #    newLine = newLine & $colWord
            #else:
            #    newLine = newLine & restLine
            #    break
        #echo $gLineConfigs

        if gLineConfigs.len == 0:
            stdout.write line
        else:
            var lineStart = 0
            for idx in 0 .. gLineConfigs.len-1:
                let lineConfig = gLineConfigs[idx]
                if lineStart < lineConfig.first:
                    stdout.write line[lineStart .. lineConfig.first-1]
                var colWord = newColorizedString(line[lineConfig.first .. lineConfig.last])
                if lineConfig.fgProc != nil:
                    colWord = lineConfig.fgProc(colWord)
                if lineConfig.bgProc != nil:
                    colWord = lineConfig.bgProc(colWord)
                lineStart = lineConfig.last + 1
                stdout.write $colWord
            if lineStart < line.len:
                stdout.write line[lineStart .. line.len-1]
        stdout.write("\n")
