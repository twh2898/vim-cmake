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

`call CMakeRun([{Args} ...])` takes an optional list of arguments.
If any arguments are provided, they are cached and any following call with no
arguments will re-use the cached arguments. To clear the cached arguments, use
`call CMakeSetRunArguments('')`.

Command                                  | Mapping                                       | Description
-----------------------------------------|-----------------------------------------------|------------
`:CMakeGenerate [{Options} ...]`         | `call CMakeGenerate([{Options} ...])`         | Generate the build directory
`:CMakeBuild [{Target}]`                 | `call CMakeBuild([{Target}])`                 | Build the project or `Target` if provided
`:CMakeSelectExecutable`                 | `call CMakeSelectExecutable()`                | Prompt the user to select which executable to run
`:CMakeRun [{Args} ...]`                 | `call CMakeRun([{Args} ...])`                 | Run the selected executable with optional arguments
`:CMakeBuldRun [{Target}, [{Args} ...]]` | `call CMakeBuldRun([{Target}, [{Args ...}]])` | Build and run the project
`:CMakeClearArguments`                   | `call CMakeSetRunArguments('')`               | Clear the run arguments
`:CMakeConfig`                           | `e CMakeLists.txt`                            | Edit the CMakeLists.txt file

### Functions

Function                                      | Description
----------------------------------------------|------------
`call CMakeGenerate([{Options} ...])`         | Generate the build directory
`call CMakeBuild([{Target}])`                 | Build the project
`call CMakeSelectExecutable()`                | Select the executable target to run
`call CMakeRun([{Args} ...])`                 | Run the selected executable
`call CMakeBuldRun([{Target}, [{Args ...}]])` | Build and Run
`call CMakeSetRunArguments([{Args} ...])`     | Set or clear the cached arguments to Run

### Configuration

Options | Description
--------|------------
`g:cmake_generate_options` | A list of string arguments for the `CMakeGenerate` function

## Licence

vim-cmake uses the [MIT](LICENCE) Licence

