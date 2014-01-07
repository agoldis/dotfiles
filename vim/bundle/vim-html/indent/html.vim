" Description:	html indenter
" Author:	Johannes Zellner <johannes@zellner.org>
" Last Change:	Tue, 27 Apr 2004 10:28:39 CEST
" 		Restoring 'cpo' and 'ic' added by Bram 2006 May 5
" Globals:	g:html_indent_tags	   -- indenting tags
"		g:html_indent_strict       -- inhibit 'O O' elements
"		g:html_indent_strict_table -- inhibit 'O -' elements

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1


" [-- local settings (must come before aborting the script) --]
setlocal indentexpr=HtmlIndentGet(v:lnum)
setlocal indentkeys=o,O,*<Return>,<>>,{,}


if exists('g:html_indent_tags')
    unlet g:html_indent_tags
endif

" [-- helper function to assemble tag list --]
fun! <SID>HtmlIndentPush(tag)
    if exists('g:html_indent_tags')
	let g:html_indent_tags = g:html_indent_tags.'\|'.a:tag
    else
	let g:html_indent_tags = a:tag
    endif
endfun


" [-- <ELEMENT ? - - ...> --]
let g:html_indent_tag_list = [
\ 'a',
\ 'abbr',
\ 'acronym',
\ 'address',
\ 'b',
\ 'bdo',
\ 'big',
\ 'blockquote',
\ 'button',
\ 'caption',
\ 'center',
\ 'cite',
\ 'code',
\ 'colgroup',
\ 'del',
\ 'dfn',
\ 'dir',
\ 'div',
\ 'dl',
\ 'em',
\ 'fieldset',
\ 'font',
\ 'form',
\ 'frameset',
\ 'h1',
\ 'h2',
\ 'h3',
\ 'h4',
\ 'h5',
\ 'h6',
\ 'i',
\ 'iframe',
\ 'ins',
\ 'kbd',
\ 'label',
\ 'legend',
\ 'map',
\ 'menu',
\ 'noframes',
\ 'noscript',
\ 'object',
\ 'ol',
\ 'optgroup',
\ 'q',
\ 's',
\ 'samp',
\ 'script',
\ 'select',
\ 'small',
\ 'span',
\ 'strong',
\ 'style',
\ 'sub',
\ 'sup',
\ 'table',
\ 'textarea',
\ 'title',
\ 'tt',
\ 'u',
\ 'ul',
\ 'var',
\]

" [-- <ELEMENT ? O O ...> --]
if !exists('g:html_indent_strict')
    let g:html_indent_tag_list += ['body', 'head', 'html', 'tbody']
endif


" [-- <ELEMENT ? O - ...> --]
if !exists('g:html_indent_strict_table')
    let g:html_indent_tag_list += ['th', 'td', 'tr', 'tfoot', 'thead']
endif

let g:html_indent_tags = join(g:html_indent_tag_list, '\|')

let s:cpo_save = &cpo
set cpo-=C

" [-- count indent-increasing tags of line a:lnum --]
fun! <SID>HtmlIndentOpen(lnum, pattern)
    let s = substitute('x'.getline(a:lnum),
    \ '.\{-}\(\(<\)\('.a:pattern.'\)\>\)', "\1", 'g')
    let s = substitute(s, "[^\1].*$", '', '')
    return strlen(s)
endfun

" [-- count indent-decreasing tags of line a:lnum --]
fun! <SID>HtmlIndentClose(lnum, pattern)
    let s = substitute('x'.getline(a:lnum),
    \ '.\{-}\(\(<\)/\('.a:pattern.'\)\>>\)', "\1", 'g')
    let s = substitute(s, "[^\1].*$", '', '')
    return strlen(s)
endfun

" [-- count indent-increasing '{' of (java|css) line a:lnum --]
fun! <SID>HtmlIndentOpenAlt(lnum)
    return strlen(substitute(getline(a:lnum), '[^{]\+', '', 'g'))
endfun

" [-- count indent-decreasing '}' of (java|css) line a:lnum --]
fun! <SID>HtmlIndentCloseAlt(lnum)
    return strlen(substitute(getline(a:lnum), '[^}]\+', '', 'g'))
endfun

