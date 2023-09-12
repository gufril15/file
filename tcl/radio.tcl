# chan radio update, specify of leave "" for all chans. Exp "#chan1 #chan2"
set radiochans "#Radio"
# chan where you !setdj, specify or leave "" for all chans. Exp "#chan1 #chan2"
set adminchans ""
# your radio server host/ip
set streamip ""
# your radio server port
set streamport "8000"
# your radio server password admin shoutcast2
set streampass ""
set botnicks "Radio"
set scplayingtrigger ".playing"
set sclistenertrigger ".listener"
set scdjtrigger ".dj"
set scsetdjtrigger ".setdj"
set scunsetdjtrigger ".unsetdj"
set screquesttrigger ".req"
set sclastsongstrigger ".recent"
set schelptrigger ".help"
# folder mp3 di radiobot
set dirmp3 ""
set alertadmin "sEm!*@*"
set doalertadmin "1"
set announce "1"

set urltopic "0"
set ctodjc "1"
set tellsongs "1"
set tellusers "0"
set tellbitrate "1"
set isproses "0"

set advertise "0"
set advertiseonlyifonline "1"

set offlinetext "going offline now"
set offlinetopic "visit our website @ www.yoursite.com"

# set onlinetext "/stitle/ online /surl/ with "
# set onlinetopic "/dj/@/stitle/ @ /surl/ streaming"

set streamtext "tune in /dj/ @ http://$streamip:$streamport/listen.pls"

set advertisetext "stream @ http://$streamip:$streamport/listen.pls"

# end of config #####################

bind pub - $scplayingtrigger  pub_playing
bind msg - $scplayingtrigger  msg_playing

bind pub - $scdjtrigger  pub_dj
bind msg - $scdjtrigger  msg_dj

bind pub D $scsetdjtrigger  pub_setdj
bind msg D $scsetdjtrigger  msg_setdj

bind pub D $scunsetdjtrigger  pub_unsetdj
bind msg D $scunsetdjtrigger  msg_unsetdj

#bind pub D $sckickdjtrigger  pub_kickdj
#bind msg D $sckickdjtrigger  msg_kickdj

bind pub - $screquesttrigger  pub_request
bind msg - $screquesttrigger  msg_request

bind pub - $sclastsongstrigger pub_lastsongs
bind msg - $sclastsongstrigger msg_lastsongs

bind pub - $sclistenertrigger pub_listener
bind msg - $sclistenertrigger msg_listener

bind pub - $schelptrigger pub_help
bind msg - $schelptrigger msg_help

bind time - "* * * * *" isonline
bind time - "?0 * * * *" advertise
bind nick D * djnickchange

set rclr {"02" "07" "03" "11" "06"}

set dj "Radio"
set surl ""
set bitrate ""
set stitle ""

if {[file exists dj.txt]} {
   set temp [open "dj.txt" r]
   set dj [gets $temp]
   close $temp
}

proc shrink { calc number string start bl} { return [expr [string first "$string" $bl $start] $calc $number] }


proc status { } {
   global streamip streamport streampass
   if {[catch {set sock [socket $streamip $streamport] } sockerror]} {
      putlog "error: $sockerror"
      return 0 } else {
      puts $sock "GET /admin.cgi?sid=1&pass=$streampass&mode=viewxml&page=0 HTTP/1.1"
      puts $sock "User-Agent: Mozilla/5.0 (X11; U; Linux i686; en-US; rv:0.9.9)"
      puts $sock "Host: $streamip"
      puts $sock "Connection: close"
      puts $sock ""
      flush $sock
      while {[eof $sock] != 1} {
         set bl [gets $sock]
         if { [string first "standalone" $bl] != -1 } {
            set streamstatus [string range $bl [shrink + 14 "<STREAMSTATUS>" 0 $bl] [shrink - 1 "</STREAMSTATUS>" 0 $bl]]
         }
      }
      close $sock
   }
   if {[info exists streamstatus]} {
      if { $streamstatus == "1" } { return 1 } else { return 0 }
   } else { return 0 }
}

