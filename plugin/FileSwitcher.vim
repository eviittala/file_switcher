vim9script

if !has("python3")
    echom "vim has to be compiled with +python3 to run this"
    finish
endif

if exists('fileSwitcherOpenerLoaded')
    finish
endif

var fileSwitcherOpenerLoaded = 1

var files: list<string>
var filePat: string
var other_files: list<string>

def Callback(winId: number, result: number): void
    # echomsg "winId: " .. winId .. " result: " .. result
    if 0 < result
        var val: number = result == 1 ? result :  result - 1
        var content: list<string> = GetMenuContent()
        if val < len(content)
            #echomsg "You choose: " .. content[val]
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
    # echomsg "winId: " .. winId .. " key: " .. key
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

    if key =~ '\v^[a-zA-Z0-9._-]{1}$'
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
    var winId = popup_create(content, {
                \ title: ' Please choose a file ',
                \ filter: 'MyMenuFilter',
                \ wrap: 0,
                \ cursorline: 0,
                \ callback: 'Callback',
                \ minwidth: minWidth,
                \ maxwidth: 500,
                \ })
                
    highlight MyPopupColor ctermbg=lightblue cterm=bold
    call setwinvar(winId, '&wincolor', 'MyPopupColor')
enddef    

def SelectFile(id: number, result: number): void
    if 0 < result
        OpenFile(other_files[result - 1])
    endif
enddef

def ShowDialog(): void
    popup_menu(other_files, {
        \ callback: 'SelectFile',
        \ })
enddef

def GetFilesFromTags(): void
    # Old function:
    # files = py3eval("fs.get_files_from_tags()")
    # TODO Eero: Add sha256(file) and if content has been changed, reload the file
    if len(files) == 0
        for line in readfile("tags")
            var txt = split(line, '\t')
            files->add(txt[1])
        endfor
        uniq(sort(files))
    endif
enddef

def IsCurrentBufferSaved(): bool
    var isModified: bool = &modified
    if isModified
        echomsg "Please save your changes first"
        return false
    endif
    return true
enddef

def Exists(file: string): bool
    if !filereadable(file)
        echomsg "Cannot find file: " .. file
        return false
    endif
    return true
enddef

def g:FileOpener(): void
    if IsCurrentBufferSaved() && Exists("tags")
        filePat = ""
        GetFilesFromTags()
        ShowPopup()
    endif
enddef

def IsValidFile(): bool
    var current_file: string = expand('%')
    var ext: string = expand('%:e')
    if ext =~ '\v(c|cpp|h|hpp)\c'
        return true
    endif
    echomsg "Not valid file: " .. current_file
    return false
enddef

def FindOtherFiles(): list<string>
    var root_file: string = expand('%:t:r') 
    var ext: string = expand('%:e')
    var ret: list<string>

    for file in files
        if ext =~ '\v(h|hpp)\c'
            #var find_1: string = root_file .. '.c'
            #var find_2: string = root_file .. '.cpp'
            #if file =~ find_1 || file =~ find_2
            if file =~ root_file .. '\v\.(c|cpp)\c'
                ret->add(file)
            endif
        else
            #var find_1: string = root_file .. '.h'
            #var find_2: string = root_file .. '.hpp'
            #if file =~ find_1 || file =~ find_2
            if file =~ root_file .. '\v\.(h|hpp)\c'
                ret->add(file)
            endif
        endif
    endfor
    return ret
enddef

def OpenFile(file: string): void
    var txt: string = "Changing to " .. file
    echomsg txt
    execute "edit " .. file
    other_files = []
enddef

def g:FileSwitcher(): void
    if IsValidFile() && IsCurrentBufferSaved() && Exists("tags")
        GetFilesFromTags()
        other_files = FindOtherFiles()
        if 1 < len(other_files)
            ShowDialog()
        elseif len(other_files) == 1
            OpenFile(other_files[0])
        elseif len(other_files) == 0
            echomsg "Cannot find switchable file for " .. expand('%')
        endif
    endif
enddef

nnoremap <leader>o :call FileOpener()<CR>
nnoremap <leader>s :call FileSwitcher()<CR>
