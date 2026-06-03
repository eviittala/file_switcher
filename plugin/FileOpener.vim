vim9script

if !has("python3")
    echom "vim has to be compiled with +python3 to run this"
    finish
endif

if exists('fileSwitcherOpenerLoaded')
    finish
endif

var fileSwitcherOpenerLoaded = 1
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
var filePat: string

def Callback(winId: number, result: number): void
    echomsg "winId: " .. winId .. " result: " .. result
    if 0 < result
        var val: number = result == 1 ? result :  result - 1
        var content: list<string> = GetMenuContent()
        if val < len(content)
            echomsg "You choose: " .. content[val]
            execute "edit " .. content[val]
        endif
    endif
enddef

def ParseFiles(): list<string>
    var ret: list<string>
    for item in files
        if 0 < len(filePat) 
            if item =~ filePat
                ret += [item]
            endif
        else
            ret += [item]
        endif
        if 10 < len(ret)
            break
        endif
    endfor
    return ret
enddef

def GetMenuContent(): list<string>
    var ret: list<string> = [filePat]
    for item in ParseFiles()
       ret += [item]
    endfor
    return ret
enddef

def MyMenuFilter(winId: number, key: string): bool
    echomsg "winId: " .. winId .. " key: " .. key

    if key == "\<DOWN>"
       popup_setoptions(winId, {cursorline: 1}) 
    endif

    if key == "\<BS>" && 0 < len(filePat)
       #echomsg 'Erasing filepat'
       filePat = filePat[0 : -2]
       var content: list<string> = GetMenuContent()
       var minWidth: number = GetMinWidth(content)
       popup_setoptions(winId, {minwidth: minWidth}) 
       popup_settext(winId, content)
       return true
    endif

    if key =~ '\v^[a-zA-Z0-9.]{1}$'
       filePat = filePat .. key
       var content: list<string> = GetMenuContent()
       var minWidth: number = GetMinWidth(content)
       popup_setoptions(winId, {minwidth: minWidth}) 
       popup_settext(winId, content)
       return true
    endif

    return popup_filter_menu(winId, key)
enddef

def GetMinWidth(content: list<string>): number
    var width: number = 0
    for item in content
        if width < len(item)
            width = len(item)
        endif
    endfor
    return width + 1
enddef

def ShowPopup(): void
    var content: list<string> = GetMenuContent()
    var minWidth: number = GetMinWidth(content)
    popup_create(content, {
                \ title: ' Please choose a file ',
                \ filter: 'MyMenuFilter',
                \ wrap: 0,
                \ cursorline: 0,
                \ callback: 'Callback',
                \ minwidth: minWidth,
                \ maxwidth: 500,
                \ })
enddef    

def GetFiles(): void
    files = py3eval("fs.get_files_from_tags()")
enddef

def IsCurrentBufferSaved(): bool
    var isModified: bool = &modified
    if isModified
        echomsg "Please save your changes first"
        return false
    endif
    return true
enddef

def g:FileOpener(): void
    if IsCurrentBufferSaved()
        filePat = ""
        GetFiles()
        ShowPopup()
    endif
enddef

nnoremap <leader>o :call FileOpener()<CR>