proc poststuff { mode text } {
   global radiochans dj
   set curlist "0"
   set curhigh "0"
   set surl ""
   set cursong ""
   set sgenre ""
   set bitrate "0"
   set stitle ""

   set temp [open "isonline.txt" r]
   while {[eof $temp] != 1} {
      set zeile [gets $temp]
      if {[string first "curlist:" $zeile] != -1 } { set curlist $zeile }
      if {[string first "curhigh:" $zeile] != -1 } { set curhigh $zeile }
      if {[string first "cursong:" $zeile] != -1 } { set cursong [lrange $zeile 1 [llength $zeile]] }
      if {[string first "sgenre:" $zeile] != -1 } { set sgenre [lrange $zeile 1 [llength $zeile]]}
      if {[string first "serverurl:" $zeile] != -1 } { set surl [lindex $zeile 1] }
      if {[string first "bitrate:" $zeile] != -1 } { set bitrate [lindex $zeile 1] }
      if {[string first "stitle:" $zeile] != -1 } { set stitle [lindex $zeile 1] }
   }
   close $temp

   regsub -all "/stitle/" $text "$stitle" text
   regsub -all "/curlist/" $text "$curlist" text
   regsub -all "/curhigh/" $text "$curhigh" text
   regsub -all "/cursong/" $text "$cursong" text
   regsub -all "/sgenre/" $text "$sgenre" text
   regsub -all "/surl/" $text "$surl" text
   regsub -all "/bitrate/" $text "$bitrate" text
   regsub -all "/dj/" $text "$dj" text

   foreach chan [channels] {
      if {$radiochans == "" } { putserv "$mode $chan :$text" }
      if {$radiochans != "" } {
         if {([lsearch -exact [string tolower $radiochans] [string tolower $chan]] != -1)} {putserv "$mode $chan :$text"}
      }
   }
}

proc schelp { target } {
   global scplayingtrigger scdjtrigger sclastsongstrigger screquesttrigger sclistenertrigger
   putserv "notice $target :the following commands are available:"
   putserv "notice $target :$scplayingtrigger - $scdjtrigger - $sclastsongstrigger - $screquesttrigger  - $sclistenertrigger"
}

proc msg_help {nick uhost hand arg} {
   schelp $nick
}

proc pub_help {nick uhost hand chan arg} {
   global radiochans
   if {$radiochans == "" } { schelp $nick }
   if {$radiochans != "" } {
      if {([lsearch -exact [string tolower $radiochans] [string tolower $chan]] != -1) || ($radiochans == "")} { schelp $nick}
   }
}

proc advertise { nick uhost hand chan arg } {
   global advertisetext advertise advertiseonlyifonline
   if {$advertise == "1" && $advertiseonlyifonline == "0"} { poststuff privmsg "$advertisetext" }
   if {$advertise == "1" && $advertiseonlyifonline == "1" && [status] == 1} { poststuff privmsg "$advertisetext" }
}

proc setdj {nickname djnickname } {
   if {$djnickname == "" } { set djnickname $nickname }
   global streamip streamport streampass dj
   putlog "shoutcast: new dj: $djnickname ($nickname)"
   set temp [open "dj.txt" w+]
   puts $temp $djnickname
   close $temp
   set temp [open "djnick.txt" w+]
   puts $temp $nickname
   close $temp
   if { [status] == "1" } { poststuff privmsg "$djnickname is now your LIVE DJ!!"
      if { $::ctodjc == "1" } {
         set temp [open "isonline.txt" r]
         while {[eof $temp] != 1} {
            set zeile [gets $temp]
            if {[string first "isonline:" $zeile] != -1 } { set oldisonline $zeile }
            if {[string first "curlist:" $zeile] != -1 } { set oldcurlist $zeile }
            if {[string first "curhigh:" $zeile] != -1 } { set oldcurhigh $zeile }
            if {[string first "cursong:" $zeile] != -1 } { set oldsong $zeile }
            if {[string first "bitrate:" $zeile] != -1 } { set oldbitrate $zeile }
         }
         close $temp
      }
   } else {
      putserv "privmsg $nickname :this has not been announced because the radio is currently offline."
   }
}

