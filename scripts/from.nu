export def "env" [
    path: string = ".env"
] {
    parse -r '(\S+)\s*=\s*(\S+)' | reduce -f {} {|it, acc| $acc | upsert $it.capture0 $it.capture1 }
}
