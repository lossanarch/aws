#!/bin/bash

function usage {
    cat <<USAGE

Usage: initbackend.sh -r <region> -k <kms_encryption_key> [<optional params>]

Required params:
  -r	Region string	(ap-southeast-2, us-east-1, etc)
  -k	KMS Key		(this will be output by the backend creation if you're following the plan)


Optional params:

 ** None of these should be necessary - they will be computed based on pwd

  -a	Account Name
  -v	VPC Name
  -e    Environment Name
  -s    Service Name

USAGE
}

while getopts a:r:v:e:s:k: OPTION
do
    case "${OPTION}"
    in
    a) ACCOUNT=${OPTARG};;
    r) REGION=${OPTARG};;
    v) VPC=${OPTARG};;
    e) ENVIRONMENT=${OPTARG};;
    s) SERVICE=${OPTARG};;
    k) KMS_KEY=${OPTARG};;
    esac
done

if [[ ! ${REGION} ]]; then
    echo "No region provided (-r)"
    usage
    exit 1
fi

if [[ ! ${KMS_KEY} ]]; then
    echo "No key provided (-k)"
    usage
    exit 1
fi

if [[ ${REGION} == "$(pwd | awk -F "/" '{print $(NF-3)}')" ]]
then  # svc module
    ACCOUNT=$(pwd | awk -F "/" '{print $(NF-4)}')
    REGION=$(pwd | awk -F "/" '{print $(NF-3)}')
    VPC=$(pwd | awk -F "/" '{print $(NF-2)}')
    ENVIRONMENT=$(pwd | awk -F "/" '{print $(NF-1)}')
    SERVICE=$(pwd | awk -F "/" '{print $NF}')

elif [[ ${REGION} == "$(pwd | awk -F "/" '{print $(NF-2)}')" ]]
then  # env module
    ACCOUNT=$(pwd | awk -F "/" '{print $(NF-3)}')
    REGION=$(pwd | awk -F "/" '{print $(NF-2)}')
    VPC=$(pwd | awk -F "/" '{print $(NF-1)}')
    ENVIRONMENT=$(pwd | awk -F "/" '{print $(NF)}')

elif [[ ${REGION} == "$(pwd | awk -F "/" '{print $(NF-1)}')" ]]
then  # vpc module
    ACCOUNT=$(pwd | awk -F "/" '{print $(NF-2)}')
    REGION=$(pwd | awk -F "/" '{print $(NF-1)}')
    VPC=$(pwd | awk -F "/" '{print $(NF)}')

elif [[ ${REGION} == "$(pwd | awk -F "/" '{print $(NF)}')" ]]
then  # region module
    ACCOUNT=$(pwd | awk -F "/" '{print $(NF-1)}')

elif [[ ! ${ACCOUNT} ]]
then # account module
    ACCOUNT=$(pwd | awk -F "/" '{print $(NF)}')
fi

if [[ ! ${ACCOUNT} ]]; then
    echo "No account provided (-a) and could not ascertain from pwd"
    echo "WARNING! Are you running this from the correct place?"
    exit 1
fi

if [[ ${VPC} ]]; then
    BUCKET_PATH_PREFIX=${REGION}/${VPC}/
fi

if [[ ${ENVIRONMENT} ]]; then
    BUCKET_PATH_PREFIX=${REGION}/${VPC}/${ENVIRONMENT}/
fi

if [[ ${SERVICE} ]]; then
    BUCKET_PATH_PREFIX=${REGION}/${VPC}/${ENVIRONMENT}/${SERVICE}/
fi

cat > ./backend.tf <<FILE
terraform {
    backend "s3" {
        bucket         = "lossanarch-tf-backend"
        key            = "${BUCKET_PATH_PREFIX}terraform.tfstate"
        region         = "${REGION}"
        # kms_key_id     = "${KMS_KEY}"
        # encrypt        = true
        # dynamodb_table = "tf-backend-${ACCOUNT}"
    }
}
FILE

cat ./backend.tf
