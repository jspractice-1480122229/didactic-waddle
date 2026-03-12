function fritoobs
    set u (curl -s https://api.github.com/repos/FreeTubeApp/FreeTube/releases | jq -r '.[0].tag_name')
    set l (pacman -Qi freetube-bin | awk '/Version/ {print $3}')
    test "$u" != "$l"; and echo "FreeTube update available → $u (installed $l)"
end
