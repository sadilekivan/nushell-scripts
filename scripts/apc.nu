# Avahi promp connection
#   These commands allow a quick prompt and connection for targets that advertise it's _ssh._tcp service

def avahi_browse_prompt [
	service_type: string,
	interface: string = ".+"
] {
	def parse [] {
		$in | split row "\n" | where ($it | str starts-with "=") | split column ";" | reject column10 | rename state interface protocol name type domain hostname ip port | where ($it.interface =~ $interface)
	}
	def all_targets [] {
		log_info "Checking avahi cache"
		let cached_targets = (avahi-browse --parsable --no-db-lookup --resolve --cache $service_type | parse)
		if not ($cached_targets | is-empty) {
			# TODO I should always scan too, unless I remember the last host and add a flag to be able to quickly reconnect
			$cached_targets
		} else {
			log_info "Scanning network"
			let availible_targets = (avahi-browse --parsable --no-db-lookup --resolve --terminate $service_type | parse)
			if not ($availible_targets | is-empty) {
				$availible_targets
			} else {
				log_error "No devices found"
				[]
			}
		}
	}
	def choose_target [] {
		let targets = $in
		if ($targets | length) > 1 {
			echo $targets
			let id = (input "Please choose a target [#]: " | into int)
			$targets | get $id
		} else {
			$targets | get 0
		}
	}

	let targets = all_targets
	 
	if not ($targets | is-empty) {
		$targets | choose_target
	} else {
		{}
	}
}

def load_identity [] {
	let identity_file = $"~/.ssh/($env.target.hostname | split row "." | get 0)"
	if ($identity_file | path exists) {
		ssh-add $identity_file
	} else {
		log_warn $"($identity_file) key not found"
	}
}

export def apc [
] {
	help apc
}

def ssh_arguments [] {
	"-o \"LogLevel ERROR\" -o \"StrictHostKeyChecking no\" -o \"UserKnownHostsFile /dev/null\" -o \"ForwardAgent yes\" -o \"ControlPath ~/.ssh/controlmasters/%r@%h:%p\" -o \"ControlMaster auto\""
}

# ssh wrapper for apc targets
export def-env "apc shell" [
		command: string = ""			#Command to execute on target
		--user (-u): string = "root"	#Username to log in as
	] {
	let-env target = avahi_browse_prompt _ssh._tcp
	if not ($env.target | is-empty) {
		load_identity
		nu -c $"ssh (ssh_arguments) ($user)@($env.target.ip) -p ($env.target.port) ($command)"
	}
}

# rsync wrapper for apc targets
export def-env "apc transfer" [
	source: string					#Source file or path
	destination: string				#Destination file or path
	--user (-u): string = "root"	#Username to log in as
	--recursive (-r): bool 			#Recurse into directories
	--verbose (-v): bool 			#Increase verbosity
	--compress (-z): bool			#Compress file data during the transfer
] {
	let-env target = avahi_browse_prompt _ssh._tcp
	if not ($env.target | is-empty) {
		load_identity
		# TODO I should do a check for ":" to be only in one and then prefix the ip there
		def ip_assignment [] {str replace ":" $"($user)@($env.target.ip):"}
		let source = ($source | ip_assignment)
		let destination = ($destination | ip_assignment)
		let rsync_flags = ("" | if $recursive {append "r"} else $in | if $verbose {append "v"} else $in | if $compress {append "z"} else $in | str join)
		let rsync_flags = (if not ($rsync_flags | is-empty) { $"-($rsync_flags)" } else "")
		log_info $"Transfering: ($source) -> ($destination)"

		let command = [$source $destination]
		let command = (if not ($rsync_flags | is-empty) {$command | prepend $rsync_flags} else $command)
		let command = ($command | prepend $"rsync -e 'ssh (ssh_arguments)'")
		let command = ($command | str join " ")
		nu -c $command
	}
}

# iperf3 wrapper for apc targets
export def "apc test" [] {
	apc shell "iperf3 -s &"
	iperf3 -c $env.target.ip
	apc shell "pkill iperf3"
}

export def "apc ping" [] {
	let-env target = avahi_browse_prompt _ssh._tcp
	if not ($env.target | is-empty) {
		ping $env.target.ip -c 100 -4 -s 100 -i 0.002 -q
	}
}

# rust build and debug
export def "apc debug-old" [
	arguments: string	# cross arguments for compilation
] {
	log_info "Running rust debug on device"
	let executable = (nu -c $"cross build -q ($arguments) --message-format json" | split row "\n" | each {from json} | where -b {columns | any $it == executable} | where -b {not ($in.executable | is-empty)} | get 0.executable)
	apc transfer $".($executable)" :
}

export def "apc debug" [
	executable: string	# cross arguments for compilation
] {
	apc transfer $executable :
	apc shell
}