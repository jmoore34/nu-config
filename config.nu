def debug-cleanup-hs [] {
    ls **/*.hs
    | each { |file|
        print $"(ansi cyan)Cleaning (ansi yellow)($file.name)"
        let cleaned = (rg -vF 'TODO: remove print debugging' $file.name) + "\n"
        $cleaned | save --force $file.name
    }
}

def present [md_path: path] {
    let pdf_path = '/tmp/presentation.pdf'
    pandoc -s $md_path -i -o $pdf_path -t beamer -V theme:Malmoe -V aspectratio:169
    pdfpc $pdf_path --switch-screens
}

alias co = git checkout
alias push = git push
alias pull = git pull
alias h = cd ~
alias cc = cd /Users/m361234/chedr-core
alias ll = ls -l
def l [] { ls | grid -ci }
def la [] { ls -a | grid -ci }
def dps [] { docker ps | from ssv }
def dls [] { docker image ls | from ssv }
# Kill all running Docker containers
def "docker kill-all" [] {
    docker ps -q | lines | each {|id| docker kill $id}
}
alias dka = docker kill-all


let carapace_completer = {|spans|
  carapace $spans.0 nushell ...$spans | from json
}
$env.config.completions = {
        quick: false  # set this to false to prevent auto-selecting completions when only one remains
        algorithm: "fuzzy"  # prefix or fuzzy
        external: {
            enable: true # set to false to prevent nushell looking into $env.PATH to find more suggestions, `false` recommended for WSL users as this look up my be very slow
            completer: $carapace_completer
        }
    }
$env.config.history.isolation = true
$env.config.history.file_format = 'sqlite'
$env.config.show_banner = false
$env.config.keybindings ++= [
        {
            name: copy_commandline
            modifier: control
            keycode: char_o
            mode: emacs
            event: [{
                send: executehostcommand
                cmd: "commandline | c --silent"
            }]
        }
        {
          name: complete_folder
          modifier: control
          keycode: char_g
          mode: emacs
          event: [
              { edit: clear }
              { edit: insertString value: "cd " }
              { send: Menu name: completion_menu }
          ]
        }
        {
          name: complete_file
          modifier: control
          keycode: char_s
          mode: emacs
          event: [
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
            name: newline
            modifier: shift
            keycode: Enter
            mode: emacs
            event: [
                { edit: InsertNewline }
            ]
        }
    ]
$env.config.hooks = {
        env_change: {
            PWD: [
                { |before, after|
                    if $before != null {
                        print (l) -n
                    }
                }
            ]
        }
        display_output: { ||
            if (term size).columns >= 80 { table -e } else { table }
        }
    }
$env.EDITOR = "code"

def --env wcd [program] { which $program | get path.0 | path dirname | cd $in }

def --env which-open [program] { which ($program) | get path | path dirname | explorer $in }


let ad = 'C:/Users/jon/AppData/Roaming'
alias post = curl -X POST -H "Content-Type:application/json"
alias ad = cd $ad
alias pwd = echo $env.PWD
alias cwd = echo $env.PWD
alias m = micro
alias lsa = ls -a
alias venv = py -m virtualenv
alias p = pnpm
alias c = code
alias c. = code .
alias xh = xh --verify no
# def pointers [string] { echo $string | str find-replace -a "/(" "!(" | str find-replace -a 0x !0x | split row ! | table -n 1 }

# def s [sec] {shutdown -a | ignore; shutdown -s -t ($sec | into string)}

alias re = cd ~/src

def --wrapped kubectl [...args] {
    check-auth
    if ($env.SHOW_K8S? | is-empty) {
        print $"(ansi rb)Error: set k8s context first"
        return 1
    }
    let context = ^kubectl config current-context
    if "prod" in $context and ($env.DANGER_K8S? | is-empty) {
        print $"(ansi rb)Error: set $env.DANGER_K8S to use kubectl in preprod/prod"
        return 2
    }
    ^kubectl ...$args
}

def check-auth [] {
    (
        if not (gcloud auth list --filter=status:ACTIVE | complete | get stdout | str contains "*") {
        gcloud auth login
    }) | ignore
}

def k [] {
    check-auth
    kubetui --namespaces chedr --split-direction horizontal
}

alias kc = kubectl -n chedr

def --env ctx [context?] {
    let context  = if ($context | is-empty) {
        ^kubectl config get-contexts | detect columns | get name | input list
    } else { $context }
    ^kubectl config use-context $context
    $env.SHOW_K8S = 1
}
def make-contexts [] {
    gcloud container clusters get-credentials cx-dev --region us-central1 --project heb-cx-nonprod
    gcloud container clusters get-credentials cx-cert --region us-central1 --project heb-cx-nonprod
    gcloud container clusters get-credentials cx-preprod --region us-central1 --project heb-cx-prod
    gcloud container clusters get-credentials cx-prod --region us-central1 --project heb-cx-prod
    gcloud container clusters get-credentials kp-dev --region us-central1 --project heb-cx-nonprod
    gcloud container clusters get-credentials kp-cert --region us-central1 --project heb-cx-nonprod
    gcloud container clusters get-credentials kp-preprod --region us-central1 --project heb-cx-prod
    gcloud container clusters get-credentials kp-prod --region us-central1 --project heb-cx-prod
}
alias cxd = ctx gke_heb-cx-nonprod_us-central1_cx-dev
alias cxc = ctx gke_heb-cx-nonprod_us-central1_cx-cert
alias cxr = ctx gke_heb-cx-prod_us-central1_cx-preprod
alias cxp = ctx gke_heb-cx-prod_us-central1_cx-prod
alias kpd = ctx gke_heb-cx-nonprod_us-central1_kp-dev
alias kpc = ctx gke_heb-cx-nonprod_us-central1_kp-cert
alias kpr = ctx gke_heb-cx-prod_us-central1_kp-preprod
alias kpp = ctx gke_heb-cx-prod_us-central1_kp-prod

def r [old, new, files, --write(-w)] {
    for f in (glob $files) {
        if $write {
            open $f | str replace $old $new --all | save $f --force
        } else {
            print $"(ansi yb)($f)(ansi reset)"
            print (open $f | str replace $old $"(ansi gb)($new)(ansi reset)" --all)
        }
    }
}

def --env mcd [path] {
    mkdir $path
    cd $path
}

def ssh-save [server] {
    open ~/.ssh/id_ecdsa.pub | ssh ($server) "(mkdir ~/.ssh; touch ~/.ssh/authorized_keys; cat >> ~/.ssh/authorized_keys)"
}

def count [] {
    let counts = ($in | uniq -c | flatten)
    let len = ($counts | get count | math sum | into float)
    $counts | insert percentage { |row| $row.count / $len * 100 | into string -d 1 | $"($in)%" }
}

def count-multi [] {
    let input = $in
    let counts = ($input | str join ";" | split row ';' | uniq -c | flatten)
    let counts = ($input | str join ";" | split row ';' | uniq -c | flatten)
    let len = ($input | length)
    $counts | insert percentage { |row| $row.count / $len * 100 | into string -d 1 | $"($in)%" }
}

def deltas [] {
    $in | prepend 0 | window 2 | each {
        |x| echo {cumulative: $x.1, delta: ($x.1 - $x.0)}
    }
}

def count-format [] {
    each { |row| $"($row.value): ($row.count) (char lp)($row.percentage)(char rp)" } | str join (char nl)
}

def --env goto [] {
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
    | str replace '//' '/' -a -n
}

def boost [] {
    ls *.mp4
    | find --invert boosted
    | each { |f|
        let new_name = ($f.name | str replace .mp4 .boosted.mp4)
        ffmpeg -i $f.name -vcodec copy -af "volume=30dB" $new_name; rm $f.name
    }
}

def rc [] {
    code ($nu.config-path | path dirname)
}
alias su = sudo nu

def e [...args] {
    if $nu.os-info.name != windows {
        ^open ...$args
    } else {
        explorer ...$args
    }
}
alias e. = e .
alias ein = e $in
alias x = explore

alias f = fend

# termux
alias lolcat = golor

$env.PROMPT_INDICATOR = " "

$env.STARSHIP_SESSION_KEY = (random chars -l 16)
$env.STARSHIP_SHELL = "nu"
$env.PROMPT_COMMAND = { || starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)' }

$env.PROMPT_COMMAND_RIGHT = ""

alias mp3-dl = youtube-dl --audio-format mp3 -x

use banner.nu
banner show_banner

def build-extension [] {
  print $"(ansi light_yellow)Building...(ansi reset)"
  let name = (open src/manifest.json | get name)
  pnpm build
  cd dist
  print "Packaging..."
  rm *.zip -f
  7z a $"($name).zip" *.json *.js *.html *.css
  print $"(ansi light_green)Done!(ansi reset)"
}

def rainbow [str: string] {
    pastel gradient -n ($str | str length) f9584d 4df953
    | pastel format hex
    | lines
    | zip ($str | split chars)
    | each { |pair|
        $"<color=($pair.0)>($pair.1)</color>"
    }
    | str join ""
}

alias pl = e $env.plugins
alias b = nu C:\Users\jon\src\ChaosTheoryPlugins\build.nu

# print a command name as dimmed and italic
def pretty-command [] {
    let command = $in
    return $"(ansi default_dimmed)(ansi default_italic)($command)(ansi reset)"
}

# give a hint error when the clip command is not available on the system
def check-clipboard [
    clipboard: string  # the clipboard command name
    --system: string  # some information about the system running, for better error
] {
    if (which $clipboard | is-empty) {
        error make --unspanned {
            msg: $"(ansi red)clipboard_not_found(ansi reset):
    you are running ($system)
    but
    the ($clipboard | pretty-command) clipboard command was not found on your system."
        }
    }
}

# Put the end of a pipe into the system clipboard.
#
# Dependencies:
#   - xclip on linux x11
#   - wl-copy on linux wayland
#   - clip.exe on windows
#   - termux-api on termux
#
# Examples:
#     put a simple string to the clipboard, will be stripped to remove ANSI sequences
#     >_ "my wonderful string" | c
#     my wonderful string
#     saved to clipboard (stripped)
#
#     put a whole table to the clipboard
#     >_ ls *.toml | clip
#     ╭───┬─────────────────────┬──────┬────────┬───────────────╮
#     │ # │        name         │ type │  size  │   modified    │
#     ├───┼─────────────────────┼──────┼────────┼───────────────┤
#     │ 0 │ Cargo.toml          │ file │ 5.0 KB │ 3 minutes ago │
#     │ 1 │ Cross.toml          │ file │  363 B │ 2 weeks ago   │
#     │ 2 │ rust-toolchain.toml │ file │ 1.1 KB │ 2 weeks ago   │
#     ╰───┴─────────────────────┴──────┴────────┴───────────────╯
#
#     saved to clipboard
#
#     put huge structured data in the clipboard, but silently
#     >_ open Cargo.toml --raw | from toml | clip --silent
#
#     when the clipboard system command is not installed
#     >_ "mm this is fishy..." | clip
#     Error:
#       × clipboard_not_found:
#       │     you are using xorg on linux
#       │     but
#       │     the xclip clipboard command was not found on your system.
export def c [
    --silent (-s) # do not print the content of the clipboard to the standard output
    --no-notify  # do not throw a notification (only on linux)
    --no-strip (-a) # do not strip ANSI escape sequences from a string
    --expand (-e) # auto-expand the data given as input
    --codepage (-c): int  # the id of the codepage to use (only on Windows), see https://en.wikipedia.org/wiki/Windows_code_page, e.g. 65001 is for UTF-8
] {
    let input = $in
        | if $expand { table --expand } else { table }
        | into string
        | if $no_strip {} else { ansi strip }

    match $nu.os-info.name {
        "linux" => {
            if ($env.WAYLAND_DISPLAY? | is-empty) {
                check-clipboard xclip --system $"('xorg' | pretty-command) on linux"
                $input | xclip -sel clip
            } else {
                check-clipboard wl-copy --system $"('wayland' | pretty-command) on linux"
                $input | wl-copy
            }
        },
        "windows" => {
            if $codepage != null {
                chcp $codepage
            }
            check-clipboard clip.exe --system "Windows"
            $input | clip.exe
        },
        "macos" => {
            check-clipboard pbcopy --system "MacOS"
            $input | pbcopy
        },
        "android" => {
            check-clipboard termux-clipboard-set --system "Termux"
            $input | termux-clipboard-set
        },
        _ => {
            error make --unspanned {
                msg: $"(ansi red)unknown_operating_system(ansi reset):
    '($nu.os-info.name)' is not supported by the ('clip' | pretty-command) command."
            }
        },
    }

    if not $silent {
        print $input
        print $"(ansi white_italic)(ansi white_dimmed)saved to clipboard(ansi reset)"
    }

    if (not $no_notify) and ($nu.os-info.name == linux) {
        notify-send "std clip" "saved to clipboard"
    }
}

def lc [] {
    history | last 2 | get 0.command | c
}

def token [] {
   openssl rand --base64 48 | c
}