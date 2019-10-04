#!/usr/bin/env bash

# wrapper for the substitution command
function sub
{
    # variables
    local OVERWRITE=""
    local GLOBAL=""
    local FILE=""
    local MATCH=""
    local REPLACE=""
    local LINES="" # used for constructing range with START and END
    local START=""
    local END=""
    local OPTIONS="-r" # default behavior is use regex
    local NEXTARG=""
    local VERBOSE=0

    # private usage function
    function usage
    {
        echo ""
        echo "Description: fsed substitution command"
        echo ""
        echo "USAGE: Run $0 and supply at least two arguments with --source and --target flags"
        echo "       If supplying arguments together (i.e. -mrfo) the individual option order does not matter but the following arguments do"
        echo "       Order: <options> match replace file"
        echo "       If you do not follow that format you may have unintended behavior"
        echo ""
        echo "Note: flags not marked REQUIRED are optional"
        echo "      flags marked NOAV are not available in shorthand mode"
        echo "FLAGS:                Explanation:"
        echo "    --match(-m)           [REQUIRED] the regex to match"
        echo "    --replace(-r)         [REQUIRED] the string to replace the match with"
        echo "    --global(-g)          changes default behavior - regex will match globally"
        echo "    --start(-s)           [NOAV] next argument must be line on which to start the regex match"
        echo "    --end(-e)             [NOAV] next argument must be line on which to end the regex match"
        echo "    --overwrite(-o)       will overwrite given file"
        echo "    --inplace(-i)         same as above"
        echo "    --file(-f)            following argument must be path to file to process"
        echo "    --verbose(-v)         echoes the command that is about to be run"
        echo "    --help(-h)            displays this message"
        echo ""
        echo "Examples:"
        echo "    # matches the first capitalized string and replaces it with an empty string in the given file"
        echo "    sub --match ([A-Z])\w+ --replace \"\" --file ~/Documents/target.txt"
        echo "    # same as bove but using shorthand form"
        echo "    sub -mrf ([A-Z])\w+ \"\" ~/Documents/target.txt"
        echo ""
    }

    # $1 is required argument and is one of the options in usage - sets corresponding variable if true and returns 1 or 0
    # $2 is the next arg
    # $3 is toggle
    function checkArg
    {
        case $1 in
            "-h"|"--help")
                usage
                return 1
            ;;
            "-g"|"--global")
                GLOBAL="g"
            ;;
            "-v"|"--verbose")
                VERBOSE=1
            ;;
            "-i"|"-o"|"--inplace"|"--overwrite")
                OVERWRITE="-i"
                OPTIONS="-i $OPTIONS"
            ;;
            "-m"|"--match")
                if [[ $3 == "" ]]; then
                    MATCH=$2
                    return 2
                fi
            ;;
            "-r"|"--replace")
                if [[ $3 == "" ]]; then
                    REPLACE=$2
                    return 2
                fi
            ;;
            "-s"|"--start")
                if [[ $3 == "" ]]; then
                    START=$2
                    return 2
                else
                    echo "WARNING: specifying a starting line is not supported in short hand mode"
                fi
            ;;
            "-e"|"--end")
                if [[ $3 == "" ]]; then
                    END=$2
                    return 2
                else
                    echo "WARNING: specifying an ending line is not supported in short hand mode"
                fi
            ;;
            "-f"|"--file")
                if [[ $3 == "" ]]; then
                    FILE=$2
                    # check if file exists
                    if [[ ! -f $FILE ]]; then
                        echo "ERROR: file $FILE not present"
                        return 1
                    fi
                    return 2
                fi
            ;;
            *)
                # catch all
                echo "ERROR: illegal option $1 detected"
                usage
                return 1
            ;;
        esac
    }

    # check if the number of arguments supplied was within our limits
    if [[ $# -lt 3 ]] || [[ $# -gt 11 ]]; then
        echo "ERROR: illegal number of arguments entered"
        usage
        return 1
    fi

    # collect arguments
    for (( i = 1; i <= $#; i++ ))
    do
        NEXTARG=$((i+1))
        # check if user is supplying all options together
        if [[ ${i:0:1} == "-" ]] && [[ ! ${i:1:1} == "-" ]] && [[ ${#i} -gt 2 ]]; then
            # process
            for (( j = 1; j < ${#i}; j++ )); do
                checkArg ${!i} ${!NEXTARG}
                rc=$?
                if [[ $rc -eq 2 ]]; then
                    let i++
                elif [[ $rc == "1" ]]; then
                    echo "ERROR: failed parsing args"
                    return 1
                fi
            done
            MATCH=$2
            REPLACE=$3
            if [[ ! $4 == "" ]]; then
                FILE=$4
                # check if file exists
                if [[ ! -f $FILE ]]; then
                    echo "ERROR: expecting file path for arg 4 but file '$FILE' not present"
                    return 1
                fi
            fi
            break
        else
            checkArg ${!i} ${!NEXTARG}
            rc=$?
            if [[ $rc -eq 2 ]]; then
                let i++
            elif [[ $rc == "1" ]]; then
                echo "ERROR: failed parsing args"
                return 1
            fi
        fi
    done

    if [[ ! $END == "" ]] && [[ $START == "" ]]; then
        echo "ERROR: no matching ending line supplied for starting line $START"
        usage
        return 1
    elif [[ ! $END == "" ]] && [[ ! $START == "" ]]; then
        LINES="$START,$END"
    elif [[ ! $START == "" ]]; then
        LINES=$START
    fi

    # [Invoking Sheev]: do eet
    #
    if [[ $MATCH == *"!"* ]]; then
        # dont use ! use @
        #echo "Command would be:"
        if [[ $VERBOSE -eq 1 ]]; then
            echo "Running command: sed $OPTIONS \"${LINES}s@${MATCH}@${REPLACE}@${GLOBAL} $FILE\""
        fi
        sed $OPTIONS "${LINES}s@${MATCH}@${REPLACE}@${GLOBAL}" $FILE
        if [[ $? -ne 0 ]]; then
            echo "ERROR: sed failed"
            return 1
        fi
    else
        if [[ $VERBOSE -eq 1 ]]; then
            echo "Running command: sed $OPTIONS \"${LINES}s!${MATCH}!${REPLACE}!${GLOBAL} $FILE\""
        fi
        sed $OPTIONS "${LINES}s!${MATCH}!${REPLACE}!${GLOBAL}" $FILE
        if [[ $? -ne 0 ]]; then
            echo "ERROR: sed failed"
            return 1
        fi
    fi
    #
}
