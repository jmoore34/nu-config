# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = "〉"
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) }
    to_string: { |v| $v | str join (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) }
    to_string: { |v| $v | str join (char esep) }
  }
}

# Directories to search for scripts when calling source or use
#
# By default, <nushell-config-dir>/scripts is added
$env.NU_LIB_DIRS = [
    # ($nu.config-path | path dirname | path join 'scripts')
    ($nu.config-path | path dirname | path join 'nu_scripts')
    ($nu.config-path | path dirname)
]

# Directories to search for plugin binaries when calling register
#
# By default, <nushell-config-dir>/plugins is added
$env.NU_PLUGIN_DIRS = [
    ($nu.config-path | path dirname | path join 'plugins')
]

# work
if $nu.os-info.name != windows {
    $env.PROJECT_DIR = '/Users/m361234/chedr-core'
    $env.GITHUB_USER = 'jon'
    $env.PNPM_HOME = '/Users/m361234/Library/pnpm'
    $env.PATH ++= [
        /opt/homebrew/bin
        /Users/m361234/Library/pnpm
        /Users/m361234/.ghcup/bin
        /Users/m361234/.cargo/bin
        /Applications/Docker.app/Contents/Resources/bin
    ]
    $env.USE_GKE_GCLOUD_AUTH_PLUGIN = true
    $env.CHEDR_DIR = '/Users/m361234/chedr-core'
}