// Alpine version
variable "ALPINE_VERSION" {
  default = "3.19"
}

variable "PYTHON_VERSION" {
    default = "3.9.19"
}

variable "PYTHON_GPG_KEY" {
    default = "E3FF2839C048B25C084DEBE9B26995E310250568"
}

variable "PYTHON_PIP_VERSION" {
    default = "23.0.1"
}

variable "PYTHON_SETUPTOOLS_VERSION" {
    default = "65.5.1"
}

variable "PYTHON_GET_PIP_SHA256" {
    default = "45a2bb8bf2bb5eff16fdd00faef6f29731831c7c59bd9fc2bf1f3bed511ff1fe"
}

variable "ONBUILD_BASE_TAG" {
    default = "3.9"
}

variable "ECR_REGISTRY" {
    default = "915632791698.dkr.ecr.us-east-2.amazonaws.com"
}

variable "ECR_REPOSITORY" {
    default = "kinnontest/harnessbuild"
}

variable "S3_BUCKET" {
    default = "${S3_BUCKET}"
}
variable "AWS_REGION" {
    default = "${AWS_REGION}"
}
variable "AWS_ACCESS_KEY_ID" {
    default = "${AWS_ACCESS_KEY_ID}"
}
variable "AWS_SECRET_ACCESS_KEY" {
    default = "${AWS_SECRET_ACCESS_KEY}"
}
variable "AWS_SESSION_TOKEN" {
    default = "${AWS_SESSION_TOKEN}"
}

variable "PYTHON_GET_PIP_URL" {
    default = "https://github.com/pypa/get-pip/raw/9af82b715db434abb94a0a6f3569f43e72157346/public/get-pip.py"
}

target "onbuild-args" {
    args = {
        BASE_TAG = ONBUILD_BASE_TAG
        ECR_REGISTRY = ECR_REGISTRY
        ECR_REPOSITORY = ECR_REPOSITORY
    }
}

target "args" {
  args = {
    ALPINE_VERSION = ALPINE_VERSION
    PYTHON_VERSION = PYTHON_VERSION
    PYTHON_GPG_KEY = PYTHON_GPG_KEY 
    PYTHON_PIP_VERSION = PYTHON_PIP_VERSION 
    PYTHON_SETUPTOOLS_VERSION = PYTHON_SETUPTOOLS_VERSION   
    PYTHON_GET_PIP_SHA256 = PYTHON_GET_PIP_SHA256
    PYTHON_GET_PIP_URL = PYTHON_GET_PIP_URL
  }
}

target "platforms" {
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}

target "arm" {
  platforms = ["linux/arm64"]
}

target "amd64" {
  platforms = ["linux/amd64"]
}


// Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {
  tags = ["alpine-python:local"]
}

group "default" {
  targets = ["image-local", "onbuild-local", "onbuild-poetry-local"]
}

target "image" {
  inherits = ["args", "docker-metadata-action"]
  cache-to   = ["type=s3,bucket=${S3_BUCKET},region=${AWS_REGION},access_key_id=${AWS_ACCESS_KEY_ID},secret_access_key=${AWS_SECRET_ACCESS_KEY},session_token=${AWS_SESSION_TOKEN},mode=max"]
  cache-from = ["type=s3,bucket=${S3_BUCKET},region=${AWS_REGION},access_key_id=${AWS_ACCESS_KEY_ID},secret_access_key=${AWS_SECRET_ACCESS_KEY},session_token=${AWS_SESSION_TOKEN}"]
}

target "image-local" {
  inherits = ["args","image"]
  output = ["type=docker"]
}

target "image-local-arm" {
  inherits = ["args","image","arm"]
  output = ["type=docker"]
}

target "image-local-amd64" {
  inherits = ["args","image","amd64"]
  output = ["type=docker"]
}

target "image-all" {
  inherits = ["platforms", "image"]
}

target "onbuild" {
  inherits = ["onbuild-args", "platforms", "docker-metadata-action"]
  dockerfile = "Dockerfile.onbuild"
}

target "onbuild-poetry" {
  inherits = ["onbuild-args", "platforms", "docker-metadata-action"]
  dockerfile = "Dockerfile.onbuild-poetry"
}

target "onbuild-local" {
  tags = ["alpine-onbuild:local-onbuild"]
  inherits = ["onbuild-args"]
  dockerfile = "Dockerfile.onbuild"
  output = ["type=docker"]
}

target "onbuild-poetry-local" {
  tags = ["alpine-onbuild:local-onbuild-poetry"]
  inherits = ["onbuild-args"]
  dockerfile = "Dockerfile.onbuild-poetry"
  output = ["type=docker"]
}

