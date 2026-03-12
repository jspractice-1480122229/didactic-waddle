#!/usr/bin/env fish
function nyope --wraps='podman container rm $(podman ps -aq)' --description 'alias nyope=podman container rm $(podman ps -aq)'
  podman container rm $(podman ps -aq) $argv
end
