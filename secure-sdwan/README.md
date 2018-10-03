# Automated Secure SD-WAN Demo

The goal of the demo is to show the automated deployment of a secure SD-WAN using:
 - a media server
 - 2 networks simulating
    * failing WAN 
    * guaranteed network like MPLS
 - 2 simulated branches with Fortigate SDWAN firewalls
 
 ## Scenario
 
Entreprise A wants to organize a live broadcast town-hall meeting. The IT department of Enterprise A must rapidly deploy a media server and ensure proper bandwidth and latency to ensure smooth upload and broadcast.
The SD-WAN policies must be updated to ensure appropriate SD-WAN performance at the time of the broadcast with reversion to the standard SD-WAN policies to prioritize business critical apps at the end of the broadcast.
 
 
 ## Quick start
 
 You must have a Cloudify manager installed and configured.
 
 The easiest is to run : cloudify/manager-on-openstackvm on a configured openstack (mgmt netwrok with floating ips)

 Then upload fortigate images and be sure to point to Ubuntu 16.04 images (input-citycloud.yaml as example)
 
  Then 
  ```bash
 $ cd cloudify-ftnt-sdwan
 $ cfy install -b dcplus dc-plus-wans.yaml -i inputs-citycloud.yaml
 $  openstack router set dc-router --route destination=10.20.20.0/24,gateway=10.40.40.254
 $ cfy install -b antmedia antmedia.yaml -i inputs-citycloud.yaml 
``` 
 ## VLC access from MAC

On a x11 started session:

```
    gsettings set  org.gnome.Vino enabled true
      #   for broken clients like rdp/Macos
     gsettings set  org.gnome.Vino  require-encryption false
     gsettings set  org.gnome.Vino vnc-password Zm9ydGluZXQ=
     gsettings set org.gnome.Vino use-upnp true
     gsettings set org.gnome.Vino notify-on-connect false
     gsettings set org.gnome.Vino prompt-enabled false
     gsettings set org.gnome.Vino authentication-methods  "['vnc']"
```

 ## Streaming
 
 Use OBS and use the following settings:
 https://github.com/ant-media/Ant-Media-Server/wiki/Reduce-Latency-in-RTMP-to-HLS-Streaming
 
 To watch the live stream:
 http://<SERVER_NAME>/LiveApp/streams/<STREAM_ID>.m3u8 HLS
 
 See this https://github.com/ant-media/Ant-Media-Server/wiki/Play-Live-and-VoD-Streams for details
 
 In community edition, MP4 URL will be available in this URL http://<SERVER_NAME>:5080/LiveApp/streams/<STREAM_ID>.mp4

 An embedded player is available here:
 http://<SERVER_NAME>:5080/LiveApp/play.html?name=<STREAM_ID> 

 For demos you might want to broadcast a file with vlc:
 cvlc  -vvv FILE016.MP4 --sout '#transcode{vcodec=h264,scale=Auto,width=1280,height=720,acodec=mp3,ab=128,channels=2,samplerate=44100}:std{access=rtmp,mux=ffmpeg{mux=flv},dst=rtmp://a.rtmp.youtube.com/live2/stream-name}'
src: https://stackoverflow.com/questions/40428837/broadcasting-to-youtube-live-via-rtmp-using-vlc-from-terminal
 
 As the VOD usually buffers the file, network lag is not experienced in the video playback.
 Broadasting and viewing from same pc overloads the bandwidth.
 
 SD-WAN videos on YouTube : 
 https://www.youtube.com/watch?v=CgkbewuLEys  https://www.youtube.com/watch?v=jaNZiFFg-38  https://www.youtube.com/watch?v=SYyCJS-hE5I
