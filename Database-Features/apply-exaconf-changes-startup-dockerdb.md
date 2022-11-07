# How to Apply EXAConfg Changes on Startup in DockerDB

## Question
I am trying to "manipulate" exasol docker image to start a container with enabled auditing, expanded storage and ram, also different nameserver list, etc. I've tried to create a specific entrypoint.sh as it was suggested here. Main problem is that it runs ok, but one has to restart the container in order for changes to take place. Is there easier way to enable and change parameters from EXAConf and use them on a first startup? Another suggestion in mentioned post was exa/etc/rc.local, can somebody give me some instructions on how that works?

## Answer
Probably the most elegant way is to use rc.local with python language. I have attached an example file. To use it, you need to copy it to a directory, which you use for the /exa directory inside the container, like this:

mkdir -p /data/n11/etc
cp rc_local.py /data/n11/etc/rc.local
chmod 755 /data/n11/etc/rc.local
docker run -it --privileged -v /data/n11:/exa exasol/docker-db:latest

That way you can set up your container at the start without your own entry point.  This script works with 7.0, to use it with 6.2 you need to use python2 in rc.local. Several things are to mention here:

- When you mount /exa like this, then your EXAConf will not be completely initialized and you need to do that in the rc.local, especially the storage configuration needs to be done there.
- This script is supposed to work on single-node systems, on multi-node systems it should work as well, but there you usually set up the EXAConf and the environment beforehand anyway.

Generally with rc.local you can hook into any stage of the boot process and do things.