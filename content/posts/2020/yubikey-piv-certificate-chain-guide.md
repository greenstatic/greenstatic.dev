---
title: "YubiKey PIV Certificate Chain Guide"
date: 2020-07-24T11:53:00+02:00
type: post
summary: How to import your entire certificate chain into your YubiKey so you can verify signatures successfully. 
categories:
- Security
tags:
- yubikey
- pki
- x.509
---

So you finally got your new fancy YubiKey. 
Hurray!!! 🎉
You know it's going to improve your security and you can finally get rid
of that little voice that keeps you awake in the middle of the night.
You know, because your keys are on your computer (althrough encrypted, hopefully) but as a 
software engineer you run so much "random GitHub" code that you are starting to get very anxious
at all the different ways malicious users can pwn you.

You visit Yubico, navigate to the documentation page and are blasted with acronyms that you don't understand.
You then decide to follow a guide or two, but it's missing stuff.
It's explaining things but not guiding you how to solve concrete problems.
Simple questions like how many keys can I store become confusing.

You stand there perplexed.
This can't be, you must not be getting something, this shouldn't be so hard.
Rest assured, you arn't the only one. 
As a [GitHub issue comment](https://github.com/Yubico/yubico-piv-tool/issues/153#issuecomment-407483215) 
on the yubico-piv-tool repository nicely puts it:

![YubiKey in a nutshell](/static-posts/2020/yubikey_in_a_nutshell.png)

So, how do I import my X.509 certificate including the entire certificate chain and 
private key so I can use my certificate entirely on my YubiKey and verify signatures as well?
Well, let's get started!

I have come to the following conclusions for **my use case which is importing my [qualified digital certificate issued by
my government](https://www.si-trust.gov.si/en/)** for the purpose of digitally signing documents and logging into 
government services. 
I own a **YubiKey 5C** device for which this guide is written for, but should work on other YubiKey devices that support PIV.

## Requirements
* A YubiKey that supports PIV (e.g. YubiKey 5C)
* [YubiKey Manager](https://www.yubico.com/products/services-software/download/yubikey-manager/) installed
* `ykman` (usually bundled with YubiKey Manager)

## A Bit of Background
As you are probably aware of YubiKey has [certificate slots](https://developers.yubico.com/PIV/Introduction/Certificate_slots.html).
These follow specification [NIST 800-73-4: *Interfaces for Personal Identity Verification – Part 1: PIV Card Application Namespace, Data Model and Representation*](https://csrc.nist.gov/publications/detail/sp/800-73/4/final).

What this means is that different slots act differently during private key operations, such as always requiring the PIN 
(i.e. Slot 9c: Digital Signature).
One certificate slot can contain only one certificate along with the corresponding private key.
But our digital certificate can contain the entire chain (all the way to the root certificate).
Even though our `.p12` file contains the entire chain, when we import it into one of the certificate slots, YubiKey 
Manager doesn't warn us about anything.
In the background what it does is take the private key and the corresponding certificate and import it into the 
certificate slot discarding any other certificates.

The workaround is to import each certificate from the chain into it's own certificate slot.
Now since we only hold the private key to our certificate and not to the other certificates in the chain it doesn't matter
in which certificate slot we import it since no private key operations will be conducted using those certificates.

### Certificate Slot Organization
In my use case I imported my certificate (and private key) into slot 9a (PIV Authentication), you may import it into 
whichever slot you like.
But you will soon see that via the GUI YubiKey Manager displays only 4 slots (9a, 9c, 9d and 9e). 
Does this mean you can only have 4 certificates in the entire chain?
No!
You can import the certificate chain certificates into the Retired Key Management slots (82-95 on YubiKey 4 & 5, a total 
of 20 slots - the slot numbers are in hex)
but these slots are only accessible via the CLI and not the GUI.

So in other words, **it is better to configure this using the CLI since you will still have the GUI-displayed slots available
for future use**.

## How To Guide
1. Have ready all certificates that make the chain or if present in the `.p12` file, extract the certificates[^1] into 
separate files.
2. Insert your YubiKey into your computer, open YubiKey Manager, under Applications select PIV. Configure your PIN's 
(if not already). Select *Configure Certificates* and import your certificate (and private key) into your desired slot.
3. Open the terminal and `cd` into the dir that contains `ykman` - on macOS this is very important since otherwise you 
get an error when running the tool. `ykman` comes bundled with YubiKey Manager on macOS and is available in the dir: 
`/Applications/YubiKey\ Manager.app/Contents/MacOS`.
4. Import your chain certificates into Retired Key Management slots (82-95):
   ```shell
   $ ./ykman piv import-certificate 82 chain_cert_root.pem
   $ ./ykman piv import-certificate 83 chain_cert_intermediate.pem
   $ ./ykman piv import-certificate 84 chain_cert_intermerdiate_2.pem
   # ... add as many certificates as you need
   # Slot numbers are in hex! 82, ..., 88, 89, 8a, 8b, 8c, 8d, 8e, 8f, 90, 91, ... , 95
   ```
5. Plug out your Yubikey from your computer and give it a try.


[^1]: This is one way of viewing all certificates that are emedded in a `.p12` file:
    ```shell
    $ openssl pkcs12 -in <my_certificate.p12> -out <tmp.pem>
    $ openssl x509 -in <tmp.pem> -noout -text
    ```