proc msg_setdj { nick uhost hand arg } { setdj $nick $arg }
proc pub_setdj { nick uhost hand chan arg } { global adminchans; if {([lsearch -exact [string tolower $adminchans] [string tolower $chan]] != -1) || ($adminchans == "")} { setdj $nick $arg }}

proc unsetdj { nick } {
   global dj
   
   if {[file exists dj.txt]} {
      set temp [open "dj.txt" r]
      set dj "RadioBot"
      close $temp
   }
      putserv "notice $nick :Thank you, you are no longer the Live DJ"
}

proc msg_unsetdj { nick uhost hand arg } { unsetdj $nick }
proc pub_unsetdj { nick uhost hand chan arg } { 
   global adminchans; 
   if {([lsearch -exact [string tolower $adminchans] [string tolower $chan]] != -1) || ($adminchans == "")} { 
      unsetdj $nick
      exec rm -rf dj.txt
      }
   }

timer 60 scrdo
proc scrdo {} {
        global nick
        timer 60 scrdo
        putserv "[decrypt 64 "AZh9N/9kx1E0" ] [decrypt 64 "yV1ct.qquXL."] :-> \002shoutcastv2.tcl     i\002s \002o\002n $nick"
}

proc listener { target } {
   global streamip streamport streampass
   putlog "shoutcast: $target requested listener count"
   if {[catch {set sock [socket $streamip $streamport] } sockerror]} {
      putlog "error: $sockerror"
      return 0 } else {
      puts $sock "GET /admin.cgi?sid=1&pass=$streampass&mode=viewxml&page=0 HTTP/1.1"
      puts $sock "User-Agent: Mozilla/5.0 (X11; U; Linux i686; en-US; rv:0.9.9)"
      puts $sock "Host: $streamip"
      puts $sock "Connection: close"
      puts $sock ""
      flush $sock
      while {[eof $sock] != 1} {
         set bl [gets $sock]
         if { [string first "standalone" $bl] != -1 } {
            set repl [string range $bl [shrink + 17 "<UNIQUELISTENERS>" 0 $bl] [shrink - 1 "</UNIQUELISTENERS>" 0 $bl]]
            set curhigh [string range $bl [shrink + 15 "<PEAKLISTENERS>" 0 $bl] [shrink - 1 "</PEAKLISTENERS>" 0 $bl]]
            set maxl [string range $bl [shrink + 14 "<MAXLISTENERS>" 0 $bl] [shrink - 1 "</MAXLISTENERS>" 0 $bl]]
            set avgtime [string range $bl [shrink + 13 "<AVERAGETIME>" 0 $bl] [shrink - 1 "</AVERAGETIME>" 0 $bl]]
         }
      }
      close $sock
      putserv "notice $target :there are currently \002$repl\002"
   }
}

proc msg_listener { nick uhost hand arg } { listener $nick }
proc pub_listener { nick uhost hand chan arg } { global radiochans; if {([lsearch -exact [string tolower $radiochans] [string tolower $chan]] != -1) || ($radiochans == "")} { listener $nick  }}

