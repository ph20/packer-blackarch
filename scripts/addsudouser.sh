#!/usr/bin/env bash
# stop on errors
set -eu

# vagrant key from https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
VAGRANT_INSECURE_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key'
SUDOUSERS_DIR=/etc/sudoers.d
TMP_PUB_KEY=/root/authorized_keys_tmp_
USERID=""
USERPASSWD=""
KEY=""

CURL=$(which curl)
INSTALL=$(which install)

set_key(){
    declare user_name="$1" key="$2"

    local user_home=$(getent passwd ${user_name} | cut -d':' -f 6)
    local ssh_dir="${user_home}/.ssh"
    local authorized_keys="${ssh_dir}/authorized_keys"
    local user_pubkey_url=${key}

    echo "[+] Setup public ssh key for user '${user_name}'"
    if [[ "$key" == 'vagrant' ]]; then
        echo ${VAGRANT_INSECURE_KEY} > ${TMP_PUB_KEY}
    else
        ${CURL} -s --output ${TMP_PUB_KEY} --location ${user_pubkey_url}
    fi

    if [[ ! -d "${ssh_dir}" ]]; then
        ${INSTALL} --directory --owner=${user_name} --group=${user_name} --mode=0700 ${ssh_dir}
    fi
    if [[ ! -f "${authorized_keys}" ]]; then
        ${INSTALL} --owner=${user_name} --group=${user_name} --mode=0600 /dev/null ${authorized_keys}
    fi

    cat ${TMP_PUB_KEY} >> ${authorized_keys}
    rm -f ${TMP_PUB_KEY}
}

add(){
    declare user_name="$1" user_id="$2" user_passwd="$3"

    local useradd_args=""
    local sudousers_file="${SUDOUSERS_DIR}/10_${user_name}"

    if [[ ! -z "${user_id}" ]]; then
        useradd_args="--uid ${user_id}"
    fi
    if [[ ! -z "${user_passwd}" ]]; then
        passwd_=$(/usr/bin/openssl passwd -quiet  -crypt "'${user_passwd}'")
        useradd_args="${useradd_args} --password ${passwd_}"
    fi


    echo "[+] Adding sudo user '${user_name}' with uid ${user_id}; args ${useradd_args}"
    /usr/sbin/useradd  ${useradd_args} --comment 'Sudo User' --create-home --user-group ${user_name}
    if [[ ! -f ${sudousers_file} ]]; then
        echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > ${sudousers_file}
    fi
    echo "${user_name} ALL=(ALL) NOPASSWD: ALL" >> ${sudousers_file}
    /bin/chmod 0440 ${sudousers_file}

}

USERNAME="$1"; shift

for i in "$@"
do
case $i in
    -i=*|--uid=*)
    USERID="${i#*=}"
    ;;
    -p=*|--passwd=*)
    USERPASSWD="${i#*=}"
    ;;
    -k=*|--key=*)
    KEY="${i#*=}"
    ;;
    *)
            # unknown option
    ;;
esac
done


add "${USERNAME}" "${USERID}" "${USERPASSWD}"
if [[ ! -z "$KEY" ]]; then
    set_key "${USERNAME}" "$KEY"
fi