# Mah wallet check
#	Private property

export def fio [] {
	let token = (/usr/bin/secret-tool lookup finance fio)
	let response = fetch $"https://www.fio.cz/ib_api/rest/periods/($token)/2000-01-01/(date now | date format %Y-%m-%d)/transactions.json"
	$response.accountStatement.info.closingBalance
}

export def lordtoken [] {
	let base_url = "https://exchange.lordtoken.com"
	#let server_time = (curl -s $"($base_url)/open/v1/common/time" | from json | $in.timestamp)
	
	let post_data = $"timestamp=(date now | date to-timezone UTC | date format %s%3f)"
	let signature = ($post_data | openssl dgst -binary -sha256 -hmac $secret | xxd -p)
	echo $"($post_data)&signature=($signature)"
	let response = (curl -s -H $"X-MBX-APIKEY: ($token)" -d $"($post_data)&signature=($signature)" $"($base_url)/open/v1/account/spot" | from json)
	$response
}

