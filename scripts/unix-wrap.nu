#!/usr/bin/env nu

export def lsblk [
    --scsi (-s): bool   #output info about SCSI devices
] {
    let args = "-abp"
    let args = (if $scsi {$args + "S"} else {$args})
    (nu -c $"/usr/bin/lsblk ($args) --json" | from json | get blockdevices | update size {$in.size | into filesize})
}