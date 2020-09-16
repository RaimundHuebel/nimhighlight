## Provides an API to colorize the Output of an CLI-Tool.
##
## see: http://web.theurbanpenguin.com/adding-color-to-your-output-from-c/
## see: https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html
##
## author: Raimund Hübel


import strutils



type ColorizedString* = ref object of RootObj
    ## Implementation of an String containing additionally color-informations, which can be
    ## changed by using its color-name-Methods.
    str:          string
    fgColor:      int
    bgColor:      int
    cdBold:       int
    cdUnderlined: int
    cdReversed:   int



proc newColorizedString*(str: string): ColorizedString =
    ## Creates a new colorized String, not intended to be used by client.
    ## Clients should rather use methods like a_string.yellow.onBlue.
    return ColorizedString(str: str)



proc reset*(colStr: ColorizedString): ColorizedString =
    ## Resets the colors to console-default.
    colStr.fgColor      = 0
    colStr.bgColor      = 0
    colStr.cdBold       = 0
    colStr.cdUnderlined = 0
    colStr.cdReversed   = 0
    return colStr




proc default*(colStr: ColorizedString): ColorizedString =
    ## Applies default-foreground-color on the ColorizedString.
    colStr.fgColor = 0
    return colStr

proc color*(colStr: ColorizedString, color: int): ColorizedString =
    ## Applies the color-code between 0 and 255 as foreground-color to the ColorizedString.
    colStr.fgColor = 1000 + color
    return colStr

proc black*(colStr: ColorizedString): ColorizedString =
    ## Applies black-foreground on the ColorizedString.
    colStr.fgColor = 30
    return colStr

proc red*(colStr: ColorizedString): ColorizedString =
    ## Applies red-foreground on the ColorizedString.
    colStr.fgColor = 31
    return colStr

proc green*(colStr: ColorizedString): ColorizedString =
    ## Applies green-foreground on the ColorizedString.
    colStr.fgColor = 32
    return colStr

proc yellow*(colStr: ColorizedString): ColorizedString =
    ## Applies yellow-foreground on the ColorizedString.
    colStr.fgColor = 33
    return colStr

proc blue*(colStr: ColorizedString): ColorizedString =
    ## Applies blue-foreground on the ColorizedString.
    colStr.fgColor = 34
    return colStr

proc magenta*(colStr: ColorizedString): ColorizedString =
    ## Applies magenta-foreground on the ColorizedString.
    colStr.fgColor = 35
    return colStr

proc cyan*(colStr: ColorizedString): ColorizedString =
    ## Applies cyan-foreground on the ColorizedString.
    colStr.fgColor = 36
    return colStr

proc white*(colStr: ColorizedString): ColorizedString =
    ## Applies white-foreground on the ColorizedString.
    colStr.fgColor = 37
    return colStr





proc onDefault*(colStr: ColorizedString): ColorizedString =
    ## Applies default-background-color on the ColorizedString.
    colStr.bgColor = 0
    return colStr

proc onColor*(colStr: ColorizedString, color: int): ColorizedString =
    ## Applies the color-code between 0 and 255 as background-color to the ColorizedString.
    colStr.bgColor = 1000 + color
    return colStr

proc onBlack*(colStr: ColorizedString): ColorizedString =
    ## Applies black-background on the ColorizedString.
    colStr.bgColor = 40
    return colStr

proc onRed*(colStr: ColorizedString): ColorizedString =
    ## Applies red-background on the ColorizedString.
    colStr.bgColor = 41
    return colStr

proc onGreen*(colStr: ColorizedString): ColorizedString =
    ## Applies green-background on the ColorizedString.
    colStr.bgColor = 42
    return colStr

proc onYellow*(colStr: ColorizedString): ColorizedString =
    ## Applies yellow-background on the ColorizedString.
    colStr.bgColor = 43
    return colStr

proc onBlue*(colStr: ColorizedString): ColorizedString =
    ## Applies blue-background on the ColorizedString.
    colStr.bgColor = 44
    return colStr

proc onMagenta*(colStr: ColorizedString): ColorizedString =
    ## Applies magenta-background on the ColorizedString.
    colStr.bgColor = 45
    return colStr

proc onCyan*(colStr: ColorizedString): ColorizedString =
    ## Applies cyan-background on the ColorizedString.
    colStr.bgColor = 46
    return colStr

proc onWhite*(colStr: ColorizedString): ColorizedString =
    ## Applies white-background on the ColorizedString.
    colStr.bgColor = 47
    return colStr




proc bright*(colStr: ColorizedString): ColorizedString =
    ## Applies the ColorizedString to be brighter.
    colStr.cdBold = 1
    return colStr

proc underlined*(colStr: ColorizedString): ColorizedString =
    ## Applies underlining on the ColorizedString.
    colStr.cdUnderlined = 4
    return colStr

proc reversed*(colStr: ColorizedString): ColorizedString =
    ## Applies to reverse the background/foreground -color on the ColorizedString.
    colStr.cdReversed = 7
    return colStr

proc toPlainString*(colStr: ColorizedString): string =
    ## Returns the plain String without any colorized informations.
    return colStr.str

