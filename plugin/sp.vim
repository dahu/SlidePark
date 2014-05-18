let sp = slidepark#asciidocish({'styles' : {'bullet' : 'bubble'}})

command! -bar -nargs=0 SlidePark let lines=getline(1,'$') | enew | call append(0, sp.reset().render(lines).to_l()) | $g/^$/d | 1 | setlocal nolist | nohl