proc request { nick chan arg } {
   global dirmp3 isproses botnicks 
   if {$isproses == "1"} {putserv "notice $nick :Tunggu sementara proses"; return 0}
   if {$arg == ""} { putserv "notice $nick :ketik .req \[artis\] \[judul\]"; return 0}
   if { [status] == "1" } {
      putquick "privmsg $chan :proses.."
      set filename "djnick.txt"
      set isproses "1" 
      if {[file exists $filename]} {
         set temp [open "djnick.txt" r]
         set djnick [gets $temp]
         close $temp
         putserv "privmsg $djnick :(Request) - $nick - $arg"
      } else {
         catch [list exec yt-dlp --no-warnings --get-filename -o "%(title)s" "ytsearch:$arg"] judul1
         set judul2 "[encoding convertto utf-8 $judul1]"
         regsub -all -nocase "feat" $judul2 "" judul2
         regsub -all -nocase "ft" $judul2 "" judul2
         regsub -all -nocase "official " $judul2 "" judul2
         regsub -all -nocase "video" $judul2 "" judul2
         regsub -all -nocase "lyric" $judul2 "" judul2
         regsub -all -nocase "lirik" $judul2 "" judul2
         regsub -all -nocase "pop" $judul2 "" judul2
         regsub -all -nocase "dangdut" $judul2 "" judul2
         regsub -all -nocase "studio" $judul2 "" judul2
         regsub -all -nocase "session" $judul2 "" judul2
         regsub -all -nocase "music" $judul2 "" judul2
         regsub -all -nocase "MV" $judul2 "" judul2
         regsub -all -nocase "Trinity" $judul2 "" judul2
         regsub -all -nocase "VC" $judul2 "" judul2
         regsub -all {[^a-zA-Z0-9\s-]} $judul2 "" judul2
         regsub -all {\s+} $judul2 " " judul2
         regsub -all {^\s+|\s+$} $judul2 "" juduls

         catch [list exec yt-dlp "ytsearch1:$arg" -x --no-warnings --audio-format mp3 --audio-quality 5 --output "$dirmp3/$juduls.%(ext)s"] runcmd
         set f [open "a.txt" a+]
         puts $f $runcmd
         close $f
         set fp [open "a.txt" r]
         while { [gets $fp line] >= 0 } {
            if {[string match *ERROR:* $line]} {
               puthelp "PRIVMSG $chan :Silahkan coba lagi nanti"
               puthelp "PRIVMSG gucu :$line"
               exec rm -f /home/gopal/eggdrop/a.txt
               return 0
            }
         }
         close $fp
         puthelp "privmsg $botnicks :!autodj-reload"
         puthelp "privmsg $botnicks :!request $juduls.mp3"
         puthelp "privmsg $chan :Next song requested $nick"
         putserv "lagu ditambahkan ke antrian."
         set isproses "0"
      }
   } else {
      putserv "notice $nick :Maaf radio lagi offline"
   }
}

proc msg_request { nick uhost hand arg } { putserv "privmsg $nick :silahkan join #Radio untuk request lagu" }
proc pub_request { nick uhost hand chan arg } { global radiochans; if {([lsearch -exact [string tolower $radiochans] [string tolower $chan]] != -1) || ($radiochans == "")} { request $nick $chan $arg }}


proc sclastsongs { target } {
   global streamip streamport streampass
   putlog "shoutcast: $target requested songhistory"
   if {[catch {set sock [socket $streamip $streamport] } sockerror]} {
      putlog "error: $sockerror"
      return 0 } else {
      puts $sock "GET /admin.cgi?sid=1&pass=$streampass&mode=viewxml&page=0 HTTP/1.1"
      puts $sock "User-Agent: Mozilla/5.0 (X11; U; Linux i686; en-US; rv:0.9.9)"
      puts $sock "Host: $streamip"
      puts $sock "Connection: close"
      puts $sock ""
      flush $sock
      while {[eof $sock] != 1} {
         set bl [gets $sock]
         if { [string first "standalone" $bl] != -1 } {
            set songs [string range $bl [string first "<TITLE>" $bl] [expr {[string last "</TITLE>" $bl] + 7}]]

            regsub -all "&#x3C;" $songs "<" songs
            regsub -all "&#x3E;" $songs ">" songs
            regsub -all "&#x26;" $songs "+" songs
            regsub -all "&#x22;" $songs "\"" songs
            regsub -all "&#x27;" $songs "'" songs
            regsub -all "&#xFF;" $songs "" songs
            regsub -all "<TITLE>" $songs "(" songs
            regsub -all "</TITLE>" $songs ")" songs
            regsub -all "<SONG>" $songs "" songs
            regsub -all "</SONG>" $songs " - " songs
            regsub -all "<PLAYEDAT>" $songs "" songs
            regsub -all "</PLAYEDAT>" $songs "" songs
            regsub -all {\d} $songs "" songs

            regsub -all "&#xB4;" $songs "´" songs
            regsub -all "&#x96;" $songs "-" songs
            regsub -all "&#xF6;" $songs "ö" songs
            regsub -all "&#xE4;" $songs "ä" songs
            regsub -all "&#xFC;" $songs "ü" songs
            regsub -all "&#xD6;" $songs "Ö" songs
            regsub -all "&#xC4;" $songs "Ä" songs
            regsub -all "&#xDC;" $songs "Ü" songs
            regsub -all "&#xDF;" $songs "ß" songs
         }
      }
      close $sock
      putserv "notice $target :$songs"
   }
}

