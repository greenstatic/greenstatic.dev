---
title: "Makerdiary nRF52840 MDK USB Dongle fix reset button"
date: 2022-11-09T22:40:25+01:00
type: post
summary: Fixing broken reset button on Makerdiary nRF52840 MDK USB Dongle 
categories:
- Hardware
tags:
- nRF52840
- hardware development
- devkit
---

## Background
I was playing around with a Makerdiary nRF52840 MDK USB Dongle and somehow managed to soft-brick
the dongle by flashing an application that overwrote the reset button pin, meaning I couldn't enter
the bootloader to flash a new application onto the dongle.
To be honest I don't even know what was the application since the dongle was sitting in my drawer
for so long after a long break from playing around with it.

The dongle either contains (1) Open Bootloader or (2) UF2 Bootloader as per [documentation](https://wiki.makerdiary.com/nrf52840-mdk-usb-dongle/programming/).
It is advised if your dongle was shipped with Open Bootloader (older dongle versions) to upgrade to the UF2 bootloader due to it's
easy to use feature of appearing as a flash drive and loading new applications onto the flash drive when in DFU mode.
In order to get the dongle into DFU mode, one must hold the RESET/USER button (see image 2) while inserting the device into the USB slot.
If successful, the onboard LED will blink red twice and then a solid green. You are now in DFU mode and if using the UF2
bootloader a new (emulated) flash drive will appear on your computer which accepts `.uf2` format application images - details
in the [official documentation](https://wiki.makerdiary.com/nrf52840-mdk-usb-dongle/programming/).

<div class="row justify-content-center">
    <div class="col-auto">
        <figure>
            <img style="max-width:300px" class="img-fluid" src="/static-posts/2022/mdk-dongle/dongle.jpeg" />
            <figcaption style="text-align:center">
                <small>Image 1: Makerdiary nRF52840 MDK USB Dongle - <a href="https://makerdiary.com/products/nrf52840-mdk-usb-dongle">source</a></small>
            </figcaption>
        </figure>
    </div>
</div>

<div class="row justify-content-center">
    <div class="col-auto">
        <figure>
            <img class="img-fluid" src="/static-posts/2022/mdk-dongle/pinout.png" />
            <figcaption style="text-align:center">
                <small>Image 2: Pinout diagram - <a href="https://wiki.makerdiary.com/nrf52840-mdk-usb-dongle/">source</a></small>
            </figcaption>
        </figure>
    </div>
</div>

## Problem
Since the RESET/USER button is wired directly to <em>P0.18/RESET</em> pin on the nRF52840 (see image 3) it can either be programed as a GPIO
pin or nRESET.
By **default it is set as GPIO** so that the bootloader can detect the button press and start DFU mode.
However in my case I accidentally programmed the dongle with an application that **sets the pin as nRESET**, this causes the dongle to reset
(i.e. restart) when holding the button while inserting into USB instead of entering DFU mode.

The trickly detail is that setting this pin mode is <strong>stored into non-volatile memory (NVM)</strong>, specifically in the 
UICR (User Information Configuration Register) - source <a href="https://infocenter.nordicsemi.com/pdf/nRF52840_PS_v1.7.pdf">nRF52840 Product Specification v1.7</a> page 43.
This means that when we cause a power cycle of the dongle, the pin is still configured as nRESET and in turn the bootloader will not trigger DFU mode if
the RESET button is being held during insertion.

<div class="row justify-content-center">
    <div class="col-auto">
        <figure>
            <img class="img-fluid" src="/static-posts/2022/mdk-dongle/reset-pinout-1.png" />
            <img class="img-fluid" src="/static-posts/2022/mdk-dongle/reset-pinout-2.png" />
            <figcaption style="text-align:center">
                <small>Image 3: RESET/USER button pinout - source <a href="https://infocenter.nordicsemi.com/pdf/nRF52840_PS_v1.7.pdf">nRF52840 Product Specification v1.7</a></small>
            </figcaption>
        </figure>
    </div>
</div>

## Solution
So in order to fix this we need to clear the UICR register.
Luckily I figured that whatever I flashed actually would go into DFU mode if I pressed the button twice after being already inserted in the USB
slot.
This saved me a great deal of work since I wouldn't need to flash the SoC using J-Link / DAPLink ([source](https://github.com/makerdiary/nrf52840-mdk-usb-dongle/issues/5))
but simply run an application that resets the UICR register by drag and dropping the UF2 formatted application while the dongle is in DFU mode.

Then I also found out that such an application that would reset the UICR register [already exists](https://github.com/makerdiary/nrf52840-mdk-usb-dongle/issues/14) 
in the MDK's dongle Git repository 
<a href="https://github.com/makerdiary/nrf52840-mdk-usb-dongle/tree/master/examples/nrf5-sdk/pselreset_erase">pselreset_erase</a>.
And as a bonus, there was already a <a href="https://github.com/makerdiary/nrf52840-mdk-usb-dongle/blob/master/firmware/openthread/cli/thread_cli_ftd_nrf52840_mdk_usb_dongle_v1.3.0.uf2">compiled version</a> in UF2 format.

Quickly reviewing the pselreset_erase application reveals that it clears the PSELRESET UICR register and then 
indicates to the user that it is finished by [toggling the LED](https://github.com/makerdiary/nrf52840-mdk-usb-dongle/blob/40136203035916083252595b921491eb032f2154/examples/nrf5-sdk/pselreset_erase/main.c#L152-L159).

### Commands
So to summarize in my case when using the UF2 bootloader:

1. Enter DFU mode on the dongle (if you are lucky like me, otherwise you will need a J-Link / DAPLink)
2. ```sh
   $ sudo su -
   $ lsblk
   NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
   sda            8:0    1  3.9M  0 disk 
   mmcblk0      179:0    0 29.1G  0 disk 
   ├─mmcblk0p1  179:1    0  256M  0 part /boot
   └─mmcblk0p2  179:2    0 28.9G  0 part /
   mmcblk0boot0 179:32   0    4M  1 disk 
   mmcblk0boot1 179:64   0    4M  1 disk 

   $ mkdir /mnt/mdk/
   $ mount /dev/sda /mnt/mdk
   $ cp pselreset_erase_dongle.uf2 /mnt/mdk/
   $ umount /mnt/mdk
   ```
3. Wait for the LED lights to toggle; in my case the LED started to pulse from <em>green -> yellow -> white -> purple -> blue -> off</em> repeat.
4. Unplug the dongle
5. Enter DFU mode by holding the RESET button while inserting the dongle into the USB slot.

If step 5 works, you have successfully fixed the reset button.
You may now flash a new application onto the dongle, but be sure not to override the P0.18/RESET pin mode.
