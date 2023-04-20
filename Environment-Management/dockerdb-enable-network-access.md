# How to Enable Network Access for Docker

## Question
Just started Exasol Advanced Analytics Training, for an exercise network access is required.

I'm using Exasol@Docker for the training, found a hint how to enable network access from Communitiy Edition in Virtualbox VM, but I don't know how to enable it on the Docker container.

## Answer
The problem was caused by a combination of docker configuration and firewall.

I'm using OSX (Mac), I had to change the docker daemon configuration and [add a further dns server](https://stackoverflow.com/questions/44410259/how-do-i-configure-which-dns-server-docker-uses-in-docker-desktop-for-mac).

Now, the this request works (with own apiKex):
> with urllib.request.urlopen("http://free.currencyconverterapi.com/api/v5/convert?q=EUR_USD&compact=ultra&apiKey=d7ae34bdee893bbda7d2") as url: 

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 