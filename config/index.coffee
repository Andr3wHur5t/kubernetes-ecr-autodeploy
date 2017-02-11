env = (name, defaultVal) ->
  val = process.env[name] or defaultVal
  throw new Error "'#{name}' is not optional, please configure your environment!" unless val?
  return val

IS_PROD = env("NODE_ENV", "development") is "production"
envForceProd = (name, defaultVal) ->
  throw new Error "'#{name}' must be set when in production mode!" if IS_PROD and (not process.env[name]?)
  return env(name, defaultVal)

module.exports = {
  IS_PROD

  ### Generic ###
  PERIOD_TO_POLL_SECONDS: parseInt env("PERIOD_TO_POLL_SECONDS", "10")

  ### Kubernetes ###
  KUBE_API_URI: envForceProd("KUBE_API_URI")
  KUBE_API_VERSION: env("KUBE_API_VERSION", "/api/v1")
  KUBE_AUTH_TOKEN: envForceProd("KUBE_AUTH_TOKEN")
  KUBE_STRICT_SSL: env("KUBE_STRICT_SSL", "true") is "true"

  ### AWS ECR ###
  AWS_ERC_REGION: env("AWS_ERC_REGION", "us-east-1")

  ### AWS S3 and Deployment Config Reference ###
  AWS_S3_REGION: env("AWS_S3_REGION", "us-east-1")

}