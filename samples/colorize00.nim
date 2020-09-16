## Sample to demonstrate the use of highlightpkg/colorize
##
## compile & run: $ nim compile --run samples/colorize00.nim
##
## author: Raimund Hübel


import highlightpkg/colorize
import strutils


proc main() =
    echo "Foreground:"
    echo "  - " & "default".default & " #"
    echo "  - " & ".black".black & " #"
    echo "  - " & ".red".red & " #"
    echo "  - " & ".green".green & " #"
    echo "  - " & ".yellow".yellow & " #"
    echo "  - " & ".blue".blue & " #"
    echo "  - " & ".magenta".magenta & " #"
    echo "  - " & ".cyan".cyan & " #"
    echo "  - " & ".white".white & " #"

    echo "Background:"
    echo "  - " & ".onDefault".onDefault & " #"
    echo "  - " & ".onBlack".onBlack & " #"
    echo "  - " & ".onRed".onRed & " #"
    echo "  - " & ".onGreen".onGreen & " #"
    echo "  - " & ".onYellow".onYellow & " #"
    echo "  - " & ".onBlue".onBlue & " #"
    echo "  - " & ".onMagenta".onMagenta & " #"
    echo "  - " & ".onCyan".onCyan & " #"
    echo "  - " & ".onWhite".onWhite & " #"

    echo "Formatting:"
    echo "  - " & ".reset".yellow.onBlue.reset & " #"
    echo "  - " & ".bright".bright & " #"
    echo "  - " & ".underlined".underlined & " #"
    echo "  - " & ".reversed".reversed & " #"
    echo "  - " & ".bright.underlined.reversed".bright.underlined.reversed & " #"

    echo "Mixed:"
    echo "  - " & ".yellow on red + bright + underlined".yellow.onRed.bright.underlined & " #"
    echo "  - " & ".yellow on red + bright + underlined + reversed".yellow.onRed.bright.underlined.reversed & " #"

    echo "Restoring defaults / resetting:"
    echo "  - " & ".yellow.default".yellow.default & " #"
    echo "  - " & ".onYellow.onDefault".onYellow.onDefault & " #"
    echo "  - " & ".yellow.onBlue.default".yellow.onBlue.default & " #"
    echo "  - " & ".yellow.onBlue.onDefault".yellow.onBlue.onDefault & " #"
    echo "  - " & ".yellow.onBlue.default.onDefault".yellow.onBlue.default.onDefault & " #"
    echo "  - " & ".yellow.onBlue.bright.underlined.reset".yellow.onBlue.bright.underlined.reset & " #"

    echo "Foreground-Colors (extended, .color(0..255)):"
    for i in 0..<16:
        for j in 0..<16:
            let colorCode: int    = i * 16 + j
            let spaces:   string  = " ".repeat(4-($colorCode).len)
            let colorStr: string  = $(spaces & $colorCode).color(colorCode)
            stdout.write colorStr
        stdout.write "\n"

    echo "Background-Colors (extended, .onColor(0..255)):"
    for i in 0..<16:
        for j in 0..<16:
            let colorCode: int    = i * 16 + j
            let spaces:   string  = " ".repeat(4-($colorCode).len)
            let colorStr: string  = $(spaces & $colorCode).onColor(colorCode)
            stdout.write colorStr
        stdout.write "\n"

main()
