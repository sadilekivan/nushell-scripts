export def "zigbee2mqtt" [] {
	help zigbee2mqtt
}

export def "zigbee2mqtt start" [
	--noopen (-n): bool # Dont open zigbee2mqtt webserver
] {
	let dongle_connected = ("/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20220813105246-if00" | path exists)
	if $dongle_connected {
		log_info "Zigbee USB dongle found"
		log_info "Starting Zigbee2mqtt"
		sudo systemctl start zigbee2mqtt
		if not ($noopen) {
			log_info "Opening Zigbee2mqtt webserver interface"
			xdg-open localhost:8080/
		}
		log_info "Zigbee2mqtt started"
	} else {
		log_error "Zigbee USB dongle not connected"
	}
}

export def "zigbee2mqtt stop" [] {
	log_info "Stopping Zigbee2mqtt"
	sudo systemctl stop zigbee2mqtt
	sudo systemctl stop mosquitto
	log_info "Zigbee2mqtt stopped"
}
