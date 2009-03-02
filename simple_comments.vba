" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
doc/simple_comments.txt	[[[1
93
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

==============================================================================
4. History

v249  fix: s:left and friends changed to b:left, ... doh!
      fix: Preserve space on left hand side of the commented line and handle
           commentstrings with space nicely
      fix: renamed buffer variables to better names

v243  Initial version

==============================================================================
Author: Anders Thøgersen <anders@bladre.dk>
Version: $Id: simple_comments.txt 249 2009-03-02 01:30:38Z alt $
==============================================================================
vim:tw=78:ts=8:ft=help
plugin/simple_comments.vim	[[[1
106
" author: Anders Thøgersen <anders@bladre.dk>
" $Id: simple_comments.vim 248 2009-03-02 01:21:46Z alt $
"
" This is a very simple commenter that uses the commentstring variable.  There
" are other much more advanced commenting scripts on vim.org, but I wanted
" something very simple for my needs.
"
" See simple_comments.txt for more info

if exists('loaded_vimcomenter') || &cp
    finish
endif
let loaded_vimcommenter = 1

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

exe 'nmap <silent> '. g:simple_comments_Comment .' :call <SID>CommentRememberCursor("C")<CR>'
exe 'nmap <silent> '. g:simple_comments_Remove  .' :call <SID>CommentRememberCursor("D")<CR>'

exe 'imap <silent> '. g:simple_comments_Comment .' <C-o>:call <SID>AddComment()<CR>'
exe 'imap <silent> '. g:simple_comments_Remove  .' <C-o>:call <SID>DelComment()<CR>'

exe 'vmap <silent> '. g:simple_comments_Comment .' :call <SID>CommentRememberCursor("C")<CR>'
exe 'vmap <silent> '. g:simple_comments_Remove  .' :call <SID>CommentRememberCursor("D")<CR>'

delfunction s:AddVar

" Called in the autocommands
fun! s:SetCommentVars()
    let b:simple_comments_left       = substitute(&commentstring, '\(.*\)%s.*', '\1', '')
    let b:simple_comments_right      = substitute(&commentstring, '.*%s\(.*\)', '\1', 'g')
    let b:simple_comments_eleft      = escape(b:simple_comments_left, '/*\.[]$^ ')
    let b:simple_comments_eright     = escape(b:simple_comments_right, '/*\.[]$^ ')
    let b:simple_comments_left_del   = substitute(b:simple_comments_left, '\s\+', '', 'g')
    let b:simple_comments_eleft_del  = escape(b:simple_comments_left_del, '/*\.[]$^')
    let b:simple_comments_right_del  = substitute(b:simple_comments_right, '\s\+', '', 'g')
    let b:simple_comments_eright_del = escape(b:simple_comments_right_del, '/*\.[]$^')
endfun

fun! s:AddComment()
    let line  = getline(".")
    if line =~ '^\s*$'
        return
    endif
    " Toggle previous comment
    if b:simple_comments_right != '' && stridx(line, b:simple_comments_left_del) != -1
        exe ':silent! s/^\(\s*\)'.b:simple_comments_eleft_del.'\s*/\1'.g:simple_comments_LeftPlaceHolder.'/'
    endif
    if b:simple_comments_right != '' && stridx(line, b:simple_comments_right) != -1
        exe ':silent! s/\s*'.b:simple_comments_eright_del.'\s*$/'.g:simple_comments_RightPlaceHolder.'/'
    endif
    " Add commentstring
    exe ':silent! s/^\(\s*\)/\1'. b:simple_comments_eleft.'/'
    if b:simple_comments_right != ''
        exe ':silent! s/\s*$/'.b:simple_comments_eright.'/'
    endif
endfun

fun! s:DelComment()
    let line  = getline(".")
    " Delete comments
    if stridx(line, b:simple_comments_left_del) != -1
        exe ':silent! s/^\(\s*\)'.b:simple_comments_eleft_del.'\s*/\1/'
    endif
    if b:simple_comments_right != '' && stridx(line, b:simple_comments_right_del) != -1
        exe ':silent! s/'.b:simple_comments_eright_del.'\s*$//'
    endif
    " Re-insert old comments
    if stridx(line, g:simple_comments_LeftPlaceHolder) != -1
        exe ':silent! s/^\(\s*\)'.escape(g:simple_comments_LeftPlaceHolder,'[').'/\1'.b:simple_comments_eleft.'/'
    endif
    if stridx(line, g:simple_comments_RightPlaceHolder) != -1
        exe ':silent! s/'.escape(g:simple_comments_RightPlaceHolder,']').'\s*$/'.b:simple_comments_eright.'/'
    endif
endfun

fun! s:CommentRememberCursor(action) range
    let saveCursor = getpos(".")
    if a:action == 'D'
        exe a:firstline .','. a:lastline . 'call s:DelComment()'
    elseif a:action == 'C'
        exe a:firstline .','. a:lastline . 'call s:AddComment()'
    endif
    call setpos('.', saveCursor)
endfun

augroup COMMENTS
    autocmd!
    autocmd FileType * call s:SetCommentVars()
augroup END

let &cpoptions = s:savedCpo

