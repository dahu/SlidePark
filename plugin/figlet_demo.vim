let s:local_figlet_font_dir = expand('<sfile>:p:h:h') . '/figlet'
function! FigletDemo(text)
  for f in glob(s:local_figlet_font_dir . '/*.flf', 0, 1)
    echo f
    echo system('figlet -f ' . f . ' ' . shellescape(a:text))
  endfor
endfunction
