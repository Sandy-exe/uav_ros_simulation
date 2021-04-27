#!/bin/bash

# Exit immediatelly if a command exits with a non-zero status
set -e

# Executes a command when DEBUG signal is emitted in this script - should be after every line
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG

# Executes a command when ERR signal is emmitted in this script
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

sudo apt-get -y install git

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

## | --------- change to the directory of this script --------- |

cd "$MY_PATH"

## | --------------------- install ROS ------------------------ |

bash $MY_PATH/dependencies/ros.sh

## | --------------------- install gitman --------------------- |

bash $MY_PATH/dependencies/gitman.sh

## | ---------------- install gitman submodules --------------- |

gitman install --force

# Install uav_ros_stack

bash $MY_PATH/../ros_packages/uav_ros_stack/installation/install.sh

# Install ardupilot

bash $MY_PATH/dependencies/ardupilot_dep.sh
bash $MY_PATH/../firmware/ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh -y

SNAME=$( echo "$SHELL" | grep -Eo '[^/]+/?$' )
BASHRC=~/.$(echo $SNAME)rc

distro=`lsb_release -r | awk '{ print $2 }'`
[ "$distro" = "18.04" ] && ROS_DISTRO="melodic"
[ "$distro" = "20.04" ] && ROS_DISTRO="noetic"

# Add Ardupilot exports to bashrc

num=`cat $BASHRC | grep "/ardupilot/Tools/autotest" | wc -l`
if [ "$num" -lt "1" ]; then

  TEMP=`( cd "$MY_PATH/../firmware/ardupilot/Tools/autotest" && pwd )`

  echo "Adding Ardupilot source to $BASHRC"
  echo "# Ardupilot exports
export PATH=\$PATH:$TEMP
export PATH=/usr/lib/ccache:\$PATH" >> $BASHRC
fi

## | ------------- add Gazebo sourcing to .bashrc ------------- |

line="source /usr/share/gazebo/setup.sh"
num=`cat $BASHRC | grep "$line" | wc -l`
if [ "$num" -lt "1" ]; then

  echo "Adding '$line' to your $BASHRC"

  # set bashrc
  echo "$line" >> $BASHRC
fi


## | ------------- add ardupilot completion ------------- |
line=`( cd "$MY_PATH/../firmware/ardupilot/Tools/completion" && pwd )`
num=`cat $BASHRC | grep "$line" | wc -l`
if [ "$num" -lt "1" ]; then
  echo "Adding 'source $line/completion.$SNAME' to your $BASHRC"
  echo "source $line/completion.$SNAME" >> $BASHRC
fi

# Add mavproxy export in case we are using Ubuntu 20.04
line="export PATH=$HOME/.local/bin:\$PATH"
num=`cat $BASHRC | grep "$line" | wc -l`
if [[ "$distro" = "20.04" && "$num" -lt "1" ]]
then
  echo "Adding $line to $BASHRC"
  echo "$line" >> $BASHRC
fi

