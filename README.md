# vim-cmake

CMake project support for Vim and Neovim.

## Install

For [vim-plug](https://github.com/junegunn/vim-plug) add the following to your
`.vimrc` or `.config/nvim/init.vim`

```vim
Plug 'twh2898/vim-cmake'
```

and then restart Vim / Neovim and run `:PlugInstall`.

## Features

- Generate build directory
- Build and Run
- Select which executable to run
- Set arguments to pass to the executable
- Cached selection and arguments between sessions

## Usage

### Commands

Command                                  | Mapping                                      
-----------------------------------------|----------------------------------------------
`:CMakeGenerate [{Options} ...]`         | `call CMakeGenerate([{Options} ...])`        
`:CMakeBuild [{Target}]`                 | `call CMakeBuild([{Target}])`                
`:CMakeSelectExecutable`                 | `call CMakeSelectExecutable()`               
`:CMakeRun [{Args} ...]`                 | `call CMakeRun([{Args} ...])`                
`:CMakeBuldRun [{Target}, [{Args} ...]]` | `call CMakeBuldRun([{Target}, [{Args} ...]])`
`:CMakeClearArguments`                   | `call CMakeSetRunArguments('')`              
`:CMakeConfig`                           | `e CMakeLists.txt`                           

### Functions

Function                                      | Description
----------------------------------------------|------------
`call CMakeGenerate([{Options} ...])`         | Generate the build directory
`call CMakeBuild([{Target}])`                 | Build the project
`call CMakeSelectExecutable()`                | Select the executable target to run
`call CMakeRun([{Args} ...])`                 | Run the selected executable
`call CMakeBuldRun([{Target}, [{Args} ...]])` | Build and Run
`call CMakeSetRunArguments([{Args} ...])`     | Set or clear the cached arguments to Run

`call CMakeGenerate([{Options} ...])` takes an optional list of options for the
`cmake` command. These are appended to the default options set by
`g:cmake_generate_options`.

`call CMakeBuild([{Target}])` takes an optional target. If none is provided
then the whole project is built.

`call CMakeRun([{Args} ...])` takes an optional list of arguments.  If any
arguments are provided, they are cached and any following call with no
arguments will re-use the cached arguments. To clear the cached arguments, use
`call CMakeSetRunArguments('')`.

`call CMakeBuildRun([{Target}, [{Args} ...]])` calls `CMakeBuild` and
`CMakeRun` with their respective arguments. If the build fails, this function
will return the exit code of the `cmake --build` command. Otherwise run the
executable and return it's exit code.

### Configuration

Options | Description
--------|------------
`g:cmake_generate_options` | A list of string arguments for the `CMakeGenerate` function

## Licence

vim-cmake uses the [MIT](LICENCE) Licence

