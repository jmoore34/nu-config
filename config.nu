let carapace_completer = {|spans|
  carapace $spans.0 nushell $spans | from json
}

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
    pdfpc $pdf_path
}

alias co = git checkout
alias push = git push
alias pull = git pull
alias cc = cd /Users/m361234/chedr-core
alias ll = ls -l
def l [] { ls | grid -c }
def la [] { ls -a | grid -c }
def dps [] { docker ps | from ssv }
def dls [] { docker image ls | from ssv }
# Kill all running Docker containers
def "docker kill-all" [] {
    docker ps -q | lines | each {|id| docker kill $id}
}
alias dka = docker kill-all

$env.config = {
    ls: {
        use_ls_colors: true
        clickable_links: true
    }
    rm: {
        always_trash: true
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
        file_format: "sqlite"
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
              { edit: insertString value: "cd " }
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
    buffer_editor: "micro"
    footer_mode: "auto" # always, never, number_of_rows, auto
    use_grid_icons: true
}

def --env which-cd [program] { which $program | get path | path dirname | str trim | each { |path| cd $path } }

def --env which-open [program] { which ($program) | get path | path dirname | explorer $in }


let ad = 'C:/Users/jon/AppData/Roaming'
alias ad = cd $ad
alias pwd = echo $env.PWD
alias cwd = echo $env.PWD
alias m = micro
alias lsa = ls -a
alias venv = py -m virtualenv
alias p = pnpm
alias c = code
alias c. = code .
alias cr = cargo run
alias cb = cargo build
alias ct = cargo test
# def pointers [string] { echo $string | str find-replace -a "/(" "!(" | str find-replace -a 0x !0x | split row ! | table -n 1 }

# def s [sec] {shutdown -a | ignore; shutdown -s -t ($sec | into string)}

alias r = cargo r
alias re = cd ~/repos

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
    code $nu.config-path | path dirname
}
alias su = sudo nu

def e [...args] {
    if $nu.os-info.kernel_version ends-with MANJARO {
        exo-open --launch FileManager $args
    } else {
        explorer $args
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

alias r = e ~/repos
alias pl = e $env.plugins
alias b = nu C:\Users\jon\repos\ChaosTheoryPlugins\build.nu
use std clip

# work
if $nu.os-info.name != windows {
    $env.PROJECT_DIR = '/Users/m361234/chedr-core'
    $env.GITHUB_USER = 'jon'
    $env.PATH ++= [
        /Users/m361234/.ghcup/bin
        /Users/m361234/.cargo/bin
    ]
    $env.USE_GKE_GCLOUD_AUTH_PLUGIN = True
} else {
    $env.QA1_USERNAME = program.b2236bd4
    $env.QA2_USERNAME = program.26b1e36d
    $env.S1_USERNAME = program.b8b5e0a8
    $env.S2_USERNAME = program.f2b28f5a
    $env.S3_USERNAME = program.004e3121
    $env.S4_USERNAME = program.51291a2d
    $env.S5_USERNAME = program.a0666a9b
    $env.S6_USERNAME = program.f746c604
    $env.S7_USERNAME = programjmkds.d164a36f
}