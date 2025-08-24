export def request [
    method: string # GET, POST, PUT, HEAD, PATCH, OPTIONS
    url: string
    --json(-j): any
    --headers(-H): record
    --query-params(-q): record
    --extra-curl-params(-x): string
    --print-curl-command(-c)
    --verbose(-v) # Print all debug information to stdout
    --full(-f) # returns the full response instead of only the body
    --raw(-r) # fetch contents as text rather than a table
    --insecure(-k) # allow insecure servere connections when using SSL
] {
    let args = [
        ($headers | default {} | transpose | rename key value | each {|h|
            [--header ($"($h.key): ($h.value)"
                      | str escape-quotes --when=$print_curl_command)
            ]} | flatten)
        (if ($json | is-not-empty) {[--json ($json | to json)]} else [])
        -X $method
        --silent --show-error
        $"($url)(if ($query_params | is-not-empty) {"?" + ($query_params | url build-query)})"
        (if ($extra_curl_params | is-not-empty) {$extra_curl_params} else [])
        (if ($verbose and not $full) {[--verbose]} else [])
        (if ($insecure) {[--insecure]} else [])
    ] | flatten
    def format_output [] {
        if $raw { $in } else { $in | from json }
    }
    if $print_curl_command {
        $"curl ($args | str join ' ')"
    } else if $full {
        let output = curl ...$args -sw '%{stderr}{headers: {response: %{header_json}}, status: %{response_code}, error: "%{errormsg}"}'
            | complete
        let stdout = $output | get stdout
        $output
            | get stderr
            | from json
            | insert body ($stdout | format_output)
            | insert headers.request $headers
            | update headers.response {|json|
                $json.headers.response
                | transpose
                | rename key values
                | each {|x|
                    {$x.key: $x.values.0?}}
                | into record }
    } else {
        curl ...$args | format_output
    }
}

def "str escape-quotes" [--when=true]: string -> string {
    if not $when {
        $in
    } else if ($in | str contains " ") or ($in | str starts-with '"') {
        '"' + ($in | str replace -a '\' '\\' | str replace -a '"' '\"' ) + '"'
    } else {
        $in
    }
}
export alias GET = request GET
export alias POST = request POST
export alias PUT = request PUT
export alias HEAD = request HEAD
export alias PATCH = request PATCH
export alias OPTIONS = request OPTIONS