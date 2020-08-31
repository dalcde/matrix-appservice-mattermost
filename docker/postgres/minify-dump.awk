prev != "" && !/^\\\.$/ { print prev; print }
!/^--/ && !/^$/ && !/^COPY/ && prev == "" { print }
prev = ""
/^COPY/ { prev = $0 }