" [-- return the sum of indents respecting the syntax of a:lnum --]
fun! <SID>HtmlIndentSum(lnum, style)
    if a:style == match(getline(a:lnum), '^\s*</')
	if a:style == match(getline(a:lnum), '^\s*</\<\('.g:html_indent_tags.'\)\>')
	    let open = <SID>HtmlIndentOpen(a:lnum, g:html_indent_tags)
	    let close = <SID>HtmlIndentClose(a:lnum, g:html_indent_tags)
	    if 0 != open || 0 != close
		return open - close
	    endif
	endif
    endif
    if '' != &syntax &&
	\ synIDattr(synID(a:lnum, 1, 1), 'name') =~ '\(css\|java\).*' &&
	\ synIDattr(synID(a:lnum, strlen(getline(a:lnum)), 1), 'name')
	\ =~ '\(css\|java\).*'
	if a:style == match(getline(a:lnum), '^\s*}')
	    return <SID>HtmlIndentOpenAlt(a:lnum) - <SID>HtmlIndentCloseAlt(a:lnum)
	endif
    endif
    return 0
endfun

fun! s:getSyntaxName(lnum, re)
	return synIDattr(synID(a:lnum, match(getline(a:lnum), a:re) + 1, 0), "name")
endfun

fun! s:isSyntaxElem(lnum, re, elem)
	if getline(a:lnum) =~ a:re && s:getSyntaxName(a:lnum, a:re) == a:elem
		return 1
	endif
	return 0
endfun

fun! HtmlIndentGet(lnum)
    " Find a non-empty line above the current line.
    let lnum = prevnonblank(a:lnum - 1)

    " Hit the start of the file, use zero indent.
    if lnum == 0
	return 0
    endif

    let restore_ic = &ic
    setlocal ic " ignore case

    " [-- special handling for <pre>: no indenting --]
    if getline(a:lnum) =~ '\c</pre>'
		\ || 0 < searchpair('\c<pre>', '', '\c</pre>', 'nWb')
		\ || 0 < searchpair('\c<pre>', '', '\c</pre>', 'nW')
	" we're in a line with </pre> or inside <pre> ... </pre>
	if restore_ic == 0
	  setlocal noic
	endif
	return -1
    endif

    " [-- special handling for <javascript>: use cindent --]
    let js = '<script.*type\s*=\s*.*java'
    if   0 < searchpair(js, '', '</script>', 'nWb')
    \ || 0 < searchpair(js, '', '</script>', 'nW')
	" we're inside javascript
	if getline(lnum) !~ js && getline(a:lnum) !~ js
	    if restore_ic == 0
	      setlocal noic
	    endif
		" Open and close bracket:
		if s:isSyntaxElem(lnum, '{', "javaScriptBraces") && s:isSyntaxElem(a:lnum, '}', "javaScriptBraces")
			return indent(lnum)
		elseif s:isSyntaxElem(lnum, '{', "javaScriptBraces")
			return indent(lnum) + &sw
		elseif s:isSyntaxElem(a:lnum, '}', "javaScriptBraces")
			if s:isSyntaxElem(lnum, 'break', 'javaScriptBranch') && ! s:isSyntaxElem(lnum, '\(case\|default\)', "javaScriptLabel")
				return indent(lnum) - 2 * &sw
			endif
			return indent(lnum) - &sw
		endif

		" cases:
		if s:isSyntaxElem(lnum, '\(case\|default\)', "javaScriptLabel") && s:isSyntaxElem(a:lnum, '\(case\|default\)', "javaScriptLabel")
			return indent(lnum)
		elseif s:isSyntaxElem(lnum, '\(case\|default\)', "javaScriptLabel")
			return indent(lnum) + &sw
		elseif s:isSyntaxElem(a:lnum, '\(case\|default\)', "javaScriptLabel")
			return indent(lnum) - &sw
		endif

		if getline(a:lnum) =~ '\c</script>'
			let scriptline = prevnonblank(search(js, 'bW'))
			if scriptline > 0
				return indent(scriptline)
			endif
		endif
		return indent(lnum)
	endif
    endif

    if getline(a:lnum) =~ '\c</\?body' || getline(a:lnum) =~ '\c</\?html' || getline(a:lnum) =~ '\c</\?head'
		return 0
	endif
    if getline(lnum) =~ '\c</\?body' || getline(lnum) =~ '\c</\?html' || getline(lnum) =~ '\c</\?head'
		return 0
	endif

    if getline(lnum) =~ '\c</pre>'
	" line before the current line a:lnum contains
	" a closing </pre>. --> search for line before
	" starting <pre> to restore the indent.
	let preline = prevnonblank(search('\c<pre>', 'bW') - 1)
	if preline > 0
	    if restore_ic == 0
	      setlocal noic
	    endif
	    return indent(preline)
	endif
    endif

    let ind = <SID>HtmlIndentSum(lnum, -1)
    let ind = ind + <SID>HtmlIndentSum(a:lnum, 0)

    if restore_ic == 0
	setlocal noic
    endif

    return indent(lnum) + (&sw * ind)
endfun

let &cpo = s:cpo_save
unlet s:cpo_save

" [-- EOF <runtime>/indent/html.vim --]
