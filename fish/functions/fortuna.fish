# Function for displaying random fortune cookie messages.
function fortuna
    fortune | cowthink -f $(find /usr/share/cowsay/cows -type f | shuf -n 1)
end