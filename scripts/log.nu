def log [color: string, level: string, text: string] {
	echo $"(ansi $color)($level)(ansi reset) ($text)"
}

export def debug [text: string] {
	log p DEBUG $text
}

export def info [text: string] {
	log c INFO $text
}

export def warn [text: string] {
	log y WARN $text
}

export def error [text: string] {
	log r ERROR $text
}