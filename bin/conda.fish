#
# Conda environment activate / deactivate functions for fish shell v2.0+.
#
# Ivan Smirnov (C) 2014
#


#
# INSTALL
#
#     Source this file from the fish shell to enable activate / deactivate functions.
#     In order to automatically load these functions on fish startup, append
#
#         . $ANACONDA_DIR/bin/conda.fish
#
#     to the end of your ~/.config/config.fish file.
#
# USAGE
#
#     To activate an environment, you can use one of the following:
#
#         activate ENV
#
#         conda activate ENV
#
#     To deactivate an environment, use one of:
#
#         deactivate
#
#         conda deactivate
#


# Require version fish v2.0+ to be able to use array slices, `else if`
# and $status for command substitutions
if test (echo (fish -v ^&1) | sed -r 's/^.+version ([0-9]+)\..+/\1/') -lt 2
    echo "Incompatible fish shell version; please upgrade to v2.0 or higher."
    exit 1
end


# Calls activate / deactivate functions if the first argument is activate or
# deactivate; otherwise, calls conda-<cmd> and passes the arguments through
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
            case '*'
                command conda $argv
        end
    end
end


# Equivalent to bash version of conda activate script
function activate --description "Activate a conda environment."
    if [ (count $argv) -lt 1 ]
        echo "You need to specify a conda environment."
        return 1
    end

    # deactivate an environment first if it's set
    if set -q CONDA_DEFAULT_ENV
        conda ..checkenv $argv[1]
        if test $status = 0
            set -l NEW_PATH (conda "..deactivate")
            # convert colon-separated path to a fish list
            set -gx PATH (echo $NEW_PATH | sed 's/:/\n/g')
            if test (conda ..changeps1)
                set -gx PS1 $CONDA_OLD_PS1
                set -e CONDA_OLD_PS1
            end
        else
            return 1
        end
    end

    # try to activate the environment
    set -l NEW_PATH (conda ..activate "$argv[1]")
    if test $status = 0
        # convert colon-separated path to a fish list
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


# Equivalent to bash version of conda deactivate script
function deactivate --description "Deactivate the current conda environment."
    set -l NEW_PATH (conda ..deactivate $argv[1])
    if test $status = 0
        # convert colon-separated path to a fish list
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
