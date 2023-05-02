
def main [] {
    /usr/bin/ssh-agent -c | lines | first 2 | parse "setenv {name} {value};" | reduce -f {} { |it, acc| $acc | upsert $it.name $it.value }
}