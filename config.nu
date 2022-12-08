let carapace_completer = {|spans|
  carapace $spans.0 nushell $spans | from json
}

alias l = (ls | grid -c)
alias ll = (ls -l)
alias la = (ls -a | grid -c)

let-env config = {
    ls: {
        use_ls_colors: true
        clickable_links: true
    }
    rm: {
        always_trash: true
    }
    cd: {
        abbreviations: true
    }
    table: {
        mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
        index_mode: always # "always" show indexes, "never" show indexes, "auto" = show indexes when a table has "index" column
        trim: {
            methodology: wrapping # wrapping or truncating
            wrapping_try_keep_words: true # A strategy used by the 'wrapping' methodology
            truncating_suffix: "..." # A suffix used by the 'truncating' methodology
        }
    }
    history: {
        max_size: 10000 # Session has to be reloaded for this to take effect
        sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
        file_format: "plaintext"
    }
    completions: {
        case_sensitive: false
        quick: false  # set this to false to prevent auto-selecting completions when only one remains
        partial: true  # set this to false to prevent partial filling of the prompt
        algorithm: "fuzzy"  # prefix or fuzzy
        external: {
            enable: true # set to false to prevent nushell looking into $env.PATH to find more suggestions, `false` recommended for WSL users as this look up my be very slow
            max_results: 100 # setting it lower can improve completion performance at the cost of omitting some options
            completer: $carapace_completer
        }
    }
    filesize: {
        metric: true
        format: "auto"
    }
    show_banner: false
    keybindings: [
        {
          name: complete_in_cd
          modifier: control
          keycode: char_s
          mode: emacs
          event: [
              { edit: clear }
              { edit: insertString value: "./" }
              { send: Menu name: completion_menu }
          ]
        }
        {
            name: backspace_word
            modifier: control
            keycode: Backspace
            mode: emacs
            event: [
                  { edit: BackspaceWord  }
            ]
        }
        {
            name: reload_config
            modifier: alt
            keycode: char_p
            mode: emacs
            event: {
              send: executehostcommand,
              cmd: $"source '($nu.config-path)'"
            }
        }
        {
            name: cut_line
            modifier: control
            keycode: char_k
            mode: emacs
            event: [
                { edit: cutCurrentLine }
            ]
        }
        {
            name: newline
            modifier: shift
            keycode: Enter
            mode: emacs
            event: [
                { edit: InsertNewline }
            ]
        }
    ]
    hooks: {
        env_change: {
            PWD: [
                { |before, after|
                    if $before != $nothing {
                        print (l) -n
                    }
                }
            ]
        }
    }
    buffer_editor: "micro"
    footer_mode: "auto" # always, never, number_of_rows, auto
    use_grid_icons: true
}

def-env which-cd [program] { which $program | get path | path dirname | str trim | each { |path| cd $path } }

def-env which-open [program] { which ($program) | get path | path dirname | explorer $in }


let ad = 'C:\Users\jon\AppData\Roaming'
alias ad = cd $ad
alias pwd = $env.PWD
alias cwd = $env.PWD
alias m = micro
alias lsa = ls -a
alias venv = py -m virtualenv
alias p = pnpm
alias c. = code .
alias "scoop search" = scoop-search

# def pointers [string] { echo $string | str find-replace -a "\(" "!(" | str find-replace -a 0x !0x | split row ! | table -n 1 }

# def s [sec] {shutdown -a | ignore; shutdown -s -t ($sec | into string)}
alias s = py C:\Users\jon\PycharmProjects\ShutdownScheduler\main.py

alias sc = swiftc.cmd

alias r = cargo r

def-env mcd [path] {
    mkdir $path
    cd $path
}

# Repeat a string a number of times
def "str repeat" [
    count: int # The number of times to repeat the string
    ] {
        let input = $in
        for $i in 1..=count {
            echo $input
        }
    }

def ssh-save [server] {
    open ~\.ssh\id_ecdsa.pub | ssh ($server) "(mkdir ~/.ssh; touch ~/.ssh/authorized_keys; cat >> ~/.ssh/authorized_keys)"
}

def count [] {
    let counts = ($in | uniq -c | flatten)
    let len = ($counts | get count | math sum | into decimal)
    $counts | insert percentage { |row| $row.count / $len * 100 | into string -d 1 | $"($in)%" }
}

def count-multi [] {
    let input = $in
    let counts = ($input | str collect ";" | split row ';' | uniq -c | flatten)
    let len = ($input | length)
    $counts | insert percentage { |row| $row.count / $len * 100 | into string -d 1 | $"($in)%" }
}

def deltas [] {
    $in | prepend 0 | window 2 | each {
        |x| echo {cumulative: $x.1, delta: ($x.1 - $x.0)}
    }
}

def count-format [] {
    each { |row| $"($row.value): ($row.count) (char lp)($row.percentage)(char rp)" } | str collect (char nl)
}

def-env goto [] {
    let input = $in
    cd (
        if ($input | path type) == file {
            ($input | path dirname)
        } else {
            $input
        }
    )
}

def to-linux-path [] {
    $in
    | str replace 'C:' '/mnt/c' -n
    | str replace '\\' '/' -a -n
}

def boost [] {
    ls *.mp4
    | find --invert boosted
    | each { |f|
        let new_name = ($f.name | str replace .mp4 .boosted.mp4)
        ffmpeg -i $f.name -vcodec copy -af "volume=30dB" $new_name; rm $f.name
    }
}

alias rc = (code $nu.config-path | path dirname)
alias su = sudo nu
alias which = which -a

def e [...args] {
    if $nu.os-info.kernel_version ends-with MANJARO {
        exo-open --launch FileManager $args
    } else {
        explorer $args
    }
}
alias e. = e .
alias ein = e $in

alias q = ^"C:\Program Files\Qalculate\qalc.exe"
alias qq = start "C:\Program Files\Qalculate\qalculate.exe"
alias qqq = start "C:\Program Files\Qalculate\qalculate-qt.exe"
alias f = fend

# termux
alias lolcat = golor
alias r = golor

alias dog = dog -n 1.1.1.1

let-env PROMPT_INDICATOR = " "

let-env STARSHIP_SESSION_KEY = (random chars -l 16)
let-env STARSHIP_SHELL = "nu"
let-env PROMPT_COMMAND = { starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)' }

let-env PROMPT_COMMAND_RIGHT = {""}

alias mp3-dl = youtube-dl --audio-format mp3 -x

use banner.nu
banner show_banner
