# scdl
The intelligent SoundCloud downloader. Downloads any url, and tags it automatically.

![](https://i.imgur.com/pXpfrEu.png)

##Install  

```bash
npm install scdl -g
```

**scdl requires either [ffmpeg](https://www.ffmpeg.org/) or [eyed3](http://eyed3.nicfit.net/) to be installed.**  
FFmpeg is the default tag writing driver, eye3d can also be used, but seems to be rather unstable from my own tests.

###ffmpeg  

Linux (debian): `apt-get install ffmpeg`  
OSX: `brew install ffmpeg` (if you haven't already, get [homebrew](http://brew.sh))    
Windows: `choco install ffmpeg` (if you haven't already, get [chocolatey](https://chocolatey.org/))   

###eyed3
Simply install it trough pip with
```bash
sudo pip install eyed3
```
or optionally on osx (doesn't require sudo)
```bash
brew install eyed3
```

##API
If you want to use SCDL from your own app, you can!  
Install scdl as a local dependency, `var scdl = require('scdl')` and you're good to go

####.url(url, callback)  
- **url** SoundCloud URL (playlist, profile, individual track, whatever)
- **callback**(error, files) Callback that gets called when everything has been downloaded & tagged.  
  - **error**: will contain error object if error occured
  - **files**: array of outputted files

####.on(event, callback)  
- **event**: Any of the following: 'start', 'progress', 'end'.  
- **callback** Callback function, every call except 'progress' will have the filename as the 1st argument.  
  'progress' returns the percentage and as 2nd argument the filename  
