function presentation --description 'Toggle screen-blank/DPMS off for presentations (XFCE/X11)'
    set -l state (xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled 2>/dev/null)

    if test "$state" = "false"
        # currently off -> turn back on
        xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s true
        xset s on
        xset +dpms
        echo "presentation mode: OFF (screen blanking restored)"
    else
        xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false
        xset s off
        xset -dpms
        xset s noblank
        echo "presentation mode: ON (screen will not blank/sleep)"
    end
end
