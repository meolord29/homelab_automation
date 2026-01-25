#!/usr/bin/expect -f

# ---------------------------------------------------------
# 1. READ CONFIGURATION
# ---------------------------------------------------------
if {![file exists "config.ini"]} { puts "Error: config.ini not found!"; exit 1 }
set fp [open "config.ini" r]
set file_data [read $fp]
close $fp

foreach line [split $file_data "\n"] {
    if {[string match "#*" $line] || [string match ";*" $line] || [string length $line] == 0} { continue }
    if {[string match "\[*\]" $line]} { continue }
    set idx [string first "=" $line]
    if {$idx > -1} {
        set key [string trim [string range $line 0 [expr $idx - 1]]]
        set val [string trim [string range $line [expr $idx + 1] end]]
        set $key $val
    }
}

# ---------------------------------------------------------
# 2. REACTIVE EXECUTION LOGIC
# ---------------------------------------------------------

# Set timeout to 60 seconds just in case of network lag. 
# If a prompt isn't found in 60s, the script will exit with error.
set timeout 60

puts "\n=== \[1/5\] Connection -> $target_ip ==="
spawn ssh -o StrictHostKeyChecking=no $ssh_user@$target_ip

# --- STEP 0: Initial Login ---
expect {
    "password:" {
        puts "-> Sending SSH Password"
        send "$initial_pass\r"
    }
    timeout { puts "Error: Timed out waiting for SSH login."; exit 1 }
}

# --- STEP 1: Root Password ---
# We use -re (Regex) to catch variations like "current UNIX" or "Create root"
puts "\n=== \[2/5\] Configuring Root Password ==="
expect {
    # Case A: System asks for CURRENT password first (standard Linux behavior)
    -re "current UNIX password:" {
        send "$initial_pass\r"
        expect "new UNIX password:"
        send "$root_new_pass\r"
    }
    # Case B: System asks to CREATE root password immediately (Armbian Wizard)
    -re "Create root password:" {
        send "$root_new_pass\r"
    }
}

# Confirm Root Password (matches "Repeat" or "Retype")
expect -re "(Repeat|Retype)"
send "$root_new_pass\r"

# --- STEP 2: Shell Selection ---
# Matches text ending in "shell" or the bracket option "[1]"
puts "\n=== \[3/5\] Selecting Shell ==="
expect -re "(shell|bash)" 
send "$shell_choice\r"

# --- STEP 3: User Creation ---
puts "\n=== \[4/5\] Creating User Account ==="

# Wait for username prompt
expect -re "(username|Give the name)" 
send "$new_username\r"

# Wait for 1st password prompt
expect -re "(password|new UNIX)" 
send "$new_user_pass\r"

# Wait for confirmation prompt (Repeat/Retype)
expect -re "(Repeat|Retype)" 
send "$new_user_pass\r"

# Wait for Real Name prompt
expect "Real name" 
send "$real_name\r"

# --- STEP 4: Locales ---
puts "\n=== \[5/5\] Configuring Locales ==="

# Armbian asks to set up language based on $LANG. 
# It usually ends with a question mark or colon.
expect -re "(language|locales)"
send "$lang_setup_resp\r"

# Wait for the specific locale selection prompt
# This usually lists options or asks for input.
expect -re "(initial locale|en_US)"
send "$lang_choice\r"

# --- STEP 5: FINISH & EXIT FOR ANSIBLE ---
puts "\n=== Waiting for prompts to finish... ==="

# Wait specifically for the root command prompt (#)
# This confirms the Wizard has fully exited and returned control to the OS.
expect -re "root@.*#" 

puts "-> Wizard complete. Root shell detected. Exiting..."
send "exit\r"
expect eof