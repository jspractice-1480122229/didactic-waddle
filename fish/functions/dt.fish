function dt --description 'Toggle between Laptop and TV display'
    set current (autorandr --current)

    if test "$current" = "BigNlil"
        autorandr --load mobile
        notify-send "Mobile Mode"
    else
        autorandr --load BigNlil
        notify-send "TV Mode"
    end
end
1
