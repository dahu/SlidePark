function! slidepark#interface(options)
  let obj = {}
  let obj.tw = &tw == 0 ? 70 : &tw
  let obj.output = []
  let obj.style = {}
  let obj.default_styles = {
        \  'normal'  : 'graceful'
        \, 'small'   : 'bulbhead'
        \, 'thin'    : 'thin'
        \, 'mini'    : 'mini'
        \, 'compact' : 'twopoint'
        \, 'tiny'    : 'term'
        \, 'bullet'  : 'digital'
        \}
  let obj.renderer = renderers#figlet(extend({'default_styles' : obj.default_styles}
        \, a:options))
  " let obj.renderer = renderers#figlet(a:options)

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
    " let spc_char = self.renderer.as_l(s.style, repeat('M', len(a:index)), s.opts)
    let spc_char = self.renderer.as_l(s.style, 'M', s.opts)
    let bheight  = len(spc_char)
    let bhalfh   = ((bheight)/2)
    let bwidth   = len(spc_char[0])+1
    let bullet   = self.renderer.as_l(s.style, a:index, s.opts)
    let indent   = (bwidth * level)
    let text     = Asif(a:text, 'text', ['set tw=' . (self.tw - indent), 'norm! gqap'])

    let text = extend(repeat([''], (bhalfh - (len(text)/2))), text)
    if bheight < len(text)
      call extend(bullet, repeat([repeat(' ', bwidth-1)], (len(text)-len(bullet))))
    endif
    let spacing = repeat([repeat(' ', indent)], max([bheight, len(text)]))
    call add(self.output, join(self.paste(spacing, bullet, text), "\n"))
    return self
  endfunc

  func obj.new_page() dict
    call add(self.output, "----newpage----")
  endfunc

  func obj.to_s() dict
    return join(self.output, "\n")
  endfunc

  func obj.to_l() dict
    return split(self.to_s(), "\n")
  endfunc

  func obj.render(text) dict
  endfunc

  func obj.reset() dict
    let self.output = []
    return self
  endfunc

  return obj
endfunction


function! slidepark#asciidocish(options)
  let obj = slidepark#interface(a:options)
  for s in [
        \  [ 'h0'   , '^=\s\+'     , 'normal' , {'style':''} ]
        \, [ 'h1'   , '^==\s\+'    , 'small'  , {'style':''} ]
        \, [ 'h2'   , '^===\s\+'   , 'thin'   , {'style':''} ]
        \, [ 'h3'   , '^====\s\+'  , 'mini'   , {'style':''} ]
        \, [ 'h4'   , '^=====\s\+' , 'compact', {'style':'', 'wide':''} ]
        \, [ 'list' , '^[.*]\+\s\+', 'bullet' , {'style':''} ]
        \, [ 'label', '^\.\S\+'    , 'tiny'   , {'style':'', 'wide':'', 'upper':''} ]
        \, [ 'plain', '^\w\+'      , 'tiny'   , {'style':''} ]
        \  ]
    let obj.style[s[0]] = {'inline': s[1], 'style': s[2], 'opts': s[3]}
  endfor

  func! obj.render(text) dict
    let list_index = 0
    let prior_indexes = []
    let numeric = Series(1, 1, 'nexus#sequence')
    let alphaic = Series(1, 1, 'nexus#alpha')
    let romanic = Series(1, 1, 'nexus#roman')
    let seqs = [numeric, alphaic, romanic]
    let bullets = ['*', '-']
    let blank_lines = 0

    for line in a:text
      if line =~ '^\s*$'
        let blank_lines += 1
        continue
      endif
      if blank_lines > 1
        call self.new_page()
      endif
      if line =~ '^\s*//'
        let blank_lines = 0
        continue
      endif
      let blank_lines = 0
      let rendered = 0
      for [style, settings] in items(self.style)
        if match(line, settings.inline) != -1
          if style == 'list'
            let level = len(matchstr(line, '^\s*\zs[.*]\+'))
            if level > len(prior_indexes)
              call extend(prior_indexes, repeat([1], level))
            elseif level == len(prior_indexes)
              let prior_indexes[-1] += 1
            else
              call remove(prior_indexes, level, -1)
              let prior_indexes[-1] += 1
            endif
            let level -= 1
            let list_index = prior_indexes[-1]
            let type = matchstr(line, '^\s*\zs[.*]')[0]
            if type == '.'
              let list_item = seqs[level % 3].value(list_index)
            else
              let list_item = bullets[level % 2]
            end
            let list_text = matchstr(line, '^\s*[.*]\+\s*\zs.*')
            call self.list_item(level, list_item, list_text)
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
          if style != 'list'
            let prior_indexes = []
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

  return obj
endfunction
