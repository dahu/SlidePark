let s:sfile_path = expand('<sfile>:p:h:h')

function! renderers#interface()
  let obj = {}
  let obj.default_styles = {
        \ 'massive' : ''
        \,'huge'    : ''
        \,'large'   : ''
        \,'big'     : ''
        \,'normal'  : ''
        \,'small'   : ''
        \,'mini'    : ''
        \,'compact' : ''
        \,'tiny'    : ''
        \,'bullet'  : ''
        \}
  let obj.styles = obj.default_styles

  func obj.as_s(font, text, ...) dict
    return "override me"
  endfunc

  func obj.as_l(font, text, ...) dict
    return split(call(self.as_s, [a:font, a:text] + a:000, self), "\n")
  endfunc

  return obj
endfunction

" Figlet renderer

" Bundled Figlet Fonts
" Lines  Name     Fonts
" 13     massive  crazy
" 9      huge     epic
" 7      large    banner,
" 6      big      doom, big
" 5      normal   standard
" 4      small    thick, bulbhead, bubble, graceful, small, smslant, thin
" 3      mini     digital, mini, threepoint
" 2      compact  twopoint
" 1      tiny     term, wow

" renderers#figlet(settings)
" settings is a dictionary with the optional keys:
"   default_styles  - override or extend default_styles
"   styles          - override or extend styles
"   font_dir        - location for figlet to find fonts
"   options         - controlling the figlet system command
function! renderers#figlet(...)
  let obj = renderers#interface()
  let obj.default_styles = {
        \  'massive' : 'crazy'
        \, 'huge'    : 'epic'
        \, 'large'   : 'banner'
        \, 'big'     : 'doom'
        \, 'normal'  : 'standard'
        \, 'small'   : 'thick'
        \, 'mini'    : 'threepoint'
        \, 'compact' : 'twopoint'
        \, 'tiny'    : 'term'
        \, 'bullet'  : 'digital'
        \}

  call args#merge(
        \  obj.default_styles
        \, 'g:figlet_default_styles'
        \, [a:000, 0, 'default_styles']
        \)

  let obj.styles = args#merge(
        \  {}
        \, obj.default_styles
        \, 'g:figlet_styles'
        \, [a:000, 0, 'styles']
        \)

  let obj.figlet_font_dir = args#merge(
        \  s:sfile_path . '/figlet'
        \, 'g:figlet_font_dir'
        \, [a:000, 0, 'font_dir']
        \)

  let obj.figlet_options = args#merge(
        \  ' -d ' . obj.figlet_font_dir
        \, 'g:figlet_options'
        \, [a:000, 0, 'options']
        \)

  func obj.dump_config() dict
    let s  = 'Figlet Config:'
    let s .= "\n" . 'default_styles='  . string(self.default_styles)
    let s .= "\n" . 'styles='          . string(self.styles)
    let s .= "\n" . 'figlet_font_dir=' . string(self.figlet_font_dir)
    let s .= "\n" . 'figlet_options='  . string(self.figlet_options)
    return s
  endfunc

  func! obj.as_s(font, text, ...) dict
    let lopts = {
          \ 'w' : &tw
          \}
    if a:0
      call extend(lopts, a:1)
    endif
    let text = a:text
    if has_key(lopts, 'wide')
      let text = join(split(text, '\zs'), ' ')
      call remove(lopts, 'wide')
    endif
    if has_key(lopts, 'upper')
      let text = substitute(text, '.', '\u&', 'g')
      call remove(lopts, 'upper')
    endif
    if has_key(lopts, 'style')
      let font = self.styles[a:font]
      call remove(lopts, 'style')
    else
      let font = a:font
    endif
    let font = ' -f ' . font
    let lo = ' -' . join(map(items(lopts), 'join(v:val, " ")'), '-') . ' '
    " echom 'figlet ' . self.figlet_options . font . lo . shellescape(text)
    return system('figlet ' . self.figlet_options . font . lo . shellescape(text))
  endfunc

  return obj
endfunction
