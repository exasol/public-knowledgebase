# List of Available Cloud AMIs

## Question
If I'm not mistaken then currently when we use https://cloudtools.exasol.com/ to create a new Exasol cluster we will receive a json / yaml / jinja that only contains the current ( or at least just one ) version / AMI / Image.
Apart from the slightly tedious way of regularly checking and saving AMI- /Image-ids that are exposed in this way, is there a simple way to just choose which version one wants to deploy / spin up ? Or a list of AMIs/Images currently available ?

## Answer
```
aws ec2 describe-images --query Images[].Name --filters "Name=name,Values=Exasol-R*-*" "Name=product-code.type,Values=marketplace"  
[  
    "Exasol-R6.2.11-PAYG-b80ae7ff-9219-4124-b87e-102b1086a85f-ami-0c0579e2c43d92c0a.4",  
    "Exasol-R7.0.4-PAYG-b80ae7ff-9219-4124-b87e-102b1086a85f",  
    "Exasol-R7.0.8-PAYG-b80ae7ff-9219-4124-b87e-102b1086a85f",  
    "Exasol-R7.1.2-PAYG-b80ae7ff-9219-4124-b87e-102b1086a85f",  
    "Exasol-R7.0.8-BYOL-d8a5fe21-f7ac-45fb-a03e-d2e768bd92ed",  
    "Exasol-R6.2.6-BYOL-d8a5fe21-f7ac-45fb-a03e-d2e768bd92ed-ami-0ea12d10d6fcced8f.4",  
    "Exasol-R7.0.4-BYOL-d8a5fe21-f7ac-45fb-a03e-d2e768bd92ed",  
    "Exasol-R6.2.6-PAYG-b80ae7ff-9219-4124-b87e-102b1086a85f-ami-085b838cde85b0099.4",  
    "Exasol-R6.2.6-3-PAYG-b80ae7ff-9219-4124-b87e-102b1086a85f-ami-053f5eb6c65e01b22.4",  
    "Exasol-R7.1.0-PAYG-b80ae7ff-9219-4124-b87e-102b1086a85f",  
    "Exasol-R7.0.11-BYOL-d8a5fe21-f7ac-45fb-a03e-d2e768bd92ed",  
    "Exasol-R7.1.0-BYOL-d8a5fe21-f7ac-45fb-a03e-d2e768bd92ed",  
    "Exasol-R6.2.11-BYOL-d8a5fe21-f7ac-45fb-a03e-d2e768bd92ed-ami-021e51f38f2c40cba.4",  
    "Exasol-R7.1.2-BYOL-d8a5fe21-f7ac-45fb-a03e-d2e768bd92ed",  
    "Exasol-R7.0.11-PAYG-b80ae7ff-9219-4124-b87e-102b1086a85f",  
    "Exasol-R6.2.6-3-BYOL-d8a5fe21-f7ac-45fb-a03e-d2e768bd92ed-ami-091d8f7cf8181cffd.4"  
]
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 