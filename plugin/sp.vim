" let s:sp = slidepark#asciidocish({'styles' : {'bullet' : 'bubble'}})
let s:sp = slidepark#asciidocish({})

" Create a <presentation>.slideride directory filled with
" <presentation>_<num>.slide files
function! SlidePark(...)
  let arg = a:0 ? a:1 : ''
  let arg = empty(arg) ? expand('%:t') : arg
  let slide_name = substitute(arg, '\.slidepark$', '', '')
  let slide_ride = slide_name . '.slideride'
  let tmpdir = tempname()
  call mkdir(tmpdir)
  exe 'cd ' . tmpdir
  call mkdir(slide_ride)
  exe 'cd ' . slide_ride
  let slide_ride = getcwd()
  let lines = getline(1, '$')
  let slide_lines = s:sp.reset().render(lines).to_l()
  let slides = [[]]
  let current = slides[0]
  for l in slide_lines
    if l == '----newpage----'
      call add(slides, [])
      let current = slides[-1]
      continue
    endif
    call add(current, l)
  endfor

  let slide_number = 1
  for s in slides
    call writefile(s, slide_name . printf("_%03d", slide_number) . '.slide')
    let slide_number += 1
  endfor
  call SlideRide(slide_ride)
endfunction

function! SlideRideController()
  setlocal nolist
  nohl
  nnoremap <up>    :bprev<cr>
  nnoremap <left>  :bprev<cr>
  nnoremap <down>  :bnext<cr>
  nnoremap <right> :bnext<cr>
endfunction

" Open and show a <presentation>.slideride directory
function! SlideRide(slide_ride)
  let slide_ride = a:slide_ride
  let slide_name = fnamemodify(slide_ride, ':t:r')
  exe 'cd ' . slide_ride
  for f in glob('*.slide', 0, 1)
    silent exe 'edit ' . f
  endfor
  exe 'buffer ' . slide_name . '_001.slide'
  call SlideRideController()
endfunction

command! -bar -nargs=? SlidePark call SlidePark(<q-args>)

command! -bar -nargs=0 SlideView let lines=getline(1,'$') | enew | call append(0, <SID>sp.reset().render(lines).to_l()) | $g/^$/d | 1 | setlocal nolist | nohl
