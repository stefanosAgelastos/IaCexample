# Starting with the assignment

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
changed AMI to region specific Ubuntu AMI ami-052241f00f12a5cac

### point of doubt:

- "We are explicitly defining the default AWS config profile here to illustrate how Terraform accesses sensitive credentials."
- "Note: If you simply leave out AWS credentials, Terraform will automatically search for saved API credentials (for example, in ~/.aws/credentials) or IAM instance profile credentials. This option is much cleaner for situations where tf files are checked into source control or where there is more than one admin user."
- Details [here](https://aws.amazon.com/blogs/apn/terraform-beyond-the-basics-with-aws/)
- I understand that I could the profile field if there's only one user

## Initializing

`terraform init`
It recomends to provide version constrints. Will skip that atm.

```bash
Terraform has been successfully initialized!
```

## Aply changes

`terraform apply`
### Error with AWS credentials
```bash
error validating provider credentials: error calling sts:GetCallerIdentity: NoCredentialProviders: no valid providers in chain. Deprecated.
For verbose messaging see aws.Config.CredentialsChainVerboseError
```

### Trying to debug this error

I try:

```bash
ls ~/.aws
config credentials
```

I try

```bash
nano nano ~/.aws/credentials
[default]
aws_access_key_id = AKIARR7CRD7BJX7OBI42
```

I see the aws_secret_access_key is missing. I edit the `credentials` with nano
and now:

```bash
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
```bash
Error: Error launching source instance: InvalidAMIID.NotFound: The image id '[ami-2757f631]' does not exist
status code: 400, request id: e0429614-be7b-418e-b32b-1fe8ee199080
```

OKAY, wrong AMI.
changing `example.tf` and then `terraform apply`
### Error with AMI

```bash
Error: Error launching source instance: OptInRequired: In order to use this AWS Marketplace product you need to accept terms and subscribe. To do so please visit https://aws.amazon.com/marketplace/pp?sku=3k0ceqj6ojkn6anux1mozu3ih
status code: 401, request id: b5394b77-4825-40a6-beb6-43b026577e67
```
Wrong AMI again
### Error with AMI

```bash
Error: Error launching source instance: Unsupported: The requested configuration is currently not supported. Please check the documentation for supported configurations.
status code: 400, request id: f3669cc1-da7d-4f8a-8649-542d859b8e61

on example.tf line 6, in resource "aws_instance" "example":
6: resource "aws_instance" "example" {
```

Wrong instance type, changing to `instance_type = "t3.micro"`
and now:

```bash
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

´´´bash
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

## 

