## Cli-Tool to colorize the input given by stdin.
##
## author: Raimund Hübel


import highlightpkg/highlight_command


proc main() =
    ## Entrypoint of the highlighter cli application.
    let highlightCommand = (
        newHighlightCommand()
        .initWithDefaultConfigFiles()
        .initWithCliArgs()
    )
    let execResult = highlightCommand.doExecute()
    system.quit(execResult)
main()
