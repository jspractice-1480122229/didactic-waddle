function mssqlctl -d "Control MS SQL Server"
    if test (count $argv) -ne 1
        echo "Usage: mssqlctl [start|stop|status]"
        echo "Example: mssqlctl start"
        return 1
    end
    
    switch $argv[1]
        case start restart
            echo "Starting MS SQL Server..."
            sudo systemctl restart mssql-server.service
        case stop
            echo "Stopping MS SQL Server..."
            sudo systemctl stop mssql-server.service
        case status
            echo "MS SQL Server status:"
        case '*'
            echo "Error: Unknown command '$argv[1]'"
            echo "Valid commands: start, stop, status"
            return 1
    end
    
    # Always show status after any operation
    systemctl list-units | grep --color mssql
end
