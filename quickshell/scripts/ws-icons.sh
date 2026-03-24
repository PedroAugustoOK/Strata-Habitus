#!/bin/sh
hyprctl clients -j | awk '
/"workspace"/ { getws=1; next }
getws && /"id"/ { match($0, /[0-9]+/); wid=substr($0, RSTART, RLENGTH); getws=0; next }
/"class":/ { match($0, /"class": *"([^"]*)"/, m); c=m[1];
  if (!(wid in ws)) { ws[wid]=c }
}
END {
  map["kitty"]="󰄛"
  map["chromium"]="󰊯"
  map["chromium-browser"]="󰊯"
  map["firefox"]="󰈹"
  map["nautilus"]="󰉋"
  map["org.gnome.Nautilus"]="󰉋"
  map["pavucontrol"]="󰕾"
  map["blueman-manager"]="󰂯"
  map["discord"]="󰙯"
  map["spotify"]="󰓇"
  map["steam"]="󰓓"
  map["vlc"]="󰕼"
  map["mpv"]="󰐹"
  map["code"]="󰨞"
  map["telegram"]=""
  first=1
  for (w in ws) {
    c = ws[w]
    if (c in map) icon = map[c]
    else if (c != "") icon = toupper(substr(c,1,1))
    else icon = "?"
    if (!first) printf "|"
    printf "%s:%s", w, icon
    first=0
  }
  printf "\n"
}
' 2>/dev/null
