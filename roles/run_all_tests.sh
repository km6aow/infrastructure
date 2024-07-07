#!/bin/bash -e

# Log in to Vault 
if [ -z "$VAULT_ADDR" ] ; then
  echo "You must provide the VAULT_ADDR environment variable."
  exit 40
fi

if [ -z "$ROLE_ID" ] ; then
  echo "You must provide the ROLE_ID environment variable for the concourse_approle."
  exit 41
fi

if [ -z "$SECRET_ID" ] ; then
  echo "You must provide the SECRET_ID environment variable for the concourse_approle."
  exit 41
fi

scenario="--all"
base_config="-c ../molecule/base_config_local.yml"
set -o pipefail

while getopts "c:l:s:r:p" opt; do
    case $opt in
        c)
            echo "Overriding molecule base config path with $OPTARG"
            base_config="-c $OPTARG"
            ;;
        r)
            echo "Run role $OPTARG"
            role="$OPTARG"
            ;;
        s)
            echo "Run scenario $OPTARG"
            scenario="$OPTARG"
            ;;
        p)
            echo "Will execute scenarios in parallel"
            parallel="--parallel"
            ;;
        l)
            echo "Logs will be collected in $OPTARG"
            log_dir="$OPTARG"
            [ -d $log_dir ] || mkdir $log_dir
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

if [[ "$scenario" != "--all" ]] && [[ ! -z "$parallel" ]]; then
    echo "Your arguments ask to run a single scenario in parallel, but that makes no sense. Aborting!"
    exit 42
fi

if [[ "$scenario" != "--all" ]] && [[ -z "$role" ]]; then
    echo "Your arguments ask to run a certain scenario, but you did not specify the role. Aborting!"
    exit 43
fi


mcmd="molecule $base_config test $parallel"

if [[ ! -z "$role" ]]; then
    pushd $role/ > /dev/null
    export VAULT_TOKEN=$(vault write -f -format=json auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID" | jq -r ".auth.client_token")
    if [[ "$scenario" != "--all" ]]; then
        echo "[$role] Testing scenario $scenario"
        $mcmd --scenario-name $scenario
    else
        role_scenarios=($(ls -d */*/molecule.yml | cut -d/ -f2))
        for ((i = 0; i < ${#role_scenarios[@]}; i++)); do
            role_scenario=${role_scenarios[$i]}
            echo "[$role] Testing scenario $role_scenario"
            if [[ ! -z $parallel ]]; then
                ANSIBLE_FORCE_COLOR=0 PY_COLORS=0 $mcmd --scenario-name $role_scenario > ${log_dir}molecule_${role}_$role_scenario.log 2>&1 &
                scenario_pids[$i]=$! # store bg job id
            else
                $mcmd --scenario-name $role_scenario | tee ${log_dir}molecule_${role}_$role_scenario.log 2>&1
            fi
        done
        # wait for bg jobs
        for ((j = 0; j < ${#scenario_pids[@]}; j++)); do
            pid=${scenario_pids[$j]}
            wait $pid || (echo "[$role] Scenario ${role_scenarios[$j]} failed" && exit 44)
        done
        echo "[$role] Finished waiting for scenario test jobs"
    fi
    vault token revoke --self
    popd > /dev/null
else
    echo "Searching for all roles with tests"
    for role_with_tests in $(ls -d */molecule | cut -d/ -f1); do
        echo "Testing role $role_with_tests"
        export VAULT_TOKEN=$(vault write -f -format=json auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID" | jq -r ".auth.client_token")
        pushd $role_with_tests/ > /dev/null
        role_scenarios=($(ls -d */*/molecule.yml | cut -d/ -f2))
        for ((i = 0; i < ${#role_scenarios[@]}; i++)); do
            role_scenario=${role_scenarios[$i]}
            echo "[$role_with_tests] Testing scenario $role_scenario"

            if [[ ! -z $parallel ]]; then
                ANSIBLE_FORCE_COLOR=0 PY_COLORS=0 $mcmd --scenario-name $role_scenario > ${log_dir}molecule_${role_with_tests}_$role_scenario.log 2>&1 &
                scenario_pids[$i]=$! # store bg job id
            else
                $mcmd --scenario-name $role_scenario | tee ${log_dir}molecule_${role_with_tests}_$role_scenario.log 2>&1
            fi
        done
        # wait for bg jobs
        for ((j = 0; j < ${#scenario_pids[@]}; j++)); do
            pid=${scenario_pids[$j]}
            wait $pid || (echo "[$role_with_tests] Scenario ${role_scenarios[$j]} failed" && exit 45)
        done
        echo "[$role_with_tests] Finished waiting for scenario test jobs"
        unset scenario_pids
        unset role_scenario
        vault token revoke --self
        popd > /dev/null
        echo 1 > /proc/sys/vm/drop_caches
    done
fi
