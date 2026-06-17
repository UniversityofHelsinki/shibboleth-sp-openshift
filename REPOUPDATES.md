## Repository updates (Quay.io repository)

**NOTE:** This guide is intended for someone who needs to 
rebuild the `httpd` and `shibd` images at `quay.io/tike/openshift-sp-*` repos.
If you are simply consuming these images with your own SP, 
you don't need to read further here.

### Prerequisities

All of the following:

* A linux host, _preferably RHEL9 or RHEL10 or equivalent with recent-ish supported podman_, with all of the following:
* A clone of this repository
* Tools installed and available:
    * podman
    * skopeo
    * jq
* Valid login to quay.io, with write access to both of following repos:
    * quay.io/tike/openshift-sp-httpd
    * quay.io/tike/openshift-sp-shibd
* Access and working test login credentials for following service hostnames (these need University of Helsinki VPN or internal network access):
    * https://shidb-poc-test.it.helsinki.fi
    * https://shibd-poc.it.helsinki.fi
* Valid login for University of Helsinki openshift clusters (test and prod) 
that has admin access to shibd-poc project.

### Procedure


0. Get into the linux host if you haven't already.
1. Clone the repository if you haven't already. 
2. Login to quay.io if you haven't already.
3. Run the first script:
    ```bash 
    ./build-push-next.sh
    ```
    This will build a new version for both httpd and shibd image with tags
    `:next` and `:prod-test`. This, in turn, will in some time cause the following
    to happen:
    1. ImageStream objects in shibd-poc project in both test and prod cluster will 
       update
    2. Trigger annotation will make a new rollout of the deployment that runs 
       the httpd and shibd in the `shibd-poc` project. 
       **Note**: This is a non-smooth rollout by design. If the new versions 
       of our images crash at startup, we want this to be a visible outage for 
       the PoC service! It's useful to be logged into the OpenShift clusters to 
       see how the rollout is progressing.
4. When you see the rollout has managed to get the `httpd-shibd-*` pod running 
    again, you need to test it works:
    1. Open a new private/incognito window in a browser
    2. Open  https://shidb-poc-test.it.helsinki.fi in that window
    3. Check that you can use your test login credentials to get in. 
       The page should have information about your Uid and HyGroupCN and 
       it should correspond what your test login user has been set up with.
       Also check that the text about JavaScript succeeding appears, 
       in green color.
    4. If the previous test succeeded, open 
    _a new tab in the same private/incognito window_ and navigate to 
    https://shibd-poc.it.helsinki.fi to see if it manages to login automatically
    as it should. Check the Uid and HyGroupCN at this page, too.
5. If all your tests in step 4 were success, you run the following scripts:
    ```bash
    ./promote-to-test.sh
    ./promote-to-prod.sh
    ```
6. You should then check what the tags view for the images looks like in quay.io. 
    You should now be done with updating the images. Congrats!

### TODO

All of this should be automated. Sorry about that.
