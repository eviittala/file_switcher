vim9script

if !has("python3")
    echom "vim has to be compiled with +python3 to run this"
    finish
endif

if exists('fileSwitcherLoaded')
    finish
endif

var fileSwitcherLoaded = 1
var plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

python3 << EOF
import sys
from os.path import normpath, join
import vim
plugin_root_dir = vim.eval('plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)
import FileSwitcher as fs
EOF

var files: list<string>

def OpenFile(file: string): void
    var txt: string = "Changing to " .. file
    echowindow txt
    execute "edit " .. file
    files = []
enddef

def SelectFile(id: number, result: number): void
    OpenFile(files[result - 1])
enddef

def ShowDialog(): void
    var pos = getpos('.')
    popup_create(files, {
        \ line: pos[1] + 1,
        \ col: pos[2],
        \ zindex: 200,
        \ drag: 1,
        \ wrap: 0,
        \ border: [],
        \ cursorline: 1,
        \ padding: [0, 1, 0, 1],
        \ filter: 'popup_filter_menu',
        \ mapping: 0,
        \ callback: 'SelectFile',
        \ })
enddef

def IsValidFile(file: string): bool
    var ext: string = expand('%:e')
    if ext =~ '\v(c|cpp|h|hpp)\c'
        return true
    endif
    echomsg "Not valid file: " .. file
    return false
enddef

def IsCurrentBufferSaved(): bool
    var isModified: bool = &modified
    if isModified
        echomsg "Please save your changes first"
        return false
    endif
    return true
enddef

def g:CallFileSwitcher(): void
    var current_file: string = expand('%')
    if IsValidFile(current_file) && IsCurrentBufferSaved()
        files = py3eval("fs.get_files()")
        if 1 < len(files)
            ShowDialog()
        elseif len(files) == 1
            OpenFile(files[0])
        elseif len(files) == 0
            echomsg "Cannot find switchable file for " .. current_file
        endif
    endif
enddef

nnoremap <leader>q :call CallFileSwitcher()<CR>
