# kubernetes-ecr-autodeploy

Kubernetes replication controller and AWS ECR auto deploy image.

## Quick Start

1. Create S3 Bucket
2. Populate with your auto-deploy-config
3. Create AMI
4. Set secrets using created AMI
5. Deploy Image Using Config

## Config Info

The deployment config file looks like this; It should be stored on S3 and will be checked every tick.

```json
{
  "updatedAt": "2-10-2017",
  "deployTargets": [
    {
      "friendlyName": "Your Application",
      "comments": "Will be used for UI later; builds expected to have incrementing numbers ie `build123` and `build124`",
      "fromEcr": {
        "repositoryName": "your-ecr-repo-name",
        "whereMatches": "build(\\d*)"
      },
      "toReplicationController": {
        "namespace": "default",
        "rcName": "your-replication-controller-name",
        "targetContainer": "your-template-container-name"
      }
    }
  ]
}
```


>> TODO: Explain all properties.