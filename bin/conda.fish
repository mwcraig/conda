# A simple conda wrapper for Fish Shell
#
# Ivan Smirnov (C) 2013
#

function conda
    if test (count $argv) -lt 1
        command conda
    else
        if test (count $argv) -gt 1
            set ARGS $argv[2..-1]
        else
            set -e ARGS
        end
        switch $argv[1]
            case activate
                activate $ARGS
            case deactivate
                deactivate $ARGS
            case ls
                list_conda_envs
            case '*'
                command conda $argv
        end
    end
end

function activate --description "activate a conda environment"
    if [ (count $argv) -lt 1 ]
        echo "You need to specify a conda environment."
        return 1
    end

    if set -q CONDA_DEFAULT_ENV
        conda ..checkenv $argv[1]
        if test $status = 0
            set -l NEW_PATH (conda "..deactivate")
            set -gx PATH (echo $NEW_PATH | sed 's/:/\n/g')
            if test (conda ..changeps1)
                set -gx PS1 $CONDA_OLD_PS1
                set -e CONDA_OLD_PS1
            end
        else
            return 1
        end
    end

    set -l NEW_PATH (conda ..activate "$argv[1]")
    if test $status = 0
        set -gx PATH (echo $NEW_PATH | sed 's/:/\n/g')
        if test (echo "$argv[1]" | grep "/")
            pushd (dirname $argv[1])
            set -gx CONDA_DEFAULT_ENV (pwd)/(basename $argv[1])
            popd
        else
            set -gx CONDA_DEFAULT_ENV $argv[1]
        end
        if test (conda ..changeps1)
            set -gx CONDA_OLD_PS1 $PS1
            set -gx PS1 "($CONDA_DEFAULT_ENV)$PS1"
        end
    else
        return $status
    end
end

function deactivate --description "deactivate the current conda environment"
    set -l NEW_PATH (conda ..deactivate $argv[1])
    if test $status = 0
        set -gx PATH (echo $NEW_PATH | sed 's/:/\n/g')
        set -e CONDA_DEFAULT_ENV
        if test (conda ..changeps1)
            set -gx PS1 $CONDA_OLD_PS1
            set -e CONDA_OLD_PS1
        end
    else
        return $status
    end
end

function list_conda_envs --description "list conda environments"
    for e in (ls (conda info | grep "envs directories" | sed -r 's/^.+:\s*(.+)\s*/\1/g'))
        echo $e
    end
end
