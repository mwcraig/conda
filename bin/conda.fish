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
if [ (echo (fish -v ^&1) | sed 's/^.*version \([0-9]\)\..*$/\1/') -lt 2 ]
    echo "Incompatible fish shell version; please upgrade to v2.0 or higher."
    exit 1
end


# Inject environment name into the beginning of the prompt
function __update_prompt
	if [ (conda ..changeps1) ]
		switch $argv[1]
			case activate
				functions -e __fish_prompt_orig
				functions -c fish_prompt __fish_prompt_orig
				functions -e fish_prompt
				function fish_prompt
					echo -n \($CONDA_DEFAULT_ENV\)
					__fish_prompt_orig
				end
			case deactivate
				functions -e fish_prompt
				functions -c __fish_prompt_orig fish_prompt
				functions -e __fish_prompt_orig
		end
	end
end


# Convert colon-separated path to a legit fish list
function __set_path
	set -gx PATH (echo $argv[1] | tr : \n)
end


# Calls activate / deactivate functions if the first argument is activate or
# deactivate; otherwise, calls conda-<cmd> and passes the arguments through
function conda
    if [ (count $argv) -lt 1 ]
        command conda
    else
        if [ (count $argv) -gt 1 ]
            set ARGS $argv[2..-1]
        else
            set -e ARGS
        end
        switch $argv[1]
            case activate deactivate
            	eval $argv
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
        if [ $status = 0 ]
            __set_path (conda ..deactivate)
            set -e CONDA_DEFAULT_ENV
            __update_prompt deactivate
        else
            return 1
        end
    end

    # try to activate the environment
    set -l NEW_PATH (conda ..activate $argv[1])
    if [ $status = 0 ]
    	__set_path $NEW_PATH
        if [ (echo $argv[1] | grep '/') ]
            pushd (dirname $argv[1])
            set -gx CONDA_DEFAULT_ENV (pwd)/(basename $argv[1])
            popd
        else
            set -gx CONDA_DEFAULT_ENV $argv[1]
        end
        __update_prompt activate
    else
        return $status
    end
end


# Equivalent to bash version of conda deactivate script
function deactivate --description "Deactivate the current conda environment."
    set -l NEW_PATH (conda ..deactivate $argv[1])
    if [ $status = 0 ]
    	__set_path $NEW_PATH
        set -e CONDA_DEFAULT_ENV
        __update_prompt deactivate
    else
        return $status
    end
end