proc toString(colStr: ColorizedString): string =
    ## Converts the ColorizedString to a string with color-ascii-codes.
    var formatStrs: seq[string] = @[]
    if colStr.fgColor != 0:
        if colStr.fgColor < 1000:
            formatStrs.add $colStr.fgColor
        else:
            formatStrs.add "38;5;" & $(colStr.fgColor - 1000)
    if colStr.bgColor != 0:
        if colStr.bgColor < 1000:
            formatStrs.add $colStr.bgColor
        else:
            formatStrs.add "48;5;" & $(colStr.bgColor - 1000)
    if colStr.cdBold != 0:
        formatStrs.add $colStr.cdBold
    if colStr.cdUnderlined != 0:
        formatStrs.add $colStr.cdUnderlined
    if colStr.cdReversed != 0:
        formatStrs.add $colStr.cdReversed
    if formatStrs.len != 0:
        return  "\x1B[0;" & formatStrs.join(";") & "m" & colStr.str & "\x1B[0m"
    else:
        return colStr.str


proc `$`*(colStr: ColorizedString): string =
    ## Converts the ColorizedString to a string with color-ascii-codes.
    return colStr.toString()


proc `&`*(a: string, b: ColorizedString): string =
    ## Overloaded string-concat-operator to support implizit String-Concationation.
    return a & $b

proc `&`*(a: ColorizedString, b: string): string =
    ## Overloaded string-concat-operator to support implizit String-Concationation.
    return $a & b

proc `&`*(a: ColorizedString, b: ColorizedString): string =
    ## Overloaded string-concat-operator to support implizit String-Concationation.
    return $a & $b




proc default*(str: string): ColorizedString =
    ## Applies default-foreground-color, returning a ColorizedString.
    return newColorizedString(str).default

proc color*(str: string, color: int): ColorizedString =
    ## Applies the color-code between 0 and 255 as foreground-color, returning a ColorizedString.
    return newColorizedString(str).color(color)

proc black*(str: string): ColorizedString =
    ## Applies white-background on the string, returning a ColorizedString.
    return newColorizedString(str).black

proc red*(str: string): ColorizedString =
    ## Applies red-background on the string, returning a ColorizedString.
    return newColorizedString(str).red

proc green*(str: string): ColorizedString =
    ## Applies green-background on the string, returning a ColorizedString.
    return newColorizedString(str).green

proc yellow*(str: string): ColorizedString =
    ## Applies yellow-background on the string, returning a ColorizedString.
    return newColorizedString(str).yellow

proc blue*(str: string): ColorizedString =
    ## Applies blue-background on the string, returning a ColorizedString.
    return newColorizedString(str).blue

proc magenta*(str: string): ColorizedString =
    ## Applies magenta-background on the string, returning a ColorizedString.
    return newColorizedString(str).magenta

proc cyan*(str: string): ColorizedString =
    ## Applies cyan-background on the string, returning a ColorizedString.
    return newColorizedString(str).cyan

proc white*(str: string): ColorizedString =
    ## Applies white-background on the string, returning a ColorizedString.
    return newColorizedString(str).white





proc onDefault*(str: string): ColorizedString =
    ## Applies default-background-color, returning a ColorizedString.
    return newColorizedString(str).onDefault()

proc onColor*(str: string, color: int): ColorizedString =
    ## Applies the color-code between 0 and 255 as background-color, returning a ColorizedString.
    return newColorizedString(str).onColor(color)

proc onBlack*(str: string): ColorizedString =
    ## Applies black-background on the ColorizedString.
    return newColorizedString(str).onBlack

proc onRed*(str: string): ColorizedString =
    ## Applies red-background on the ColorizedString.
    return newColorizedString(str).onRed

proc onGreen*(str: string): ColorizedString =
    ## Applies green-background on the ColorizedString.
    return newColorizedString(str).onGreen

proc onYellow*(str: string): ColorizedString =
    ## Applies yellow-background on the ColorizedString.
    return newColorizedString(str).onYellow

proc onBlue*(str: string): ColorizedString =
    ## Applies blue-background on the ColorizedString.
    return newColorizedString(str).onBlue

proc onMagenta*(str: string): ColorizedString =
    ## Applies magenta-background on the ColorizedString.
    return newColorizedString(str).onMagenta

proc onCyan*(str: string): ColorizedString =
    ## Applies cyan-background on the ColorizedString.
    return newColorizedString(str).onCyan

proc onWhite*(str: string): ColorizedString =
    ## Applies white-background on the ColorizedString.
    return newColorizedString(str).onWhite



proc toPlainString*(str: string): string =
    ## Returns the plain String without any colorized informations.
    return str

proc reset*(str: string): ColorizedString =
    return newColorizedString(str).reset

proc bright*(str: string): ColorizedString =
    ## Applies to the string to be brighter, returning a ColorizedString.
    return newColorizedString(str).bright

proc underlined*(str: string): ColorizedString =
    ## Applies to the string to be underlined, returning a ColorizedString.
    return newColorizedString(str).underlined

proc reversed*(str: string): ColorizedString =
    ## Applies to the string to be switch foreground/background -color, returning a ColorizedString.
    return newColorizedString(str).reversed
