# AWS EXAStorage disk enlargement 
## Background

Enlarge EXAStorage disk(s) after changing disk size of the EC2 instances

## Prerequisites

* To complete these steps, you need access to the AWS Management Console and have the permissions to do these actions in EXAoperation
* Please ensure you have a valid backup before proceeding. The below approach works only with the cluster installation.

## How to enlarge disk space in AWS

1. Stop all databases and stop EXAStorage in EXAoperation
2. Stop your EC2 instances, except the license node (ensure they don’t get terminated on shutdown; check shutdown behavior <http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-expand-volume.html>)
3. Modify the disk on AWS console (Select Volume -> Actions -> Modify -> Enter the new size -> Click Modify)
4. Ensure Storage disk size is set to “Rest” <EXAoperation node setting>, if d03_storage/d04_storage is not set to "Rest", set INSTALL flag for all nodes adjust the setting and set the ACTIVE flag for all nodes, otherwise nodes will be reinstalled during boot (data loss)!
5. Start instances
6. Start EXAStorage
7. Enlarge each node device using the “Enlarge Button” in EXAoperation/EXAStorage/n00xx/h000x/
8. Re-Start database

## Additional References

<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-modify-volume.html>

