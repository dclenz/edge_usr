HPC in the Cloud
================
EDGE is able to run on cloud infrastructure.
Currently, the only tested service is the Google Cloud Platform (`GCP <https://cloud.google.com/compute/docs/>`_).

Google Cloud Platform
---------------------
The Google Cloud Platform (`GCP <https://cloud.google.com/compute/docs/>`_) offers a large set of available configurations.
In this section we a) consider the use case of a single instance, sufficient for shared memory parallel workloads,
and b) set up a Slurm-operated cluster, combining multiple nodes, ready for use of the Message Passing Interface (MPI).

Single Instance
^^^^^^^^^^^^^^^
1. The following command creates the instance edge-skx.
   The preemtible instance in the ``us-west1-b`` zone has four hyperthreads of the Skylake (SKX) generation or later, 10 GB of disk space, and a CentOS system.
   Additionally, we provide the scripts :edge_git:`install_tools.sh <tree/develop/tools/build/install_tools.sh>` and  :edge_git:`install_libs.sh <tree/develop/tools/build/install_libs.sh>` to the node-setup.
   In summary both scripts install all required tools and all of EDGE's dependencies system-wide:

   .. code-block:: bash

     gcloud compute instances create edge-skx \
           --zone=us-west1-b \
           --machine-type=n1-highcpu-4 \
           --subnet=default \
           --network-tier=PREMIUM \
           --no-restart-on-failure \
           --maintenance-policy=TERMINATE \
           --preemptible \
           --min-cpu-platform="Intel Skylake" \
           --image=family/centos-7 \
           --image-project=centos-cloud \
           --boot-disk-size=10GB \
           --boot-disk-type=pd-standard \
           --boot-disk-device-name=instance-1 \
           --metadata startup-script="bash <(curl -s https://raw.githubusercontent.com/3343/edge/develop/tools/build/install_tools.sh)
                                      source /etc/bashrc; bash <(curl -s https://raw.githubusercontent.com/3343/edge/develop/tools/build/install_libs.sh)"

   .. note::

    The size of the boot disk is chosen to be small, such that there is low overhead for saving an image from the instance.
    If you are planning on using the instance for computations, this should be increased.

2. Once created, the machine can be reached through:

   .. code-block:: bash

     gcloud compute ssh edge-skx

   It is best to wait for the start-up scripts to finish, before doing any additional work.
   The output of the scripts can be found in ``/var/log/messages``.
   On completion, GCP will print ``edge-skx startup-script: INFO Finished running startup scripts`` to the log-file.
   At this point, either re-login or source ``~/.bashrc``.

3. [Optional] We can use the instance to create a new disk image.
   This allows us to skip the startup-scripts, when creating new instances.
   A pre-configured image is, for example, crucial for the fast allocation of additional compute nodes from the cloud in a cluster-setting (see below).

   First, we have to stop the instance:

   .. code-block:: bash

     gcloud compute instances stop edge-skx
  
   Now, we can create the image ``edge-centos-7-181021`` as part of the ``edge-centos-7`` family from the stopped instance:

   .. code-block:: bash

     gcloud compute images create edge-centos-7-181021 \
            --source-disk edge-skx \
            --family edge-centos-7

4. The following command deletes the instance:

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
     Here, respective tools and libraries, as used in EDGE's workflows, are pre-installed system-wide (see Sec. `Single Instance`_).
     Note, that the Slurm controller instance is still using the GCP ``centos-7`` default, as Slurm requires its own sequential HDF5.
   * The cluster's config ``edge-cluster.yaml`` is pre-configured for capability computing with EDGE.
     It specifies "Intel Skylake" as minimum CPU platform for the compute instances.
     This is required to a) run AVX-512 instructions and b) request GCP's 48-core SKX nodes.
   * More aggressive suspend-times in ``scripts/startup-script.py``.

2. Adjust the machine configuration in ``edge-cluster.yaml`` to your needs.

   .. warning::

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

   Analogue to the single-instance case, we have to wait on the startup-scripts.
   Logs of the scripts are written to ``/var/log/messages``.
   Since we provide a pre-configured image to the login and compute instances, the Slurm installation on the controller instance is the most time-consuming part.
   When finished, as indicated by a broadcast to the instances, open a new session on the login node for proper initialization of your environment.

5. Run your simulations through Slurm, as you would on any other cluster.
   Use the OpenMPI ``-pernode``-flag to ensure, that each rank gets a single node.

   .. note::

     Dynamically allocated nodes are only released after idle times, specified through ``SuspendTime`` in the Slurm-config (see ``scripts/startup-script.py``).
     Further Details are available from the `Slurm documentation <https://slurm.schedmd.com/elastic_computing.html>`_.
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