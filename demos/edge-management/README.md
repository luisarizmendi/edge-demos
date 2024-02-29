


WORK IN PROGRESS.....





# Prepare the environment




1. Clone this repo



## OpenShift Hub cluster



order /install OCP



tested with 4.14


Blank Open Environment (example with AWS)


vi ~/.aws/credentials

[default]
aws_access_key_id = <keyid>
aws_secret_access_key = <access key>











cd <repo path>/demos/edge-management/infra/ocp/hub/

cp install-config.yaml.aws-template install-config.yaml

vi install-config.yaml


mkdir cluster

cp install-config.yaml cluster/





-> download `openshift-install` cli (tested 4.14) https://mirror.openshift.com/pub/openshift-v4/clients/ocp/

curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.14/openshift-install-linux.tar.gz
tar zxvf openshift-install-linux.tar.gz openshift-install
chmod +x openshift-install






./openshift-install create cluster --dir cluster/ --log-level=info




save your credentials 




back to <repo path>/demos/edge-management





## Base multicloud-gitops infrastructure



 https://validatedpatterns.io/patterns/multicloud-gitops/





fork https://github.com/validatedpatterns/multicloud-gitops


clone that repo





Configure let's encrypt


vi <demo repo path>/demos/edge-management/infra/multicluster-gitops/overrides/values-AWS.yaml

region: <region, example:eu-central-1>
email: iwashere@iwashere.com




copy contents

cp -r <demo repo path>/demos/edge-management/infra/multicluster-gitops/* <multicloud-gitops repo>/


git push <multicloud-gitops repo>






create the pattern

oc login -u kubeadmin api.hub.<domain>:6443

oc create -f <demo repo path>/demos/edge-management/infra/pattern-sub.yaml

wait

oc create -f <demo repo path>/demos/edge-management/infra/pattern.yaml



WAIT



back to <repo path>/demos/edge-management







*** if you want vault
 oc extract -n imperative secret/vaultkeys --to=- --keys=vault_data_json 2>/dev/null
 copy root_token






## Additional infrastructure












## Add configurations and content





