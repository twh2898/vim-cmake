
if exists('g:loaded_cmake') && g:loaded_cmake
    finish
endif

" Commands

command! -nargs=* CMakeGenerate call cmake#Generate(<f-args>)

command! -nargs=? CMakeBuild call cmake#Build(<f-args>)
command! -nargs=* CMakeRun call cmake#Run(<f-args>)
command! -nargs=* CMakeBuildRun call cmake#BuildRun('', <f-args>)

command! CMakeSelectExecutable call cmake#SelectExecutable()
command! CMakeClearArguments call cmake#SetRunArguments('')

command! CMakeConfig e CMakeLists.txt

