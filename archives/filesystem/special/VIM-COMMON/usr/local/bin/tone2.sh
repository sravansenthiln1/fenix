#!/bin/bash

# Only for desktop
if ! which lightdm; then
    exit
fi

source /etc/fenix-release

if [ "$BOARD" == "VIM1S" ]; then
	OVERLAY_FILE="/boot/dtb/amlogic/kvim1s.dtb.overlay.env"
	OVERLAY_ARRAY=`cat $OVERLAY_FILE`
elif [ "$BOARD" == "VIM4" ]; then
	OVERLAY_FILE="/boot/dtb/amlogic/kvim4.dtb.overlay.env"
	OVERLAY_ARRAY=`cat $OVERLAY_FILE`
else
	OVERLAY_FILE="/boot/env.txt"
	OVERLAY_ARRAY=`grep -n "overlay" $OVERLAY_FILE | cut -d ":" -f 2`
fi

CONFIG_DIR="/usr/share/fenix/tone2"
CONFIG_FIEL="/usr/share/fenix/tone2/tone2.conf"

if [ -f "$CONFIG_FIEL" ]; then
	MODE=`cat $CONFIG_FIEL`
	if [[ "$MODE" =~ "i2s" ]]; then
		LIST_MENU_VALUE=(TRUE FALSE FALSE)
	else
		LIST_MENU_VALUE=(FLASE TRUE FALSE)
	fi
else
	LIST_MENU_VALUE=(FALSE FALSE TRUE)
fi

LIST_MENU=(I2S USB Disable)

selected_mode=$(zenity --height=275 \
                --list --radiolist \
                --title 'Tone2 Setting' \
                --text 'Select Tone2 Mode' \
                --window-icon /etc/fenix/icons/tone2.png \
                --column 'Select' \
                --column 'Mode' \
                ${LIST_MENU_VALUE[0]} ${LIST_MENU[0]} \
                ${LIST_MENU_VALUE[1]} ${LIST_MENU[1]} \
                ${LIST_MENU_VALUE[2]} ${LIST_MENU[2]})

echo "$selected_mode"


echo $OVERLAY_ARRAY

password=$(zenity --password --title 'Password')

if [ $? -ne 0 ]; then
    exit
fi

if [ -z $password ]; then
    zenity --warning --height=100 --width=200 \
            --text="Password is empty!\nNothing saved!\n\nExit."
    exit
fi


sudo -k

if sudo -lS &> /dev/null << EOF
$password
EOF
then
	sudo mkdir -p $CONFIG_DIR
fi


if [ "$selected_mode" = "I2S" ] || [ "$selected_mode" = "USB" ]; then
	if [ ! -f "$CONFIG_FIEL" ]; then
		sudo touch $CONFIG_FIEL
	fi
	if [[ "$OVERLAY_ARRAY" =~ "pwm_f" ]]; then
		zenity  --question \
			--text 'Need to remove pwm_f in overlay' \
			--title 'Warning' \
			--window-icon /etc/fenix/icons/warning.png \
			--width=300 \
			--height=40 \
			--ok-label='Yes' \
			--cancel-label="No"

		if [ $? -ne 0 ]; then
			exit
		fi

		OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/pwm_f//g'`
		OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/  / /g'`
	fi
	if [[ "$OVERLAY_ARRAY" =~ "pwm_d" ]]; then
		zenity  --question \
			--text 'Need to remove pwm_d in overlay' \
			--title 'Warning' \
			--window-icon /etc/fenix/icons/warning.png \
			--width=300 \
			--height=40 \
			--ok-label='Yes' \
			--cancel-label="No"

		if [ $? -ne 0 ]; then
			exit
		fi

		OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/pwm_d//g'`
		OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/  / /g'`
	fi

	if [[ "$OVERLAY_ARRAY" =~ "pwm_ao_a" ]]; then
		zenity  --question \
			--text 'Need to remove pwm_ao_a in overlay' \
			--title 'Warning' \
			--window-icon /etc/fenix/icons/warning.png \
			--width=300 \
			--height=40 \
			--ok-label='Yes' \
			--cancel-label="No"

		if [ $? -ne 0 ]; then
			exit
		fi
		OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/pwm_ao_a//g'`
		OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/  / /g'`
	fi
	
	if [[ "$selected_mode" = "I2S" ]];then
		if [[ "$OVERLAY_ARRAY" =~ "i2s" ]]; then
			echo "include i2s"
		else
			OVERLAY_ARRAY="$OVERLAY_ARRAY i2s"
		fi

		echo "i2s" | sudo tee $CONFIG_FIEL
	else
		zenity --warning --height=100 --width=200 \
        	--text="Maybe you need to select the sound output device in system settings."
		echo "usb" | sudo tee $CONFIG_FIEL
		if [ "$BOARD" == "VIM1S" ] || [ "$BOARD" == "VIM4" ]; then
			if [[ "$OVERLAY_ARRAY" =~ "i2s" ]]; then
				OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/i2s//g'`
				OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/  / /g'`
			fi
		fi
	fi

else
	if [ -f "$CONFIG_FIEL" ]; then
		sudo rm $CONFIG_FIEL
	fi
	if [[ "$OVERLAY_ARRAY" =~ "i2s" ]]; then
		if [[ "$OVERLAY_ARRAY" =~ "i2s" ]]; then
			OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/i2s//g'`
			OVERLAY_ARRAY=`echo $OVERLAY_ARRAY | sed 's/  / /g'`
		fi
	fi
fi

if [ "$BOARD" == "VIM1S" ] || [ "$BOARD" == "VIM4" ]; then
	echo "$OVERLAY_ARRAY" | sudo tee $OVERLAY_FILE
else
	sudo sed -i '/overlays=/d' "$OVERLAY_FILE"
	echo "$OVERLAY_ARRAY" | sudo tee $OVERLAY_FILE -a
fi

sync

zenity  --question \
	--text 'Reboot to effect ! Reboot now?' \
	--title 'Warning' \
	--window-icon /etc/fenix/icons/warning.png \
	--width=300 \
	--height=40 \
	--ok-label='Yes, reboot now' \
	--cancel-label="No, reboot later"

if [ $? -ne 0 ]; then
	exit
fi

sudo reboot

