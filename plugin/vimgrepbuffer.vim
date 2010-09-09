"
" Run vimgrep on buffers.
"
" Author: Jeet Sukumaran
"
" This plugin provides easy application of the 'vimgrep' command on buffers
" (as opposed to the filesystem, which is its normal mode of operation).  It
" provides two commands: one to search just the current buffer, and the other
" to search all listed buffers.  The QuickFix buffer will be populated with
" the search results, if any, and opened for viewing. The search pattern will
" also be assigned to the search register, so that matches will be highlighted
" if 'hlsearch' is on (':set hlsearch').
"
" Two commands are provided, ':G' and ':GG'. The first limits the search to
" the current buffer, while the second searches all listed buffers.
"
" If you do not like the cryptic/genericness of these 'short' commands, put:
"
"     let g:vimgrepbuffer_long_command = 1
"
" in your "~/.vimrc", and ':VimgrepBuffer' and ':VimgrepBuffers' will be set as
" the commands instead.
"
" The pattern specification is *exactly* like that for 'vimgrep'.  This means
" that if the pattern starts with a non-identifier or contains any literal whitespace
" characters, for correct behavior you will have to enclose the pattern in
" delimiter characters (e.g. "/", "@", "#"):
"
"    :G /\s*print "\d/
"    :GG /\s*def\s\+\w\+(/
"    :G /\(def\s\+\|class\s+\)/
"    :GG /\cisland/
"    :G /the quick brown \w+/
"    :GG /except \+\w\+Error/
"
" If your pattern starts with an identifier you can omit the enclosing
" delimiters:
"
"    :G def\s\+\w\+(.*\*\*kwargs)
"    :GG except\s\+\w\+Error
"
" In this latter case, the pattern will be considered to be
" whitespace-delimited, and so if your pattern contains any literal whitespace
" you may get incorrect results. This behavior is exactly like that of
" 'vimgrep'.
"

if exists("g:vimgrepbuffer_loaded")
	finish
endif

let g:vimgrepbuffer_loaded = 1

if exists("g:vimgrepbuffer_long_command") && g:vimgrepbuffer_long_command
    command! -nargs=1 VimgrepBuffer call s:VimgrepBuffer(<q-args>)
    command! -nargs=1 VimgrepBuffers call s:VimgrepAllBuffers(<q-args>)
else
    command! -nargs=1 G call s:VimgrepBuffer(<q-args>)
    command! -nargs=1 GG call s:VimgrepAllBuffers(<q-args>)
endif

" Search for pattern in current buffer and add hits to QuickFix
"     First argument (mandatory): search pattern
"     Second argument (optional): 0 = add to results instead of replacing; default = 1
"     Third argument (optional): 0 = do not assign pattern to search register; default = 1
"     Fourth argument (optional): 0 = do not open quickfix window; default = 1
function! <SID>VimgrepBuffer(pattern, ...)
    let l:vg = "vimgrep"
    let l:replace_results = 1
    let l:set_search_register = 1
    let l:view_results = 1
    if a:0 >= 1 && !a:1
        let l:replace_results = 0
        let l:vg = "vimgrepadd"
    else
        call setqflist([])
    endif
    if a:0 >= 2 && !a:2
        let l:set_search_register = 0
    endif
    if a:0 >= 3 && !a:3
        let l:view_results = 0
    endif
    try
        silent execute l:vg." ".a:pattern." %"
    catch /^Vim\%((\a\+)\)\=:E480/   " no match
        " ignore
    catch /^Vim\%((\a\+)\)\=:E499/   " empty file name for %
        " ignore
    endtry
    call s:ViewVimgrepBufferResults(a:pattern, l:set_search_register, l:view_results, bufnr("%"), getpos("."))
endfunction

" Search for pattern in all buffers and add hits to QuickFix.
function! <SID>VimgrepAllBuffers(pattern)
    let l:cur_buf = bufnr("%")
    let l:cur_pos = getpos(".")
    call setqflist([])
    cclose
    silent bufdo call s:VimgrepBuffer(a:pattern, 0, 0, 0)
    call s:ViewVimgrepBufferResults(a:pattern, 1, 1, l:cur_buf, l:cur_pos)
endfunction

" Present search results.
function! <SID>ViewVimgrepBufferResults(pattern, set_search_register, view_results, restore_buffer, restore_pos)
    if a:set_search_register
        let @/=a:pattern
    endif
    if a:view_results
        if len(getqflist()) > 0
            copen
            1cc
        else
            cclose
            silent execute "buffer ".a:restore_buffer
            silent call setpos('.', a:restore_pos)
            redraw
            echohl WarningMsg
            echo "No matches found for: ".a:pattern
            echohl None
        endif
    endif
endfunction
