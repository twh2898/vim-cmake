
let g:cmake_generate_options = ['-Bbuild', '-GNinja', '-DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE']

let s:cmake_run_args = ''

let s:show_match_error = 1
let s:show_debug = 0

let s:cache_path = expand('~/.cache/vim')
let s:cache_cmake = 'cmake'
let s:key_last_executable = 'last_executable'
let s:key_run_args = 'run_args'
let s:cmake_list_file = 'CMakeLists.txt'

function! s:SetCache(key, value)
    " Get a value from a cache file.
    "
    " Parameters:
    "   key string the key to write to
    "   value the value to write

    let l:dir_path = join([s:cache_path, s:cache_cmake, getcwd()], '/')
    let l:file_path = util#PathJoin(l:dir_path, a:key)

    " Make sure the cache directory exists
    silent exec '!mkdir -p "'.l:dir_path.'"'

    " Write value to file
    call writefile([a:value], l:file_path)
endfunction

function! s:GetCache(key, default)
    " Get a value from a cache file. Usually called with getcwd() as
    " `workingddir`.
    "
    " Parameters:
    "   key string the key to read from
    "   default the value to return if the cache does not exist
    "
    " Return: the value

    let l:file_path = join([s:cache_path, s:cache_cmake, getcwd(), a:key], '/')

    " Check that the value exists
    if filereadable(l:file_path)

        " Read the first line
        let l:lines = readfile(l:file_path, '', 1)

        " If something was read
        if len(l:lines) > 0 && len(l:lines[0]) > 0

            return l:lines[0]
        endif
    else

        " Return default value
        return a:default
    endif
endfunction

let s:cmake_last_executable = str2nr(s:GetCache(s:key_last_executable, '0'))
let s:cmake_run_args = s:GetCache(s:key_run_args, '')

function! s:ReadFile(path)
    " Read a CMakeLists.txt file and remove any blank lines or comments. Also,
    " strip leading and trailing whitespace for each line
    "
    " Parameter: path string the file to read
    "
    " Return: a list of clean lines

    let l:lines = []
    for l:line in readfile(a:path)
        " Trim leading and trailing whitespace
        let l:line = trim(l:line)

        " Remove comments at the end of the line
        if l:line =~ '#'
            let l:line = trim(matchstr(l:line, '\v[^#]*'))
        endif

        " Skip empty lines
        if empty(l:line)
            continue
        endif

        let l:lines = add(l:lines, l:line)
    endfor

    return l:lines
endfunction

function! s:ArgsFromLine(line)
    " Given a line with the start, middle or end of a call, return any
    " arguments to that call
    "
    " Parameter: line string the line to parse
    "
    " Return: a list of arguments


    let l:line = a:line

    " FIXME: Handle nested parenthesis
    " If line containes call start, remove it
    if l:line =~ '('
        let l:cmd = matchstr(l:line, '\v\s*(\w+)\s*\(')
        let l:line = l:line[len(l:cmd):]
    endif

    " FIXME: Handle nested parenthesis
    " If line contains call end, remove it
    if l:line =~ ')'
        let l:line = matchstr(l:line, '\v[^\)]*')
    endif

    " Split the line into arguments
    return split(l:line)
endfunction

function! s:ParseCalls(lines)
    " Given the clean lines from a CMakeLists.txt file, parse all calls and
    " their arguments. The return is a list of pairs in the form of
    " `[{command}, [{args}]]`
    "
    " Parameter: lines [string] a list of clean lines
    "
    " Return: a list of pairs with the call and a list of its arguments

    let l:i = 0
    let l:cmds = []

    while l:i < len(a:lines)
        let l:line = a:lines[l:i]

        " Get call name
        let l:match = matchstr(l:line, '\v\s*(\w+)\s*\(')
        let l:call = l:match[:-2]

        " Check for errors
        if empty(l:match)
            if s:show_match_error
                echoerr 'Match failed to find start of call in line "'.l:line.'"'
            endif
            break
        endif

        " Get call arguments for the current line
        let l:args = s:ArgsFromLine(l:line)

        " FIXME: Handle nested parenthesis
        " Parse arguments from lines until the end of the call
        while l:line !~ ')\s*$'
            let l:i += 1

            " Check if end of lines
            if l:i >= len(a:lines)
                break
            endif

            let l:line = a:lines[l:i]
            let l:args += s:ArgsFromLine(l:line)
        endwhile

        " Store command and arguments
        let l:cmds = add(l:cmds, [l:call, l:args])

        let l:i += 1
    endwhile

    return l:cmds
