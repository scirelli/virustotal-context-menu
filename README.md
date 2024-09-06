# Virustotal Context Menu
Just a one off script to add a virustotal scan as a context menu item in the Cinnamon desktop.

## Use
Get your API key from https://www.virustotal.com. Requires you to have an account.  
Add a environment variable in your `.bashrc`
```
export VIRUSTOTAL_API_KEY=<Your key>
```

### Nemo
You will need to create a file `~/.vtapikey` which contains your VirusTotal api key. Make sure the file is read only for your user.

Symlink the files in `./nemo/scripts/*` and `./nemo/actions/*` to your
```
~/.local/share/nemo/scripts
~/.local/share/nemo/actions
```
Enable the `Virus Scan File` action in the nemo `Edit -> Plugins` menu.  
If you need logs, they are created at `/tmp/nemo_virustotal_scan.log`

## References
* https://github.com/linuxmint/nemo/blob/master/files/usr/share/nemo/actions/sample.nemo_action
