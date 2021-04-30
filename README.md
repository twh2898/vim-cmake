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
- Run tests
- Cached selection and arguments between sessions

## Usage

### Commands

Command                                  | Mapping                                      
-----------------------------------------|----------------------------------------------
`:CMakeGenerate [{Options} ...]`         | `call cmake#Generate([{Options} ...])`        
`:CMakeBuild [{Target}]`                 | `call cmake#Build([{Target}])`                
`:CMakeSelectExecutable`                 | `call cmake#SelectExecutable()`               
`:CMakeRun [{Args} ...]`                 | `call cmake#Run([{Args} ...])`                
`:CMakeBuldRun [{Target}, [{Args} ...]]` | `call cmake#BuldRun([{Target}, [{Args} ...]])`
`:CMakeTest [{Args} ...]`                | `call cmake#Test([{Args} ...])`
`:CMakeClearArguments`                   | `call cmake#SetRunArguments('')`              
`:CMakeConfig`                           | `e CMakeLists.txt`                           

### Functions

Function                                       | Description
-----------------------------------------------|------------
`call cmake#Generate([{Options} ...])`         | Generate the build directory
`call cmake#Build([{Target}])`                 | Build the project
`call cmake#SelectExecutable()`                | Select the executable target to run
`call cmake#Run([{Args} ...])`                 | Run the selected executable
`call cmake#BuldRun([{Target}, [{Args} ...]])` | Build and Run
`call cmake#Test([{Args} ...])`                | Run tests
`call cmake#SetRunArguments([{Args} ...])`     | Set or clear the cached arguments to Run

`call cmake#Generate([{Options} ...])` takes an optional list of options for the
`cmake` command. These are appended to the default options set by
`g:cmake_generate_options`.

`call cmake#Build([{Target}])` takes an optional target. If none is provided
then the whole project is built.

`call cmake#Run([{Args} ...])` takes an optional list of arguments.  If any
arguments are provided, they are cached and any following call with no
arguments will re-use the cached arguments. To clear the cached arguments, use
`call cmake#SetRunArguments('')`.

`call cmake#BuildRun([{Target}, [{Args} ...]])` calls `cmake#Build` and
`cmake#Run` with their respective arguments. If the build fails, this function
will return the exit code of the `cmake --build` command. Otherwise run the
executable and return it's exit code.

### Configuration

Options | Description
--------|------------
`g:cmake_generate_options` | A list of string arguments for the `cmake#Generate` function

## Licence

vim-cmake uses the [MIT](LICENCE) Licence

