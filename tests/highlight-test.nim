# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import highlightpkg/colorize
import strutils

when isMainModule:
    echo "Foreground:"
    echo "  - " & "black".black & " #"
    echo "  - " & "red".red & " #"
    echo "  - " & "green".green & " #"
    echo "  - " & "yellow".yellow & " #"
    echo "  - " & "blue".blue & " #"
    echo "  - " & "magenta".magenta & " #"
    echo "  - " & "cyan".cyan & " #"
    echo "  - " & "white".white & " #"

    echo "Background:"
    echo "  - " & "black".onBlack & " #"
    echo "  - " & "red".onRed & " #"
    echo "  - " & "green".onGreen & " #"
    echo "  - " & "yellow".onYellow & " #"
    echo "  - " & "blue".onBlue & " #"
    echo "  - " & "magenta".onMagenta & " #"
    echo "  - " & "cyan".onCyan & " #"
    echo "  - " & "white".onWhite & " #"

    echo "Formatting:"
    echo "  - " & "reset".yellow.onBlue.reset & " #"
    echo "  - " & "bold".bold & " #"
    echo "  - " & "underlined".underlined & " #"
    echo "  - " & "reversed".reversed & " #"

    echo "Mixed:"
    echo "  - " & "yellow on red + bold + underlined".yellow.onRed.bold.underlined & " #"
    echo "  - " & "yellow on red + bold + underlined + reversed".yellow.onRed.bold.underlined.reversed & " #"

    echo "Foreground-Colors (extended):"
    for i in 0..16:
        for j in 0..16:
            let colorCode: int    = i * 16 + j
            let spaces:   string  = " ".repeat(4-($colorCode).len)
            let colorStr: string  = $(spaces & $colorCode).color(colorCode)
            stdout.write colorStr
        stdout.write "\n"

    echo "Background-Colors (extended):"
    for i in 0..16:
        for j in 0..16:
            let colorCode: int    = i * 16 + j
            let spaces:   string  = " ".repeat(4-($colorCode).len)
            let colorStr: string  = $(spaces & $colorCode).onColor(colorCode)
            stdout.write colorStr
        stdout.write "\n"
