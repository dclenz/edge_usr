HPC in the Cloud
================
EDGE is able to run on cloud infrastructure.
Currently, the tested services are the Amazon Web Services (`AWS <https://aws.amazon.com/>`_) and the Google Cloud Platform (`GCP <https://cloud.google.com/compute/docs/>`_).

Amazon Web Services
-------------------
The Amazon Web Services (AWS) have a `section <https://aws.amazon.com/hpc/>`_ for High Performance Computing (HPC).
As part of this effort, AWS develops the framework `ParallelCluster <https://aws-parallelcluster.readthedocs.io/en/latest/>`_, which can be used to deploy a custom HPC environment within AWS.
In this section, we will a) launch a single instance and create a disk image from this instance, and b) combine several compute nodes under the umbrella of ParallelCluster for use with EDGE.

Identity and Access Management (IAM) and SSH
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AWS has extensive Identity and Access Management (IAM) and security features.
These need to be configured, before we use the `AWS Command Line Interface <https://docs.aws.amazon.com/cli>`_ (CLI) to launch our instance in the following sections.
We define two policies, one for "end-users" of our compute infrastructure and one, which adds right for administration.
Additionally, we import a public ssh-key and generate a security group for ssh traffic to our generated resources.
In the following, everything will be set for the ``us-west-2`` zone.
If you are planning on using a different zone for your instances, e.g., ``us-east-2``, adjust the configurations accordingly.

1. Set appropriate right for the administrative AWS user, who will set up the computer resources.
   Further details on EC2 policies are available from the AWS `documentation <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ExamplePolicies_EC2.html>`_.

   .. code-block:: JSON

     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": "ec2:CreateSecurityGroup",
           "Resource": "*",
           "Condition": {
             "StringEquals": {
               "aws:RequestedRegion": "us-west-2"
             }
           }
         },
         {
           "Effect": "Allow",
           "Action": "ec2:AuthorizeSecurityGroupIngress",
           "Resource": "*",
           "Condition": {
             "StringEquals": {
               "aws:RequestedRegion": "us-west-2"
             }
           }
         }
       ]
     }

2. Set rights for the user, who will use the cloud resource through the AWS CLI.
   Also apply the policy to the administrator above:

   .. code-block:: JSON

     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": "ec2:Describe*",
           "Resource": "*"
         },
         {
           "Effect": "Allow",
           "Action": "ec2:RunInstances",
           "Resource": "*",
           "Condition": {
             "StringEquals": {
               "aws:RequestedRegion": "us-west-2"
             }
           }
         },
         {
           "Effect": "Allow",
           "Action": "ec2:TerminateInstances",
           "Resource": "*",
           "Condition": {
             "StringEquals": {
               "aws:RequestedRegion": "us-west-2"
             }
           }
         },
         {
           "Effect": "Allow",
           "Action": "ec2:CreateImage",
           "Resource": "*",
           "Condition": {
             "StringEquals": {
               "aws:RequestedRegion": "us-west-2"
             }
           }
         }
       ]
     }

3. Add the service-linked role for spot instance requests, to enable the use of spot instances for our cluster configuration.
   Details on the process are given in AWS EC2's `documentation <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#service-linked-roles-spot-instance-requests>`_.

4. Generate a public-private key pair for use with AWS and import it through the `AWS console <https://console.aws.amazon.com/console/home>`_.
   In the following, we assume that you used ``edge`` as the key name.

5. Create a security group in EC2 and enable ssh traffic (port 22) from our local IP address for instances, using the group.
   The following command creates the security group ``edge``:

   .. code-block:: bash

     aws ec2 create-security-group --description "Security group for use of EDGEs EC2 cloud resources." --group-name edge --region us-west-2
  
   Next, we add our local ip address to the security group ``edge``:

   .. code-block:: bash

     aws ec2 authorize-security-group-ingress --region us-west-2 --group-name edge --protocol tcp --port 22 --cidr $(ip route get 1 | awk '{print $NF;exit}')/32

