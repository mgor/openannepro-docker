#!/usr/bin/env bash

main() {
    local options
    local model

    options=$(getopt \
    --longoptions model: \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)
    [[ $? -eq 0 ]] || { 
        echo "Incorrect options provided"
        return 1
    }

    eval set -- "$options"
    while true; do
        case "$1" in
        --model)
            shift
            model=$1
            [[ ! "${model}" =~ c15|c18 ]] && {
                echo "Incorrect options provided"
                exit 1
            }
            break
            ;;
        --)
            shift
            break
            ;;
        esac
        shift
    done

    [[ -z "${model}" ]] && {
        echo "No model set"
        return 1
    }

    echo "Building for AnnePro2 ${model}"

    docker build --build-arg model="${model}" -t openannepro .
    docker run --privileged -h openannepro --rm -it --user "$(id -u)" -w /home/qmk openannepro bash

    return $?
}

main "$@"
exit $?
