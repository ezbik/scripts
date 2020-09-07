
## Watson log wrapper


This wrapper is designed to accept `watson log` on stdin and make it more cool & detailed:

Sample usage:

           `~/bin/watson log -j  | python3 ~/bin/watson_log.py`

   where

  ` ~/bin/watson`            orig watson script

  ` ~/bin/watson_log.py`     this script.

   Output:

```
 2020-09-03, from 15:40 to 16:40, spent 1:00:00 for customer : XXX, on [cde73c79] upgrade server
 2020-09-05, from 01:40 to 03:10, spent 1:30:00 for customer : YYY, on [9ec97d69] mail sync
 2020-09-05, from 23:22 to 23:52, spent 0:30:00 for customer : YYY, on [57cc6dba] sync to gmail
 TOTAL 3:00:00
```

 You can also create a bash function to overwrite `watson log`

```
watson () 
{ 
    case $1 in 
        log)
            ~/bin/watson $@ -j | python3 ~/bin/watson_log.py
        ;;
        *)
            ~/bin/watson $@
        ;;
    esac
}
```