6. For the cluster-setup, `assign <https://aws-parallelcluster.readthedocs.io/en/latest/iam.html>`_  the policy ``ParallelClusterUserPolicy`` to the users of ParallelCluster.

   .. note::

    ``ParallelClusterUserPolicy`` uses the undocumented template ``<PARALLELCLUSTER EC2 ROLE NAME>``, which has to be replaced accordingly.
    We will use ``edge-cluster`` as the name of the cluster, which means that the template has to be replaced by ``parallelcluster-edge-cluster-RootRole-*``.

   Further, create an EC2 IAM role and assign the policy ``ParallelClusterUserPolicy`` to the role.

Single Instance
^^^^^^^^^^^^^^^
We use the `AWS Command Line Interface <https://docs.aws.amazon.com/cli>`_ to launch an instance in the Elastic Compute Cloud (`EC2 <https://aws.amazon.com/ec2/>`_).
In the following, all commands will query the AWS Oregon region with the name ``us-west-2``.
If you are planning on switching to a `different region <https://docs.aws.amazon.com/general/latest/gr/rande.html>`_, this has to be replaced accordingly, e.g., by ``us-east-2`` for the Ohio region.

1. Find an appropriate Amazon Machine Image (`AMI <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html>`_), e.g., `CentOS <https://aws.amazon.com/mp/centos/>`_, `Amazon Linux 2 <https://aws.amazon.com/amazon-linux-2/>`_ or `Amazon Linux AMI <https://aws.amazon.com/amazon-linux-ami/>`_.
   In the region ``us-west-2``, the following command returns a recent image for Amazon Linux 2:

   .. code-block:: bash

     aws ec2 describe-images --owners self amazon --region us-west-2 --filters 'Name=name,Values=amzn2-ami-hvm-2.0.????????-x86_64-gp2' 'Name=state,Values=available'

   For later use in a cluster-setting (see Sec. :ref:`sec-cloud-parallel-cluster`), we use a `pre-configured Amazon Linux AMI image <https://github.com/aws/aws-parallelcluster/blob/master/amis.txt>`_ of the framework.
   In the next step, this is the CentOS 7 AMI with id ``ami-0e6916127d13e1757`` in the ``us-west-2`` region, obtained from `ParallelCluster <https://github.com/aws/aws-parallelcluster/blob/v2.0.2/amis.txt>`_.
   Update the id according to your region and to a possibly more recent version, matching your ParallelCluster-version.

2. Next, we launch a single spot ``c5.18xlarge`` instance, which runs on SKX with 36 cores, 144GiB of memory and a 30GB of root disk.
   Further, our instance uses the public ssh-key and security group ``edge``.

  .. code-block:: bash

    aws ec2 run-instances --image-id ami-0e6916127d13e1757 \
                          --block-device-mapping '[{ "DeviceName": "/dev/sda1","Ebs": {"VolumeSize": 30,"DeleteOnTermination": true} }]' \
                          --count 1 \
                          --instance-type c5.18xlarge \
                          --region us-west-2 \
                          --instance-market-options 'MarketType=spot' \
                          --security-group-ids edge \
                          --key-name edge

  We obtain the public ip of the instance, by using ``aws ec2 describe-instances`` with the returned instance-id of the command ``aws ec2 run-instances``.
  Together with the user ``centos`` for CentOS AMIs or ``ec2-user`` for Amazon Linux AMIs, you could now ssh into the machine and start using it.
  In the remaining steps, we assume that the id of the instance is available through the environment variable ``EDGE_AWS_ID`` and the public ip through ``EDGE_AWS_IP``.

  .. note::
    AWS `does not support <https://github.com/aws/aws-cli/issues/1777>`_ global queries for the status of running instances.
    We can, however, loop in bash through the regions and list the instances individually:

    .. code-block:: bash

      for region in $(aws ec2 describe-regions --region us-west-2 --output text | cut -f3)
      do
        echo "##### Region: ${region}"
        aws ec2 describe-instances --region $region
      done

  .. note::
    Certain HPC-specific VM optimizations in the scripts below are triggered by the type of the operating system and the number of hyperthreads.

