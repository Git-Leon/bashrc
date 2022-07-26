* The source code for this kill script can be found [here]()
* The source code for the alias-initialization can be found [here]()

* The following bash script, (`kill-port.sh`) successfully kills a port when called.
* It is advised that you create an alias for this shell script
    * `alias kill-port=$(PWD)/kill-port.sh`
* Creating an alias will enable the expression below in the terminal
    * `kill-port 8080`

```bash
#!/bin/bash
if [ "$1" ]
  then
    portNumbers=$(netstat -a -n -b -o | grep $1 | sed -e "s/[[:space:]]\+/ /g" | cut -d ' ' -f6)        
    { #try 
        for portNumber in $portNumbers; do
          taskkill /PID /F "$portNumber" 2>/dev/null
        done 
    } || { # catch
        for portNumber in $portNumbers; do
          taskkill //F //PID "$portNumber"
        done 
    }
fi
```

* Why is there a try / catch?
    * The _try_ block is an attempt to kill the specified port in non-gitbash environments.
    * The _catch_ block transliterates the _try_ block to a cygwin expression for the gitbash terminal
    * This allows the script to be ran in any bash or cygwin environment