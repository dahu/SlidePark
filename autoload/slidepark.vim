function! slidepark#interface()
  let obj = {}
  let obj.output = []
  let obj.style = {}
  let obj.renderer = renderers#figlet()

  func obj.paste(...)
    let result = []
    let first = a:1
    call extend(result, list#zip(result, first, ' '))
    let rest = a:000[1:]
    for a in rest
      let result = list#zip(result, a, ' ')
    endfor
    return result
  endfunc

  func obj.heading(level, text) dict
    let s = self.style['h' . a:level]
    call add(self.output, self.renderer.as_s(s.style, a:text, s.opts))
    return self
  endfunc

  func obj.blocklabel(text) dict
    let s = self.style['label']
    call add(self.output, "\n" . self.renderer.as_s(s.style, a:text, s.opts))
    return self
  endfunc

  func obj.plaintext(text) dict
    let s = self.style['plain']
    call add(self.output, self.renderer.as_s(s.style, a:text, s.opts))
    return self
  endfunc

  func obj.list_item(level, index, text) dict
    let level    = a:level
    let s        = self.style['list']
    let spc_char = self.renderer.as_l(s.style, repeat('M', len(a:index)), s.opts)
    let bheight  = len(spc_char)
    let bhalfh   = ((bheight)/2)
    let bwidth   = len(spc_char[0])+1
    let bullet   = self.renderer.as_l(s.style, a:index, s.opts)
    let indent   = (bwidth * level)
    let text     = Asif(a:text, 'text', ['set tw=' . (&tw-indent), 'norm! gqap'])

    let text = extend(repeat([''], (bhalfh - (len(text)/2))), text)
    if bheight < len(text)
      call extend(bullet, repeat([repeat(' ', bwidth-1)], (len(text)-len(bullet))))
    endif
    let spacing = repeat([repeat(' ', indent)], max([bheight, len(text)]))
    call add(self.output, join(self.paste(spacing, bullet, text), "\n"))
    return self
  endfunc

  func obj.to_s() dict
    return join(self.output, "\n")
  endfunc

  func obj.render(text) dict
  endfunc

  return obj
endfunction


function! slidepark#asciidocish()
  let obj = slidepark#interface()
  for s in [
        \  [ 'h0'   , '^=\s\+'     , 'normal' , {'style':''} ]
        \, [ 'h1'   , '^==\s\+'    , 'small'  , {'style':''} ]
        \, [ 'h2'   , '^===\s\+'   , 'thin'   , {}           ]
        \, [ 'h3'   , '^====\s\+'  , 'mini'   , {'style':''} ]
        \, [ 'h4'   , '^=====\s\+' , 'compact', {'style':''} ]
        \, [ 'list' , '^[.*]\+\s\+', 'bullet' , {'style':''} ]
        \, [ 'label', '^\.\S\+'    , 'tiny'   , {'style':'', 'wide':'', 'upper':''} ]
        \, [ 'plain', '^\w\+'      , 'tiny'   , {'style':''} ]
        \  ]
    let obj.style[s[0]] = {'inline': s[1], 'style': s[2], 'opts': s[3]}
  endfor

  func! obj.render(text) dict
    let list_index = 0
    let numeric = Series(1, 1)
    let alphaic = Series(1, 1, 'nexus#alpha')
    let romanic = Series(1, 1, 'nexus#roman')
    let seqs = [numeric, alphaic, romanic]
    let bullets = ['*', '-']
    for line in a:text
      if line =~ '^\s*$'
        continue
      endif
      let rendered = 0
      for [style, settings] in items(self.style)
        if match(line, settings.inline) != -1
          if style == 'list'
            let level = len(matchstr(line, '^\s*\zs[.*]\+')) - 1
            if level > prior_level
              let list_index = 0
            elseif level == prior_level
              let list_index += 1
            else
              let list_index = prior_index + 1
            endif
            let type = matchstr(line, '^\s*\zs[.*]')[0]
            if type == '.'
              let list_item = seqs[level % 3].value(list_index)
            else
              let list_index = 0
              let list_item = bullets[level % 2]
            end
            let list_text = matchstr(line, '^\s*[.*]\+\s*\zs.*')
            call self.list_item(level, list_item, list_text)
            let prior_level = level
            let prior_index = list_index
          elseif style =~ 'h\d'
            call self.heading(matchstr(style, '\d'), matchstr(line, '^=\+\s\+\zs.*'))
          elseif style == 'label'
            call self.blocklabel(matchstr(line, '^\.\zs.*'))
          elseif style == 'plain'
            call self.plaintext(line)
          else
            echohl Warning
            echom 'Unknown style: ' . style
            echohl None
          endif
          let rendered = 1
          break
        elseif line =~ '^\s\+'
          if list_index > 0
          else
          endif
        endif
      endfor
      if ! rendered
        echohl Warning
        echom 'Unrendered Line: ' . line
        echohl None
      endif
    endfor
    return self
  endfunc
endfunction


let sp = slidepark#asciidocish()
echo sp.render(getline(search('^finish$')+1, '$')).to_s()

finish

= Main Heading

A plain text line

== First Heading

Another plain text line

=== Second Heading

. A numbered list item A numbered And another numbered list iteAnd another numbered list itemmAnd another numbered list item
.. And continued with indentation here

.A block label:

* A bullet list item
** and another
** and another
*** and another
*** and another
** and another