endfunction

function! s:ResolveVars(vars, value)
    " Given a string and list of current variables, resolve any ${NAME}
    " formatted variables. If a variable does not exist in the `vars`
    " dictionary, it will be replaced with `@!@NAME!@!`.
    "
    " Parameter: vars {string -> string} a dictionary of variables with the
    " key as that variable name
    "
    " Return: the string with all variables resolved

    let l:value = a:value
    let l:end = 0
    let l:pattern = '\v\$\{\w+\}'

    " Try to match a variable
    let [l:match, l:begin, l:end] = matchstrpos(a:value, l:pattern, l:end)

    " While there are more variables to resolve
    while l:end > 0
        let l:var = l:match[2:-2]

        " If the variable exists
        if has_key(a:vars, l:var)
            let l:val = a:vars[l:var]
            let l:value = substitute(l:value, l:match, l:val, 'g')

            " Insert a mark to show a failed lookup
        else
            let l:val = '@!@' . l:var . '!@!'
            let l:value = substitute(l:value, l:match, l:val, 'g')
        endif

        " Try to match another variable
        let [l:match, l:begin, l:end] = matchstrpos(a:value, l:pattern, l:end)
    endwhile

    return l:value
endfunction

function! s:FindExeTargets(path, vars)
    " Find all executable targets for the CMakeLists.txt file `path`. If there
    " is an `add_subdirectory` call, this function will be called recursively.
    "
    " Parameters:
    "   path string the path to a CMakeLists.txt
    "   vars {string->string} the currently defined variables
    "
    " Return: a list of resolved target names

    " Ensure `path` exists and is a file.
    if !filereadable(a:path)
        echoerr 'File "'.a:path.'" does not exist'
    endif

    " Get directory that contains CMakeLists.txt
    let l:dir = substitute(a:path, 'CMakeLists.txt$', '', '')

    let l:lines = s:ReadFile(a:path)
    let l:cmds = s:ParseCalls(l:lines)

    " Recursive variables. All upper scope variables will be available, but
    " variables defined in this scope will not be available above
    let l:vars = copy(a:vars)

    let l:targets = []
    for [l:command, l:args] in l:cmds
        if s:show_debug
            echo "Found command (" a:path ") " l:command " " l:args
        endif

        " Resolve any variables
        let l:args = map(l:args, {_,v -> s:ResolveVars(l:vars, v)})
        let l:args = filter(l:args, {_,v->!empty(v)})

        " Check for commands which define variables or targets
        if l:command == 'project'
            let l:vars['PROJECT_NAME'] = l:args[0]

        elseif l:command == 'set'
            " Multiple arguments, join with a space
            if len(l:args) > 2
                let l:vars[l:args[0]] = join(l:args[1:], ' ')

                " One argument, set as string value
            elseif len(l:args) == 2
                let l:vars[l:args[0]] = l:args[1]

                " No arguments, clear the value
            elseif len(l:args) == 1
                let l:vars[l:args[0]] = ''
            endif

        elseif l:command == 'add_executable'
            let l:targets = add(l:targets, l:args[0])

        elseif l:command == 'add_subdirectory'
            let l:sub_path = util#PathJoin(l:dir, l:args[0], s:cmake_list_file)
            let l:targets += s:FindExeTargets(l:sub_path, l:vars)
        endif
    endfor

    return l:targets
endfunction