3. [Optional] `Intel Parallel Studio XE <https://software.intel.com/en-us/parallel-studio-xe>`_ requires us to manually upload the installer for the tools script in the next step.

   First, `download <https://software.intel.com/en-us/parallel-studio-xe/choose-download>`_ the standard installer ("Customizable Package").
   This will generate the file ``parallel_studio_xe_*.tgz``.
   Additionally, download your license file, ending with ``.lic``.
   Assuming a CentOS 7 AMI, having user ``centos``, the uploads of the installer and license file to ``centos``'s home are given as:

   .. code-block:: bash

     scp ./parallel_studio_xe_*.tgz centos@${EDGE_AWS_IP}:~
     scp ./*.lic centos@${EDGE_AWS_IP}:~

   .. warning::

     The tool-installation script in the next step searches for the installer.
     If found, it will automatically accept the EULA of Intel Parallel Studio XE in ``silent.cfg`` and proceed with the installation.

4. This steps invokes the three scripts :edge_git:`install_tools.sh <tree/develop/tools/build/install_tools.sh>`,  :edge_git:`install_libs.sh <tree/develop/tools/build/install_libs.sh>`, :edge_git:`install_hpc.sh <tree/develop/tools/build/install_hpc.sh>` through ssh.
   The two scripts install required tools and libraries for use with EDGE:

   .. code-block:: bash

     ssh centos@${EDGE_AWS_IP} "bash <(curl -s https://raw.githubusercontent.com/3343/edge/develop/tools/build/install_tools.sh); \
                                source /etc/bashrc; \
                                bash <(curl -s https://raw.githubusercontent.com/3343/edge/develop/tools/build/install_libs.sh); \
                                source /etc/bashrc; \
                                bash <(curl -s https://raw.githubusercontent.com/3343/edge/develop/tools/build/install_hpc.sh); \
                                sudo /usr/local/sbin/ami_cleanup.sh"


5. [Optional] We use the instance of the previous steps to create a custom AMI with the name ``edge-centos-7``:

   .. code-block:: bash

     aws ec2 create-image --region us-west-2 \
                          --instance-id ${EDGE_AWS_ID} \
                          --description "AMI for EDGE, based on ParallelCluster's CentOS 7 AMI." \
                          --name edge-centos-7

  The command will generate an image id, e.g., ``ami-0416d8f35899991f2``, which can be inserted into new instances.

6. You can terminate the instance through its id and the command ``aws ec2 terminate-instances``:

   .. code-block:: bash

     aws ec2 terminate-instances --region us-west-2 --instance-ids ${EDGE_AWS_ID}

.. _sec-cloud-parallel-cluster:

ParallelCluster
^^^^^^^^^^

In this section we will use the AWS's `ParallelCluster <https://aws-parallelcluster.readthedocs.io>`_ to launch a `Slurm <https://slurm.schedmd.com>`_-controlled cluster in AWS.
Our final cluster will be ready for MPI-parallel workloads with EDGE.
Full-node instances as compute nodes, e.g., `c5.18xlarge <https://aws.amazon.com/ec2/instance-types/c5/>`_, are best suited as computational backbone for EDGE.

1. Install ParallelCluster through `pip <https://pip.pypa.io/en/stable/>`_:

   .. code-block:: bash

     pip install aws-parallelcluster

2. Create the configuration ``edge-cluster.aws``.
   The following shows an example, which uses 36-core SKX spot instances as compute nodes.
   The arguments ``TEMPLATE_VPC`` and ``TEMPLATE_SUBNET`` have to be replaced according to your AWS settings:

   .. code-block:: default

     ## parallelcluster config
     [global]
     cluster_template = default
     update_check = true
     sanity_check = true

     [aws]
     aws_region_name = us-west-2

     [aliases]
     ssh = ssh {CFN_USER}@{MASTER_IP} {ARGS}

     ## parallelcluster templates
     [cluster default]
     key_name = edge
     compute_instance_type = c5.18xlarge
     master_instance_type = c5.xlarge
     # don't spawn any compute instances by default
     initial_queue_size = 0
     # maximum number of instances
     max_queue_size = 16
     # allow down-scaling of the initial number of instances
     maintain_initial_size = false
     # use Slurm as a scheduler
     scheduler = slurm
     # use cheaper spot instances
     cluster_type = spot
     # limit price on spot instances
     spot_price = 2.0
     # use our pre-built AMI
     custom_ami = TEMPLATE_AMI
     # use CentOS 7, which is what we use for the custom ami
     base_os = centos7
     vpc_settings = public
     # 30 GB for our volumes
     master_root_volume_size = 30
     compute_root_volume_size = 30
     # create placement group with cluster deployment (increases network bandwidth)
     placement_group = DYNAMIC


     ## VPC Settings
     [vpc public]
     # default VPC, copied from aws ec2 describe-vpcs --region us-west-2
     vpc_id = TEMPLATE_VPC
     # default subnet, copied from aws ec2 describe-subnets --region us-west-2
     master_subnet_id = TEMPLATE_SUBNET

     ## scaling w.r.t. AWS
     [scaling custom]
     # if a node is idle for a minute, it gets released back to the cloud
     scaledown_idletime = 1

3. We launch the ParallelCluster ``edge-cluster`` via:

   .. code-block:: bash

     pcluster create --config edge-cluster.aws edge-cluster

4. Once created, ``pcluster`` will return the public ip of the master instance, which is our login node.
   We use standard key-based ``ssh`` to get into the machine, compile EDGE, and submit jobs through Slurm.

5. After we are done, the following commands deletes our ParallelCluster ``edge-cluster``:

   .. code-block:: bash

     pcluster delete --config edge-cluster.aws edge-cluster

Google Cloud Platform
---------------------
The Google Cloud Platform (`GCP <https://cloud.google.com/compute/docs/>`_) offers a large set of available configurations.
In this section we a) consider the use case of a single instance, sufficient for shared memory parallel workloads,
and b) set up a Slurm-operated cluster, combining multiple nodes, ready for use of the Message Passing Interface (MPI).

.. _sec-cloud-gcp-single:

Single Instance
^^^^^^^^^^^^^^^
1. The following command creates the instance ``edge-skx``.
   The preemptible instance in the ``us-west1-b`` zone has 96 hyperthreads of the Skylake (SKX) generation or later, 30GB of disk space, and a CentOS operating system.

   .. code-block:: bash

     gcloud compute instances create edge-skx \
           --zone=us-west1-b \
           --machine-type=n1-highcpu-96 \
           --subnet=default \
           --network-tier=PREMIUM \
           --no-restart-on-failure \
           --maintenance-policy=TERMINATE \
           --preemptible \
           --min-cpu-platform="Intel Skylake" \
           --image=family/centos-7 \
           --image-project=centos-cloud \
           --boot-disk-size=30GB \
           --boot-disk-type=pd-standard \
           --boot-disk-device-name=edge-skx-1

   Once created, the machine can be reached through:

   .. code-block:: bash

     gcloud compute ssh edge-skx

   .. note::

     The size of the boot disk is chosen to be small, such that there is low overhead for saving an image from the instance.
     If you are planning on using the instance for computations, this should be increased.

2. `Intel Parallel Studio XE <https://software.intel.com/en-us/parallel-studio-xe>`_ requires us to manually upload the installer for the tools script in the next step.
   First, `download <https://software.intel.com/en-us/parallel-studio-xe/choose-download>`_ the standard installer ("Customizable Package").
   This will generate the file ``parallel_studio_xe_*.tgz``.
   Additionally, download your license file, ending with ``.lic``.
   The uploads of the installer and license file are given as:

   .. code-block:: bash

     gcloud compute scp ./parallel_studio_xe_*.tgz edge-skx:~
     gcloud compute scp ./*.lic edge-skx:~

   .. warning::

     The tool-installation script in the next step searches for the installer.
     If found, it will automatically accept the EULA of Intel Parallel Studio XE in ``silent.cfg`` and proceed with the installation.

3. Next, we install tools and libraries for use with EDGE.
   For this, we call the scripts :edge_git:`install_tools.sh <tree/develop/tools/build/install_tools.sh>` and  :edge_git:`install_libs.sh <tree/develop/tools/build/install_libs.sh>` through ssh:
  
   .. code-block:: bash

     gcloud compute ssh edge-skx --command "bash <(curl -s https://raw.githubusercontent.com/3343/edge/develop/tools/build/install_tools.sh); \
                                            source /etc/bashrc; \
                                            bash <(curl -s https://raw.githubusercontent.com/3343/edge/develop/tools/build/install_libs.sh); \
                                            source /etc/bashrc; \
                                            bash <(curl -s https://raw.githubusercontent.com/3343/edge/develop/tools/build/install_hpc.sh);"

4. [Optional] We can use the instance to create a new disk image.
   This allows us to skip the install scripts, when creating new instances.
   First, we have to stop the instance:

   .. code-block:: bash

     gcloud compute instances stop edge-skx
  
   Now, we create the image ``edge-centos-7-181030`` as part of the ``edge-centos-7`` family from the stopped instance:

   .. code-block:: bash

     gcloud compute images create edge-centos-7-181030 \
            --source-disk edge-skx \
            --family edge-centos-7

5. The following command deletes the instance:

   .. code-block:: bash

     gcloud compute instances delete edge-skx

Slurm Cluster
^^^^^^^^^^^^^
This section describes the required steps to start a preconfigured high performance computing cluster for use with EDGE.
Further information is available from Google's `Codelabs <https://codelabs.developers.google.com>`_, which provides an `introduction <https://codelabs.developers.google.com/codelabs/hpc-slurm-on-gcp/>`_ to Slurm in GCP.

1. Download `EDGE's Slurm deployment configuration <https://github.com/3343/slurm-gcp>`_ for GCP:

   .. code-block:: bash

     git clone https://github.com/3343/slurm-gcp.git
     cd slurm-gcp

   The configuration is slightly different from the `default <https://github.com/SchedMD/slurm-gcp>`_:

   * It uses an image from the custom CentOS family ``edge-centos-7`` for the login and compute instances.
     ``edge-centos-7`` extends GCP's default ``centos-7`` family from the ``centos-cloud``.
     Here, respective tools and libraries, as used in EDGE's workflows, are pre-installed system-wide (see Sec. :ref:`sec-cloud-gcp-single`).
     Note, that the Slurm controller instance is still using the GCP ``centos-7`` default, as Slurm requires its own sequential HDF5.
   * The cluster's config ``edge-cluster.yaml`` is pre-configured for capability computing with EDGE.
     It specifies "Intel Skylake" as minimum CPU platform for the compute instances.
     This is required to a) run AVX-512 instructions and b) request GCP's 48-core SKX nodes.
   * More aggressive suspend-times in ``scripts/startup-script.py``.

2. Adjust the machine configuration in ``edge-cluster.yaml`` to your needs.

   .. note::

     The parameter ``slurm_version`` is a source for errors, since the startup-script silently fails, if a not-available version is provided.
     In that case, the MOTD on the nodes gets stuck at:

     .. code-block:: bash

       *** Slurm is currently being installed/configured in the background. ***
       A terminal broadcast will announce when installation and configuration is complete.

     If the installation is still ongoing, respective binaries (compiler, shell scripts) show up in ``top`` on the controller instance and log-messages in ``/var/log/messages``.
     At the time of writing, 18.08.2 had to be provided as version string.

3. Start the cluster by running:

   .. code-block:: bash

     gcloud deployment-manager deployments create edge-cluster --config edge-cluster.yaml

4. Log in to the cluster's login instance via:

   .. code-block:: bash

     gcloud compute ssh edge-cluster-login1

   We have to wait on the startup-scripts of the Slurm environment.
   Logs of the scripts are written to ``/var/log/messages``.
   Since we provide a pre-configured image to the login and compute instances, the Slurm installation on the controller instance is the most time-consuming part.
   When finished, as indicated by a broadcast to the instances, open a new session on the login node for proper initialization of your environment.

   .. note::

     If you login to the cluster before the NFS-home directory is mounted, your system-generated home will be overwritten.
     The command ``sudo mkhomedir_helper $(whoami)`` creates an NFS-home for your user.

5. Run your simulations through Slurm, as you would on any other cluster.

   .. note::

     Dynamically allocated nodes are only released after idle times, specified through ``SuspendTime`` in the Slurm-config (see ``scripts/startup-script.py``).
     Further details are available from the `Slurm documentation <https://slurm.schedmd.com/elastic_computing.html>`_.
     By invoking the script ``scripts/suspend.py``, you can manually release dynamically allocated instances back to the cloud.
     This is done through the following Slurm command, here applied to the five Slurm-nodes ``edge-cluster-compute[1-5]``:

     .. code-block:: bash

       sudo scontrol update NodeName=edge-cluster-compute[1-5] State=POWER_DOWN

6. Once finished with the computations, you can delete the cluster via:

   .. code-block:: bash

     gcloud deployment-manager deployments delete edge-cluster

   .. warning::

     Dynamically allocated compute instances, are not destroyed by deleting the cluster.
     Double-check `GCP's console <https://console.cloud.google.com>`_ to ensure that all resource have been released.