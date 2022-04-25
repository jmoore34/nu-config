let $config = {
  filesize_metric: true
  table_mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
  use_ls_colors: true
  use_grid_icons: true
  footer_mode: "10" #always, never, number_of_rows, auto
  animate_prompt: ((sys).host.name == "Windows")
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

# def pointers [string] { echo $string | str find-replace -a "\(" "!(" | str find-replace -a 0x !0x | split row ! | table -n 1 }

# def s [sec] {shutdown -a | ignore; shutdown -s -t ($sec | into string)}
alias s = ^py C:\Users\jon\PycharmProjects\ShutdownScheduler\main.py

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

alias rc = code.cmd ($nu.config-path | into string)

alias e = explorer
alias e. = explorer .
alias ein = explorer $in

alias q = ^"C:\Program Files\Qalculate\qalc.exe"
alias qq = start "C:\Program Files\Qalculate\qalculate.exe"
alias qqq = start "C:\Program Files\Qalculate\qalculate-qt.exe"
alias f = fend

alias dog = dog -n 1.1.1.1

let-env PROMPT_INDICATOR = " "

let-env STARSHIP_SESSION_KEY = (random chars -l 16)
let-env STARSHIP_SHELL = "nu"
# let-env PROMPT_COMMAND = { starship prompt }
let-env PROMPT_COMMAND = { starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)' }


hide PROMPT_COMMAND_RIGHT
# let-env PROMPT_COMMAND_RIGHT = {
#     $"(ansi green)(date format %c)"
# }

# use 'C:\Users\jon\AppData\Roaming\nushell\nu_scripts\prompt\oh-my.nu' git_prompt
# let-env PROMPT_COMMAND = { (git_prompt).left_prompt }
# let-env PROMPT_COMMAND_RIGHT = { (git_prompt).right_prompt }

# let-env PROMPT_COMMAND = { oh-my-posh prompt print primary }