function! cmake#FindExecutableTargets(...)
    " Top level function to search for executable targets starting with the
    " CMakeLists.txt in the current working directory. If a path is provided,
    " it will be used in place of the current working directory.
    "
    " Parameter: path string? = '.' an optional path
    "
    " Return: a list of executable targets

    " Use current working directory if no path is provided
    if a:0 == 1
        let l:path = a:1
    else
        let l:path = getcwd()
    endif

    let l:path = util#PathJoin(l:path, s:cmake_list_file)
    let l:targets = s:FindExeTargets(l:path, {})
    if s:show_debug
        for target in l:targets
            echo "Found target " target
        endfor
    endif

    return l:targets
endfunction

function! cmake#Generate(...)
    " Wrapper for the cmake command to generate the build directory.
    "
    " Parameters: ... string arguments to pass to the cmake command
    "
    " Return: return status of the cmake command

    " Combine function arguments with default options
    let l:options = join(g:cmake_generate_options + a:000, ' ')

    exec '!cmake -S . -B build ' . l:options

    return v:shell_error
endfunction

function! cmake#Build(...)
    " Wrapper for the cmake --build command. This function writes all files to
    " disk
    "
    " Parameter: target string? an optional target
    "
    " Return: return status of the cmake command

    :wa

    " Check for optional target
    let l:options = ''
    if a:0 > 0 && !empty(a:1)
        let l:options = '--target ' . a:1
    endif

    exec '!cmake --build build ' . l:options

    return v:shell_error
endfunction

function! cmake#SelectExecutable()
    " Select the executable target to run when cmake#Run is invoked.

    let l:targets = cmake#FindExecutableTargets()

    " Print a list of targets to select from
    let l:i = 0
    for target in l:targets
        echo l:i . ") " . target
        let l:i = l:i + 1
    endfor

    " Prompt the user to select a target
    let l:select = input("Select an executable(" . s:cmake_last_executable . "): ")

    " If no input, do nothing
    if empty(l:select)
        return
    endif

    " Bounds checking
    let l:select = str2nr(l:select)
    if l:select < 0 || l:select >= len(l:targets)
        echoerr 'Invalid selection ' . l:select
    endif

    " Store the selection
    let s:cmake_last_executable = l:select
    call s:SetCache(s:key_last_executable, l:select)

    " Clear arguments from previously selected executable
    call cmake#SetRunArguments('')
endfunction

function! cmake#SetRunArguments(args)
    " Set the arguments to pass to the executable when cmake#Run is called. An
    " empty string clears the arguments.
    "
    " Parameter: args string a space delimited string of arguments

    let s:cmake_run_args = a:args
    call s:SetCache(s:key_run_args, s:cmake_run_args)
endfunction

function! cmake#Run(...)
    " Invoke the currently selected executable in the build directory. This
    " function passes the current run arguments to the executable.
    "
    " Parameter: ... string argument to pass to the executable
    "
    " Return: return status of the executable

    " Store a new set of arguments
    if a:0 > 0
        call cmake#SetRunArguments(join(a:000, ' '))
    endif

    " Get the selected target name
    let l:targets = cmake#FindExecutableTargets()
    if s:cmake_last_executable >= len(l:targets)
        echoerr "Target is out of range. Run cmake#SelectExecutable"
    endif
    let l:target = l:targets[s:cmake_last_executable]

    let l:cmds = ['cd build',
                \'[ -d ' . l:target . ' ] && cd ' . l:target,
                \'./' . l:target . ' ' . s:cmake_run_args
                \]

    exec '!' . join(l:cmds, '; ')

    return v:shell_error
endfunction

function! cmake#Test(...)
    " Wrapper for the `cmake --build build --target test` command.
    "
    " Parameter: options to pass to the cmake command
    "
    " Return: return status of the cmake command

    " Check for options
    let l:options = join(a:000, ' ')

    exec '!cmake --build build --target test ' . l:options
endfunction

function! cmake#BuildRun(target, ...)
    " Call cmake#Build and on success call cmake#Run.
    "
    " Parameters:
    "   target string the build target or an empty string
    "   ... string argument to pass to the executable
    "
    " Return: return status of the build on failure or the executable

    let l:build_error = cmake#Build(a:target)

    if l:build_error != 0
        echo 'build_error ' l:build_error
        return l:build_error
    endif

    let l:run_error = call('cmake#Run', a:000)

    return l:run_error
endfunction