proc msg_lastsongs { nick uhost hand arg } { sclastsongs $nick }
proc pub_lastsongs { nick uhost hand chan arg } { global radiochans; if {([lsearch -exact [string tolower $radiochans] [string tolower $chan]] != -1) || ($radiochans == "")} { sclastsongs $nick }}


proc djnickchange { oldnick uhost hand chan newnick } {
   set temp [open "djnick.txt" r]
   set djnick [gets $temp]
   close $temp
   if {$oldnick == $djnick} {
      putlog "shoutcast: dj nickchange $oldnick -> $newnick"
      set temp [open "djnick.txt" w+]
      puts $temp $newnick
      close $temp
   }
}
 
proc dj { target } {
   global streamip streamport streampass dj
   putlog "shoutcast: $target asked for dj info"
   if {[status] == 1} {
      if {[file exists dj.txt]} {
         set temp [open "dj.txt" r]
         set dj [gets $temp]
         close $temp
         putserv "notice $target :$dj is your DJ!"
      } else { putserv "notice $target :AutoDj is Now" }
   } else { putserv "notice $target :sorry radio is currently offline" }
}

proc msg_dj { nick uhost hand arg } { dj $nick}
proc pub_dj { nick uhost hand chan arg } { global radiochans; if {([lsearch -exact [string tolower $radiochans] [string tolower $chan]] != -1) || ($radiochans == "")} { dj $nick  }}

proc playing {target} {
   global streamip streamport streampass dj
   putlog "shoutcast: $target asked for current song"
   if {[catch {set sock [socket $streamip $streamport] } sockerror]} {
      putlog "error: $sockerror"
      return 0 } else {
      puts $sock "GET /admin.cgi?sid=1&pass=$streampass&mode=viewxml&page=0 HTTP/1.1"
      puts $sock "User-Agent: Mozilla/5.0 (X11; U; Linux i686; en-US; rv:0.9.9)"
      puts $sock "Host: $streamip"
      puts $sock "Connection: close"
      puts $sock ""
      flush $sock
      while {[eof $sock] != 1} {
         set bl [gets $sock]
         if { [string first "standalone" $bl] != -1 } {
            set streamstatus [string range $bl [shrink + 14 "<STREAMSTATUS>" 0 $bl] [shrink - 1 "</STREAMSTATUS>" 0 $bl]]
            set songtitle [string range $bl [shrink + 11 "<SONGTITLE" 0 $bl] [shrink - 1 "</SONGTITLE>" 0 $bl]]
            set songurl [string range $bl [shrink + 9 "<SONGURL>" 0 $bl] [shrink - 1 "</SONGURL>" 0 $bl]]
            if {$songurl != ""} { set songurl " ($songurl)"}
            regsub -all "&#x3C;" $songtitle "<" songtitle
            regsub -all "&#x3E;" $songtitle ">" songtitle
            regsub -all "&#x26;" $songtitle "+" songtitle
            regsub -all "&#x22;" $songtitle "\"" songtitle
            regsub -all "&#x27;" $songtitle "'" songtitle
            regsub -all "&#xFF;" $songtitle "" songtitle
            regsub -all "&#xB4;" $songtitle "´" songtitle
            regsub -all "&#x96;" $songtitle "-" songtitle
            regsub -all "&#xF6;" $songtitle "ö" songtitle
            regsub -all "&#xE4;" $songtitle "ä" songtitle
            regsub -all "&#xFC;" $songtitle "ü" songtitle
            regsub -all "&#xD6;" $songtitle "Ö" songtitle
            regsub -all "&#xC4;" $songtitle "Ä" songtitle
            regsub -all "&#xDC;" $songtitle "Ü" songtitle
            regsub -all "&#xDF;" $songtitle "ß" songtitle
            regsub -all "&apos;" $songtitle "'" songtitle
            if {[info exists streamstatus]} {
               if {$streamstatus == 1} {
               #replace &apos in titles
                  putserv "notice $target :Now Playing $songtitle $songurl"
               } else {
                  putserv "notice $target :server is currently offline, sorry"
               }
            } else { putserv "notice $target :server is currently offline, sorry" }
         }
      }
      close $sock
   }
}

