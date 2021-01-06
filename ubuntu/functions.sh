# Exit on any (not really) error, undefined variable or command pipe failure.
set -euo pipefail

count_available_updates() {
    echo $(/usr/lib/update-notifier/apt-check 2>&1 | cut -d ";" -f 1)
}

count_file_lines() {
    test_arguments_count --expected 1 --actual "$#"

    file_path="$1"
    echo $(wc -l "$file_path" | cut -d " " -f 1)
}

get_job_status() {
    test_arguments_count --expected 1 --actual "$#"

    command="$1"
    echo $(jobs | grep "$command" | cut -d " " -f 3)
}

is_decision_positive() {
    test_arguments_count --expected 1 --actual "$#"

    decision=$(lower_string "$1")
    if [[ " y yes yeah yep " =~ " $decision " ]]; then
        echo true
    else
        echo false
    fi
}

is_empty() {
    test_arguments_count --expected 1 --actual "$#"

    if [ -z "$1" ]; then
        echo true
    else
        echo false
    fi
}

is_upgrade_done() {
    job_status=$(get_job_status "sudo apt upgrade*")
    if $(is_empty "$job_status") || [ $job_status == "Done" ]; then
        echo true
    else
        echo false
    fi
}

lower_string() {
    test_arguments_count --expected 1 --actual "$#"

    string="$1"
    echo $(echo "$1" | awk '{print tolower($0)}')
}

start_upgrade_async() {
    sudo apt upgrade -y > /dev/null 2>&1 &
}

test_arguments_count() {
    if (( "$#" != 4 )); then
        echo "'${FUNCNAME[0]}()' takes 2 positional arguments, but $# were given."
        return 1
    fi

    while (( "$#" > 0 )); do
        case "$1" in
            -a|--actual) actual="$2" ;;
            -e|--expected) expected="$2" ;;
        esac
        shift
    done

    if (( "$expected" != "$actual" )); then
        echo "'${FUNCNAME[1]}()' takes $expected argument(s), but $actual were given."
        return 1
    fi

    return 0
}
