# Starting with the assignment


The assignment is to use Terraform to provision a load balancer that points to an Autoscaling group which runs ec2 with an NGINX as static HTML server.
Document your thoughts into a README so I know how you work and where I can help you get better.

Links:

https://www.terraform.io/
https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180


## Intro and download

Just read the intro to teraform, cool name. I read about the use cases they portray.
Now I am downloading the CLI tool, and figuring out how to add it to my systems path.
Done that, moved my binary to /usr/local/bin, and now terrafrom command works on my terminal.

## Writing the first .tf file.

Okay, first I'm gonna make myself a new AWS account.
Uff, okay done.
Now dowloading the amazon CLI
downloaded, now configuring the AWS CLI

- making new user with programmatic access for my laptop
- add user to new group named MyAdministrators
- Assign to group AdministratorAccess policy: Provides full access to AWS services and resources.
- Provided credentials of new user to `aws configure`

### Touched example.tf

.tf configuration language docs [here](https://www.terraform.io/docs/configuration/index.html)
Copied example from [guide](https://learn.hashicorp.com/terraform/getting-started/build#configuration)
changed region to eu-north-1
changed AMI to region specific Ubuntu AMI ami-ada823d3

### point of doubt:

- "We are explicitly defining the default AWS config profile here to illustrate how Terraform accesses sensitive credentials."
- "Note: If you simply leave out AWS credentials, Terraform will automatically search for saved API credentials (for example, in ~/.aws/credentials) or IAM instance profile credentials. This option is much cleaner for situations where tf files are checked into source control or where there is more than one admin user."
- Details [here](https://aws.amazon.com/blogs/apn/terraform-beyond-the-basics-with-aws/)
- I understand that I could the profile field if there's only one user

## Initializing

`terraform init`
It recomends to provide version constrints. Will skip that atm.

```shell
Terraform has been successfully initialized!
```

## Aply changes

`terraform apply`
### Error with AWS credentials
```shell
error validating provider credentials: error calling sts:GetCallerIdentity: NoCredentialProviders: no valid providers in chain. Deprecated.
For verbose messaging see aws.Config.CredentialsChainVerboseError
```

### Trying to debug this error

I try:

```shell
ls ~/.aws
config credentials
```

I try

```shell
nano nano ~/.aws/credentials
[default]
aws_access_key_id = AKIARR7CRD7BJX7OBI42
```

I see the aws_secret_access_key is missing. I edit the `credentials` with nano
and now:

```shell
terraform apply

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:

- create
  ........

```
### Confirm the change
So now I know what changes will be applied.
I press yes because it looks good..

### Error with AMI
```shell
Error: Error launching source instance: InvalidAMIID.NotFound: The image id '[ami-2757f631]' does not exist
status code: 400, request id: e0429614-be7b-418e-b32b-1fe8ee199080
```

OKAY, wrong AMI.
changing `example.tf` and then `terraform apply`
### Error with AMI

```shell
Error: Error launching source instance: OptInRequired: In order to use this AWS Marketplace product you need to accept terms and subscribe. To do so please visit https://aws.amazon.com/marketplace/pp?sku=3k0ceqj6ojkn6anux1mozu3ih
status code: 401, request id: b5394b77-4825-40a6-beb6-43b026577e67
```
Wrong AMI again
### Error with AMI

```shell
Error: Error launching source instance: Unsupported: The requested configuration is currently not supported. Please check the documentation for supported configurations.
status code: 400, request id: f3669cc1-da7d-4f8a-8649-542d859b8e61

on example.tf line 6, in resource "aws_instance" "example":
6: resource "aws_instance" "example" {
```

Wrong instance type, changing to `instance_type = "t3.micro"`
and now:

```shell
aws_instance.example: Creating...
aws_instance.example: Still creating... [10s elapsed]
aws_instance.example: Creation complete after 13s [id=i-0e0aab534210a10c7]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
OK, now I can see in my AWS console the instance initializing. GOOD.

### After apply info
- `terraform.tfstate` state file. It keeps track of the IDs of created resources so that Terraform knows what it is managing. 
-  It is generally recommended to setup remote state when working with Terraform, to share the state automatically. [guide](https://www.terraform.io/docs/state/remote.html)
- "These values can actually be referenced to configure other resources or outputs, which will be covered later in the getting started guide."

## Changing Infrastructure

I'm going ahead to change the ami to another one. I expect to see the new plan and aprove it.

Switching from:
- Ubuntu Server 18.04 LTS (HVM), SSD Volume Type
+ Amazon Linux 2 AMI (HVM), SSD Volume Type
Instance type remains the same.
`terraform apply` shows the changes in the plan.

´´´shell
Enter a value: yes

aws_instance.example: Destroying... [id=i-0e0aab534210a10c7]
...
aws_instance.example: Destruction complete after 4m25s
aws_instance.example: Creating...
aws_instance.example: Still creating... [10s elapsed]
aws_instance.example: Creation complete after 13s [id=i-009ad25d5d4901bdf]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
´´´
I can see the new instance on the AWS web console.
## Destroy infrastructure
`terraform destroy` the "opposite" of `apply`
I try it and get a plan of removing everything.
**Idea**
- If I remove everything from the `example.tf` I get `Error: Missing required argument`
- If I remove only the resource block from `example.tf` I get the same plan as in `terraform destroy`
I approve the previous plan.
**Result** 
The instance is terminated, and the `terraform.tfstate` holds no more resources atm.

## Apply Resource dependencies

Going to speed up things after a text from Matt.
Going to assign an elastic IP , edit the example instance to depend on an s3 bucket and another ec2 instance.
´terrafrom apply´ gives me the new plan that I approve

### Error
´´´shell
aws_instance.another: Creating...
aws_s3_bucket.example: Creating...

Error: Error creating S3 bucket: BucketAlreadyExists: The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again.
        status code: 409, request id: E4BB595957437D7D, host id: h7IUpLip25m+n+2A0cZTLybVK2taTVLHS5V2g5H1+WbH5JUJFzFLH8jLWfgD6vW+jiAh6hhvf90=

  on example.tf line 7, in resource "aws_s3_bucket" "example":
   7: resource "aws_s3_bucket" "example" {



Error: Error launching source instance: InvalidAMIID.NotFound: The image id '[ami-b374d5a5]' does not exist
        status code: 400, request id: b6c1508c-78f2-4139-9b4a-300930476750

  on example.tf line 29, in resource "aws_instance" "another":
  29: resource "aws_instance" "another" {
´´´
I see that I have the **wrong ami** for the ec2, and there **naming conflict** the bucket.
Also I notice that in the state I have resources entries for:
- elastic ip
- example ec2 that depends on the bucket.
- both resources have an empty array for instances.
- no instances are launched on the AWS atm.

I change the **ami** and the **bucket name** and I ´terraform apply´.

´´´shell
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
´´´
State file and AWS console agree.
`terraform destroy`
And I remove all the unused resources.
# Working on the assignment, implementing dependent resources:

I understand that our setup needs:
- three core resources from AWS, **EC2**, **autoscaling group** and **Application Load Balancer**
- then it also needs some configured software **NGINX serving html** running on the EC2 instances. I can imagine that we could do this easily by choosing a preconfigured image for our instance, but I keep my options open, because I think you expect something else.

## Setting up the resources:
### Autoscaling group
I will start by exploring the **autoscaling group**, since that is onde level above having one instance.
Here I feel confident enough to also start looking at the tutorial you send me.
I found the autoscaling group in the AWS provider docs [here](https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html)
Looking at the documentation I see that I need a `aws_launch_configuration`
**Next steps:**
1. I insert a `resource "aws_launch_configuration" "example" {[CONFIG …]}` I find in the tutorial
2. I use the `image_id` as `ami` and `instance_type` from my previous `resource "aws_instance" "example"{[CONFIG …]}`
3. I see that I am missing a `security_groups` field. This will allow trafic and specific protocols to and from the ec2 instances.
4. I declare a `resource "aws_security_group" "instance" {[CONFIG …]}` with rules for tcp port 8080.
5. Now I am missing the actual `aws_autoscaling_group` resource.
>> `terraform apply` here creates the security group, and launch configuration but no instances are started
6. I get the resource `"aws_autoscaling_group" "example" {[CONFIG …]}` from the tutorial.
7. I run `terrafrom apply` and approve
8. **Error** `AutoScaling Group: ValidationError: At least one Availability Zone or VPC Subnet is required.`
9. Check the documentation, and add field `security_groups = [aws_security_group.instance.id]`
10. **SUCCESS** There are two ec2 instances running with the assigned inbound rules.
11. At this point I want to do a hack and test if the instances are accessible on port 8080.
12. I copy from the tutorial the following field and set it in `aws_launch_configuration`
```shell
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
```
This "hack" didn't work initially, but then I realised that my image is Linux and busybox is preinstalled on Ubuntu. I changed the `image_id` and applied again. Now I can `curl` any of the two instances and get back `Hello, World`. this gives me good motivation to keep on. I will leave the busybox there for the moment.

### Application Load Balancer
The tutorial explains how to setup a classic LB. 
My plan is to refer to the provisioners docs [here](https://www.terraform.io/docs/providers/aws/r/lb.html). Another idea is to check how can one do this manually as to figure out what are the dependencies between an ALB and an autoscalling group.
1. Declare the example usage from the documentation, and strip it down to minimum fields.
2. The example comes with fields set for `security_groups` & `subnets`. Both are optional according to documentation.
3. **I was wrong**I provide the id for the `resource "aws_security_group" "instance"{[CONFIG …]}` and remove the `subnets` field
4. `apply yes`
5. **Error** `Error: Error creating application Load Balancer: ValidationError: At least two subnets in two different Availability Zones must be specified`
6. SO apparently subnets are not optional in this case.
7. I refer to the tutorial and I need to bring in a datasource to get the list of subnets available to my VPC.
8. From the provider documentation I think something like this will do `aws_subnet_ids`
8. I take the chance and bring also a datasource for my available AZ, and provide it to the `aws_autoscaling_group`.

**STOP**
I think I am doing something wrong:
1. The security group I assigned to the ALB allows only tcp traffic on 8080.
2. I believe the ALB should be receiving traffic on port 80 from any public IP, and then point somehow to the autoscalling group.
3. The ALB needs two subnets from different AZs.
4. My autoscalling group is in the Default VPC which has three subnets, in two AZs.
5. Both of my instances are in the same subnet.

Also from a bit of browsing in the providers documentation I found the following:
1. `aws_autoscalling_group` has optional field `target_group_arns` that receives a list of `aws_alb_target_group` ARNs for use with ALB.
2. The AWS manual says also that an Autoscalling Group has to be attached to a target group when choosing ALB.
3. The target group must have a target type of instance.
4. Also looking at my setup at the moment, the root resource here is the Autoscalling Group. It holds dependecies towards the Launch Configuration and the AZs.
>> *How can I get a reference to the subnets from the Autoscalling Group?*
5. I can get the VPC from the Autoscalling Group, and from there I can get the subnets.
6. I make a datasource of type `aws_subnet_ids` and configure `vpc_id = "${aws_autoscaling_group.example.vpc_zone_identifier}"`
7. **Unfortunately** `NOTE: Some values are not always set and may not be available for interpolation.` in `aws_autoscalling_group`
8. I will do the hack and get the id of the default vpc for the region, and from that extract the subnet ids.
9. It is working, I have an ALB in the default VPC attached to all three subnets in 2 AZs.
10. I just read [this page](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html#application-load-balancer-components) about the different components of a ALB. This clears up some things. ![](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/images/component_architecture.png)

### Time for the Target Group:





# Provisioners, I shouldn't use them :)
[from the docs:]
(https://www.terraform.io/docs/provisioners/#passing-data-into-virtual-machines-and-other-compute-resources)
If you are building custom machine images, you can make use of the "user data" or "metadata" passed by the above means in whatever way makes sense to your application, by referring to your vendor's documentation on how to access the data at runtime.

This approach is required if you intend to use any mechanism in your cloud provider for automatically launching and destroying servers in a group, because in that case individual servers will launch unattended while Terraform is not around to provision them.