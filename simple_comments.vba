" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
doc/simple_comments.txt	[[[1
121
*simple_comments.txt*      simple_comments help                     2009-03-01
==============================================================================
1. Intro                                               *simple_comments-intro*

   This is a plugin to comment out or remove comments from lines in sourcecode
   using the |commentsring| variable. It is intended to be as simple as
   possible and can only handle the commenting/uncommenting of whole lines.

   Also, only the |commentstring| comments are handled, which may give
   problems in languages such as C++ where both /**/ and // comments are
   allowed.

   For filetypes where the commentstring setting is incorrect it can be
   changed by editing ftplugin/<filetype>.vim and adding a line such as

        setlocal commentstring=/*\ %s\ */

   This specifies a C comment.  Spaces in the |commentstring| setting must be
   escaped. 

==============================================================================
2. Setup                                             *simple_comments-mapping*

   The default key mappings for this plugin are:

     <M-x> Add comments to the current line, a visual selection or range.
     <M-z> Remove comments from current line, range or visual selection.

   The mappings can be changed.  See |simple_comments-customizing|. 

==============================================================================
3. Customizing                                   *simple_comments-customizing*

   The following variables can be used to customize this plugin:

     |g:simple_comments_Comment|
     |g:simple_comments_Remove|
     |g:simple_comments_LeftPlaceHolder|
     |g:simple_comments_RightPlaceHolder|
     |g:simple_comments_SyntaxDictionary|

------------------------------------------------------------------------------
                                                   *g:simple_comments_Comment*

   Specifies the mapping to use to comment out a line.  It can be changed using
   the following:

     let g:simple_comments_Comment = '<M-x>'

------------------------------------------------------------------------------
                                                    *g:simple_comments_Remove*

   Specifies the mapping to use to remove comments from a line.  It can be
   changed using the following:

     let g:simple_comments_Remove = '<M-z>'

------------------------------------------------------------------------------
                                           *g:simple_comments_LeftPlaceHolder*
                                          *g:simple_comments_RightPlaceHolder*

   If the commentsring contains a left and a right side, adding comments to a
   line that already contains comments will cause the original comments to be
   replaced with the contents of these variables.  Example:
   
     Commenting the line
   
       /* int i = 0; */
   
     Will result in
   
       /* [> int i = 0; <] */
   
   When uncommenting the line again the original comments will be restored.
   Default settings are:
   
     let g:simple_comments_LeftPlaceHolder = '[>'
     let g:simple_comments_LeftPlaceHolder = '<]'
   
------------------------------------------------------------------------------
                                         *g:simple_comments_SyntaxDictionary*

   If editing a file that contains different languages using different types
   of comments, the language specific comments can be specified in this
   dictionary.
   
   The |commentstring| will be used as usual if there is no entry for the
   current |filetype| in this dictionary.  Note that also comments for the
   current filetype must be specified in the dictionary.
   
   A useful setting for editing html files:
   
       let www = {'html': '<!-- %s -->', 'css': '/* %s */', 'java': '// %s' } 
       let g:simple_comments_SyntaxDictionary = {'html': www, 'xhtml':www }
   
   To decide which comments to use for a line the first lower case characters
   of the |synIDattr| name is used.  To find out what these characters are the
   following command can be used:

      :echo synIDattr(synID(line("."), col("."), 0), "name")

==============================================================================
4. History

v253  fix: Variable names and autocommands, vim7 needed
      add: commenting according to syntax in current line to handle files with
           different languages such as html + javascript.  User must specify a
           Dictionary containing alternative languages.

v249  fix: s:left and friends changed to b:left, ... doh!
      fix: Preserve space on left hand side of the commented line and handle
           commentstrings with space nicely
      fix: renamed buffer variables to better names

v243  Initial version

==============================================================================
Author: Anders Thøgersen <anders@bladre.dk>
Version: $Id: simple_comments.txt 253 2009-03-03 03:52:03Z alt $
==============================================================================
vim:tw=78:ts=8:ft=help
plugin/simple_comments.vim	[[[1
163
" author: Anders Thøgersen <anders@bladre.dk>
" $Id: simple_comments.vim 253 2009-03-03 03:46:18Z alt $
"
" This is a very simple commenter that uses the commentstring variable.  There
" are other much more advanced commenting scripts on vim.org, but I wanted
" something very simple for my needs.
"
" See simple_comments.txt for more info

if exists('loaded_simple_comments') || &cp
    finish
endif
if v:version < 700
    echoerr "simple_comments: this plugin requires vim >= 7."
    finish
endif
let loaded_simple_comments = 1

let s:savedCpo = &cpoptions
set cpoptions&vim

" Initialization
fun! s:AddVar(var, val)
    if ! exists(a:var)
        exe 'let '. a:var ." = '". a:val ."'"
    endif
endfun

call s:AddVar('g:simple_comments_Comment', '<M-x>')
call s:AddVar('g:simple_comments_Remove',  '<M-z>')
call s:AddVar('g:simple_comments_LeftPlaceHolder',  '[>')
call s:AddVar('g:simple_comments_RightPlaceHolder', '<]')
if ! exists('g:simple_comments_SyntaxDictionary')
    let g:simple_comments_SyntaxDictionary = {}
endif

exe 'nmap <silent> '. g:simple_comments_Comment .' :call <SID>CommentRememberCursor("C")<CR>'
exe 'nmap <silent> '. g:simple_comments_Remove  .' :call <SID>CommentRememberCursor("D")<CR>'

exe 'imap <silent> '. g:simple_comments_Comment .' <C-o>:call <SID>AddComment()<CR>'
exe 'imap <silent> '. g:simple_comments_Remove  .' <C-o>:call <SID>DelComment()<CR>'

exe 'vmap <silent> '. g:simple_comments_Comment .' :call <SID>CommentRememberCursor("C")<CR>'
exe 'vmap <silent> '. g:simple_comments_Remove  .' :call <SID>CommentRememberCursor("D")<CR>'

" Clean up 
delfunction s:AddVar
unlet g:simple_comments_Remove
unlet g:simple_comments_Comment

" Called in the autocommands
fun! s:SetCommentVars(comstr, name)
    exe "let b:simple_comments_".a:name."left       = substitute('".a:comstr."', '\\(.*\\)%s.*', '\\1', '')"
    exe "let b:simple_comments_".a:name."right      = substitute('".a:comstr."', '.*%s\\(.*\\)', '\\1', 'g')"
    exe "let b:simple_comments_".a:name."left_del   = substitute(b:simple_comments_".a:name."left, '\\s\\+', '', 'g')"
    exe "let b:simple_comments_".a:name."right_del  = substitute(b:simple_comments_".a:name."right, '\\s\\+', '', 'g')"
endfun

fun! s:SetAllCommentVars()
    call s:SetCommentVars(&commentstring, '')
    " Do we use a syntax comment?
    if has_key(g:simple_comments_SyntaxDictionary, &filetype)
        let com = g:simple_comments_SyntaxDictionary[&filetype]
        for key in keys(com)
            call s:SetCommentVars(com[key], key)
        endfor
        call s:SetSynComments()
    endif
endfun

fun! s:GetAltName()
    let mycol  = col(".")
    let myline = line(".")
    normal ^
    call search('\S', 'c', line("."))
    let ign = &ignorecase
    set noignorecase
    let name = substitute(synIDattr(synID(myline, col("."), 0), "name"), '^\([a-z]*\).*$', '\1', '')
    exe 'let &ignorecase = '. ign
    call cursor(myline, mycol)
    return name
endfun

fun! s:SetSynComments()
    let name = s:GetAltName()
    exe "let b:simple_comments_left = b:simple_comments_".name .'left' 
    exe "let b:simple_comments_right = b:simple_comments_".name .'right' 
    exe "let b:simple_comments_left_del = b:simple_comments_".name .'left_del' 
    exe "let b:simple_comments_right_del = b:simple_comments_".name .'right_del' 
endfun

fun! s:AddComment()
    let line  = getline(".")
    if line =~ '^\s*$'
        return
    endif
    if has_key(g:simple_comments_SyntaxDictionary, &filetype)
        call s:SetSynComments()
    endif

    " Toggle previous comment
    if b:simple_comments_right != '' && stridx(line, b:simple_comments_left_del) != -1
        exe ':silent! s/^\(\s*\)'.escape(b:simple_comments_left_del,'[].\\/*').'\s*/\1'.g:simple_comments_LeftPlaceHolder.'/'
    endif
    if b:simple_comments_right != '' && stridx(line, b:simple_comments_right) != -1
        exe ':silent! s/\s*'.escape(b:simple_comments_right_del,'[].\\/*').'\s*$/'.g:simple_comments_RightPlaceHolder.'/'
    endif
    " Add commentstring
    exe ':silent! s/^\(\s*\)/\1'.escape(b:simple_comments_left, '[].\\/*').'/'
    if b:simple_comments_right != ''
        exe ':silent! s/\s*$/'.escape(b:simple_comments_right,'[].\\/*').'/'
    endif
endfun

fun! s:DelComment()
    let line  = getline(".")
    if has_key(g:simple_comments_SyntaxDictionary, &filetype)
        call s:SetSynComments()
    endif
    " Delete comments
    if stridx(line, b:simple_comments_left_del) != -1
        exe ':silent! s/^\(\s*\)'.escape(b:simple_comments_left_del,'[].\\/*').'\s*/\1/'
    endif
    if b:simple_comments_right != '' && stridx(line, b:simple_comments_right_del) != -1
        exe ':silent! s/'.escape(b:simple_comments_right_del,'[].\\/*').'\s*$//'
    endif
    " Re-insert old comments
    if stridx(line, g:simple_comments_LeftPlaceHolder) != -1
        exe ':silent! s/^\(\s*\)'.escape(g:simple_comments_LeftPlaceHolder,'[').'/\1'.escape(b:simple_comments_left,'[].\\/*').'/'
    endif
    if stridx(line, g:simple_comments_RightPlaceHolder) != -1
        exe ':silent! s/'.escape(g:simple_comments_RightPlaceHolder,']').'\s*$/'.escape(b:simple_comments_right,'[].\\/*').'/'
    endif
endfun

fun! s:CommentRememberCursor(action) range
    let saveCursor = getpos(".")
    " Insertion and deletion of comments is done backwards to set the right
    " comments according to g:simple_comments_SyntaxDictionary 
    if a:action == 'D'
        let l:count = a:lastline
        while l:count >= a:firstline
            exe ':'. string(l:count) .'call s:DelComment()'
            let l:count -= 1
        endwhile
    elseif a:action == 'C'
        let l:count = a:lastline
        while l:count >= a:firstline
            exe ':'. string(l:count) .'call s:AddComment()'
            let l:count -= 1
        endwhile
    endif
    call setpos('.', saveCursor)
endfun

augroup COMMENTS
    autocmd!
    autocmd FileType    * call s:SetAllCommentVars()
    autocmd BufWinEnter * if has_key(g:simple_comments_SyntaxDictionary, &filetype) | call s:SetSynComments() | endif
augroup END

let &cpoptions = s:savedCpo

