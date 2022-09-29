let-env config = {
  show_banner: false
  history_file_format: "sqlite"
  completion_algorithm: "fuzzy"
  buffer_editor: "micro"
  filesize_metric: true
  table_mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
  use_ls_colors: true
  use_grid_icons: true
  footer_mode: "10" #always, never, number_of_rows, auto
  quick_completions: false
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
}

def-env which-cd [program] { which $program | get path | path dirname | str trim | each { |path| cd $path } }

def-env which-open [program] { which ($program) | get path | path dirname | explorer $in }

alias l = (ls | grid -c)
alias ll = (ls -l)
alias la = (ls -a | grid -c)

let ad = 'C:\Users\jon\AppData\Roaming'
alias ad = cd $ad
alias pwd = $env.PWD
alias cwd = $env.PWD
alias m = micro
alias lsa = ls -a
alias venv = py -m virtualenv
alias p = pnpm
alias c. = code .

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
# let-env PROMPT_COMMAND = { starship prompt }
let-env PROMPT_COMMAND = { starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)' }

let-env PROMPT_COMMAND_RIGHT = {""}

use custom-completions/cargo/cargo-completions.nu *
# use custom-completions/yarn/yarn-completion.nu *
use custom-completions/git/git-completions.nu *

alias mp3-dl = youtube-dl --audio-format mp3 -x

use banner.nu
banner show_banner
