
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'flamegraph' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandElements = $commandAst.CommandElements
    $command = @(
        'flamegraph'
        for ($i = 1; $i -lt $commandElements.Count; $i++) {
            $element = $commandElements[$i]
            if ($element -isnot [StringConstantExpressionAst] -or
                $element.StringConstantType -ne [StringConstantType]::BareWord -or
                $element.Value.StartsWith('-')) {
                break
        }
        $element.Value
    }) -join ';'

    $completions = @(switch ($command) {
        'flamegraph' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Profile a running process by pid')
            [CompletionResult]::new('--pid', 'pid', [CompletionResultType]::ParameterName, 'Profile a running process by pid')
            [CompletionResult]::new('--completions', 'completions', [CompletionResultType]::ParameterName, 'Generate shell completions for the given shell')
            [CompletionResult]::new('-o', 'o', [CompletionResultType]::ParameterName, 'Output file, flamegraph.svg if not present')
            [CompletionResult]::new('--output', 'output', [CompletionResultType]::ParameterName, 'Output file, flamegraph.svg if not present')
            [CompletionResult]::new('-F', 'F', [CompletionResultType]::ParameterName, 'Sampling frequency')
            [CompletionResult]::new('--freq', 'freq', [CompletionResultType]::ParameterName, 'Sampling frequency')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Custom command for invoking perf/dtrace')
            [CompletionResult]::new('--cmd', 'cmd', [CompletionResultType]::ParameterName, 'Custom command for invoking perf/dtrace')
            [CompletionResult]::new('--notes', 'notes', [CompletionResultType]::ParameterName, 'Set embedded notes in SVG')
            [CompletionResult]::new('--min-width', 'min-width', [CompletionResultType]::ParameterName, 'Omit functions smaller than <FLOAT> pixels')
            [CompletionResult]::new('--image-width', 'image-width', [CompletionResultType]::ParameterName, 'Image width in pixels')
            [CompletionResult]::new('--palette', 'palette', [CompletionResultType]::ParameterName, 'Color palette')
            [CompletionResult]::new('--perfdata', 'perfdata', [CompletionResultType]::ParameterName, 'perfdata')
            [CompletionResult]::new('-v', 'v', [CompletionResultType]::ParameterName, 'Print extra output to help debug problems')
            [CompletionResult]::new('--verbose', 'verbose', [CompletionResultType]::ParameterName, 'Print extra output to help debug problems')
            [CompletionResult]::new('--open', 'open', [CompletionResultType]::ParameterName, 'Open the output .svg file with default program')
            [CompletionResult]::new('--root', 'root', [CompletionResultType]::ParameterName, 'Run with root privileges (using `sudo`)')
            [CompletionResult]::new('--deterministic', 'deterministic', [CompletionResultType]::ParameterName, 'Colors are selected such that the color of a function does not change between runs')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'Plot the flame graph up-side-down')
            [CompletionResult]::new('--inverted', 'inverted', [CompletionResultType]::ParameterName, 'Plot the flame graph up-side-down')
            [CompletionResult]::new('--reverse', 'reverse', [CompletionResultType]::ParameterName, 'Generate stack-reversed flame graph')
            [CompletionResult]::new('--flamechart', 'flamechart', [CompletionResultType]::ParameterName, 'Produce a flame chart (sort by time, do not merge stacks)')
            [CompletionResult]::new('--no-inline', 'no-inline', [CompletionResultType]::ParameterName, 'Disable inlining for perf script because of performance issues')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Prints help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Prints help information')
            [CompletionResult]::new('-V', 'V', [CompletionResultType]::ParameterName, 'Prints version information')
            [CompletionResult]::new('--version', 'version', [CompletionResultType]::ParameterName, 'Prints version information')
            break
        }
    })

    $completions.Where{ $_.CompletionText -like "$wordToComplete*" } |
        Sort-Object -Property ListItemText
}
