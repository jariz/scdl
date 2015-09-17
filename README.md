# scdl
The intelligent SoundCloud downloader. Downloads any url, and tags it automatically.

![](https://i.imgur.com/Y3xXgbH.png)

##Install
```bash
npm install scdl -g
```

**scdl requires either [ffmpeg](https://www.ffmpeg.org/) or [eyed3](http://eyed3.nicfit.net/) to be installed.**  
FFmpeg is the default tag writing driver, eye3d can also be used, but seems to be rather unstable from my own tests.

###ffmpeg
From a real operating system: `apt-get/brew install ffmpeg` should be sufficient.  
From windows: [Good luck](http://www.wikihow.com/Install-FFmpeg-on-Windows)

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
- **url**
- **callback**(error, files)
  - **error**: will contain error object if error occured
  - **files**: array of outputted files
