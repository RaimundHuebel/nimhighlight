# This is just an example to get you started. Users of your hybrid library will
# import this file by writing ``import nimhighlightpkg/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.


# see: http://web.theurbanpenguin.com/adding-color-to-your-output-from-c/
# see: https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html

import strutils



when defined(Posix):


    type ColorizedString* = ref object of RootObj
        str:          string
        fgColor:      int
        bgColor:      int
        cdBold:       int
        cdUnderlined: int
        cdReversed:   int



    proc newColorizedString*(str: string): ColorizedString =
        return ColorizedString(str: str)



    proc reset*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor      = 0
        colStr.bgColor      = 0
        colStr.cdBold       = 0
        colStr.cdUnderlined = 0
        colStr.cdReversed   = 0
        return colStr




    proc color*(colStr: ColorizedString, color: int): ColorizedString =
        colStr.fgColor = 1000 + color
        return colStr

    proc black*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor = 30
        return colStr

    proc red*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor = 31
        return colStr

    proc green*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor = 32
        return colStr

    proc yellow*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor = 33
        return colStr

    proc blue*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor = 34
        return colStr

    proc magenta*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor = 35
        return colStr

    proc cyan*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor = 36
        return colStr

    proc white*(colStr: ColorizedString): ColorizedString =
        colStr.fgColor = 37
        return colStr




    #proc onDefault*(colStr: ColorizedString): ColorizedString =
    #    colStr.bgColor = 0
    #    return colStr

    proc onColor*(colStr: ColorizedString, color: int): ColorizedString =
        colStr.bgColor = 1000 + color
        return colStr

    proc onBlack*(colStr: ColorizedString): ColorizedString =
        colStr.bgColor = 40
        return colStr

    proc onRed*(colStr: ColorizedString): ColorizedString =
        colStr.bgColor = 41
        return colStr

    proc onGreen*(colStr: ColorizedString): ColorizedString =
        colStr.bgColor = 42
        return colStr

    proc onYellow*(colStr: ColorizedString): ColorizedString =
        colStr.bgColor = 43
        return colStr

    proc onBlue*(colStr: ColorizedString): ColorizedString =
        colStr.bgColor = 44
        return colStr

    proc onMagenta*(colStr: ColorizedString): ColorizedString =
        colStr.bgColor = 45
        return colStr

    proc onCyan*(colStr: ColorizedString): ColorizedString =
        colStr.bgColor = 46
        return colStr

    proc onWhite*(colStr: ColorizedString): ColorizedString =
        colStr.bgColor = 47
        return colStr




    proc bold*(colStr: ColorizedString): ColorizedString =
        colStr.cdBold = 1
        return colStr

    proc underlined*(colStr: ColorizedString): ColorizedString =
        colStr.cdUnderlined = 4
        return colStr

    proc reversed*(colStr: ColorizedString): ColorizedString =
        colStr.cdReversed = 7
        return colStr




    proc `$`*(colStr: ColorizedString): string =
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


    proc `&`*(a: string, b: ColorizedString): string =
        return a & $b

    proc `&`*(a: ColorizedString, b: string): string =
        return $a & b

    proc `&`*(a: ColorizedString, b: ColorizedString): string =
        return $a & $b





proc color*(str: string, color: int): ColorizedString =
    return newColorizedString(str).color(color)

proc black*(str: string): ColorizedString =
    return newColorizedString(str).black

proc red*(str: string): ColorizedString =
    return newColorizedString(str).red

proc green*(str: string): ColorizedString =
    return newColorizedString(str).green

proc yellow*(str: string): ColorizedString =
    return newColorizedString(str).yellow

proc blue*(str: string): ColorizedString =
    return newColorizedString(str).blue

proc magenta*(str: string): ColorizedString =
    return newColorizedString(str).magenta

proc cyan*(str: string): ColorizedString =
    return newColorizedString(str).cyan

proc white*(str: string): ColorizedString =
    return newColorizedString(str).white




#proc onDefault*(str: string): ColorizedString =
#    return newColorizedString(str).onDefault

proc onColor*(str: string, color: int): ColorizedString =
    return newColorizedString(str).onColor(color)

proc onBlack*(str: string): ColorizedString =
    return newColorizedString(str).onBlack

proc onRed*(str: string): ColorizedString =
    return newColorizedString(str).onRed

proc onGreen*(str: string): ColorizedString =
    return newColorizedString(str).onGreen

proc onYellow*(str: string): ColorizedString =
    return newColorizedString(str).onYellow

proc onBlue*(str: string): ColorizedString =
    return newColorizedString(str).onBlue

proc onMagenta*(str: string): ColorizedString =
    return newColorizedString(str).onMagenta

proc onCyan*(str: string): ColorizedString =
    return newColorizedString(str).onCyan

proc onWhite*(str: string): ColorizedString =
    return newColorizedString(str).onWhite




proc reset*(str: string): ColorizedString =
    return newColorizedString(str).reset

proc bold*(str: string): ColorizedString =
    return newColorizedString(str).bold

proc underlined*(str: string): ColorizedString =
    return newColorizedString(str).underlined

proc reversed*(str: string): ColorizedString =
    return newColorizedString(str).reversed