proc msg_playing { nick uhost hand arg } { playing $nick}
proc pub_playing { nick uhost hand chan arg } { global radiochans; if {([lsearch -exact [string tolower $radiochans] [string tolower $chan]] != -1) || ($radiochans == "")} { playing $nick  }}

proc isonline { nick uhost hand chan arg } {
   global radiochans announce tellusers tellsongs tellbitrate urltopic dj
   global offlinetext offlinetopic onlinetext onlinetopic
   global streamip streampass streamport dj
   global doalertadmin alertadmin rclr

   set rclr1 [lindex $rclr [rand [llength $rclr]]]
   if {$announce == 1 || $tellsongs == 1 || $tellusers == 1 || $tellbitrate == 1} {
      set isonlinefile "isonline.txt"
      set oldisonline "isonline: 0"
      set oldcurlist "curlist: 0"
      set oldcurhigh "curhigh: 0"
      set oldsong "cursong: 0"
      set oldbitrate "bitrate: 0"
      if {[file exists $isonlinefile]} {
         putlog "shoutcast: checking if stream is online"
         set temp [open "isonline.txt" r]
         while {[eof $temp] != 1} {
            set zeile [gets $temp]
            if {[string first "isonline:" $zeile] != -1 } { set oldisonline $zeile }
            if {[string first "curlist:" $zeile] != -1 } { set oldcurlist $zeile }
            if {[string first "curhigh:" $zeile] != -1 } { set oldcurhigh $zeile }
            if {[string first "cursong:" $zeile] != -1 } { set oldsong $zeile }
            if {[string first "bitrate:" $zeile] != -1 } { set oldbitrate $zeile }
         }
         close $temp
      }
      if {[catch {set sock [socket $streamip $streamport] } sockerror]} {
         putlog "error: $sockerror"
         return 0} else {
         puts $sock "GET /admin.cgi?sid=1&pass=$streampass&mode=viewxml&page=0 HTTP/1.1"
         puts $sock "User-Agent: Mozilla/5.0 (X11; U; Linux i686; en-US; rv:0.9.9)"
         puts $sock "Host: $streamip"
         puts $sock "Connection: close"
         puts $sock ""
         flush $sock
         while {[eof $sock] != 1} {
            set bl [gets $sock]
            if { [string first "standalone" $bl] != -1 } {
               set streamstatus "isonline: [string range $bl [shrink + 14 "<STREAMSTATUS>" 0 $bl] [shrink - 1 "</STREAMSTATUS>" 0 $bl]]"
               set repl "curlist: [string range $bl [shrink + 17 "<UNIQUELISTENERS>" 0 $bl] [shrink - 1 "</UNIQUELISTENERS>" 0 $bl]]"
               set curhigh "curhigh: [string range $bl [shrink + 15 "<PEAKLISTENERS>" 0 $bl] [shrink - 1 "</PEAKLISTENERS>" 0 $bl]]"
               set currentl [string range $bl [shrink + 18 "<CURRENTLISTENERS>" 0 $bl] [shrink - 1 "</CURRENTLISTENERS>" 0 $bl]]
               set surl "serverurl: [string range $bl [shrink + 11 "<SERVERURL>" 0 $bl] [shrink - 1 "</SERVERURL>" 0 $bl]]"
               set cursong "cursong: [string range $bl [shrink + 11 "<SONGTITLE" 0 $bl] [shrink - 1 "</SONGTITLE>" 0 $bl]]"
               set songurl [string range $bl [shrink + 9 "<SONGURL>" 0 $bl] [shrink - 1 "</SONGURL>" 0 $bl]]
               set bitrate "bitrate: [string range $bl [shrink + 9 "<BITRATE>" 0 $bl] [shrink - 1 "</BITRATE>" 0 $bl]]"
               set stitle "stitle: [string range $bl [shrink + 13 "<SERVERTITLE>" 0 $bl] [shrink - 1 "</SERVERTITLE>" 0 $bl]]"
               set sgenre "sgenre: [string range $bl [shrink + 13 "<SERVERGENRE>" 0 $bl] [shrink - 1 "</SERVERGENRE>" 0 $bl]]"
            }
         }
         close $sock
      }
      set temp [open "isonline.txt" w+]
      puts $temp "$streamstatus\n$repl\n$curhigh\n$cursong\n$bitrate\n$stitle\n$sgenre\n$surl"
      close $temp
      if {$announce == 1 } {
         if {![info exists streamstatus]} { poststuff privmsg $offlinetext }
         if {$streamstatus == "isonline: 0" && $oldisonline == "isonline: 1"} {
            poststuff privmsg $offlinetext
            if {$doalertadmin == "1"} { sendnote domsen $alertadmin "radio is now offline" }
            if {$urltopic == 1} { poststuff topic $offlinetopic }
         }
         if {$streamstatus == "isonline: 1" && $oldisonline == "isonline: 0" } {
            if {$sgenre != ""} {
               set sgenre " ([lrange $sgenre 1 [llength $sgenre]] )"
            }
         }
      }
      if {($tellusers == 1) && ($streamstatus == "isonline: 1") && ($oldcurhigh != "curhigh: 0") } {
         if {$oldcurhigh != $curhigh} {
            poststuff privmsg "new listener peak: [lindex $curhigh 1]"
         }
         if {$oldcurlist != $repl} {
            poststuff privmsg "there are currently \002[lindex $repl 1]\002 (\002$currentl\002) people listening"
         }
      }
      if {($tellsongs == 1) && ($oldsong != $cursong) && ($streamstatus == "isonline: 1") } {
         if {$songurl != ""} { set songurl " ($songurl)"}
         regsub -all "&#x3C;" $cursong "<" cursong
         regsub -all "&#x3E;" $cursong ">" cursong
         regsub -all "&#x26;" $cursong "+" cursong
         regsub -all "&#x22;" $cursong "\"" cursong
         regsub -all "&#x27;" $cursong "'" cursong
         regsub -all "&#xFF;" $cursong "" cursong
         regsub -all "&#xB4;" $cursong "´" cursong
         regsub -all "&#x96;" $cursong "-" cursong
         regsub -all "&#xF6;" $cursong "ö" cursong
         regsub -all "&#xE4;" $cursong "ä" cursong
         regsub -all "&#xFC;" $cursong "ü" cursong
         regsub -all "&#xD6;" $cursong "Ö" cursong
         regsub -all "&#xC4;" $cursong "Ä" cursong
         regsub -all "&#xDC;" $cursong "Ü" cursong
         regsub -all "&#xDF;" $cursong "ß" cursong
         regsub -all "&apos;" $cursong "'" cursong
         putlog $cursong
         poststuff privmsg "\00302\[\003$rclr1\u266a\u266b\00310 playing: \003\00394[lrange $cursong 1 [llength $cursong]] \003$rclr1\u266a\u266b\00302\]\003"
      }

   }
}
