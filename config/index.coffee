fs = require "fs"
path = require "path"
env = (name, defaultVal) ->
  val = process.env[name] or defaultVal
  throw new Error "'#{name}' is not optional; please configure your environment..." unless val?
  return val

IS_PROD = env("NODE_ENV", "development") is "production"
envForceProd = (name, defaultVal) ->
  throw new Error "'#{name}' must be set when in production mode!" if IS_PROD and (not process.env[name]?)
  return env(name, defaultVal)

tryFile = (pathToFile) ->
  resolvedPath = path.resolve pathToFile
  return unless fs.existsSync resolvedPath
  return fs.readFileSync(resolvedPath).toString()

KUBE_SECRET_PATH = env("KUBE_SECRET_PATH", "/var/run/secrets/kubernetes.io/serviceaccount")
module.exports = {
  IS_PROD

  ### Generic ###
  PERIOD_TO_POLL_SECONDS: parseInt env("PERIOD_TO_POLL_SECONDS", "60")

  ### Kubernetes ###
  KUBE_SECRET_PATH
  KUBE_API_URI: env("KUBE_API_URI", "https://" + envForceProd("KUBERNETES_SERVICE_HOST", "localhost"))
  KUBE_API_VERSION: env("KUBE_API_VERSION", "/api/v1")
  KUBE_AUTH_TOKEN: env("KUBE_AUTH_TOKEN", tryFile(KUBE_SECRET_PATH + "/token"))
  KUBE_STRICT_SSL: env("KUBE_STRICT_SSL", "true") is "true"

  ### AWS ECR ###
  AWS_ERC_REGION: env("AWS_ERC_REGION", "us-east-1")

  ### AWS S3 and Deployment Config Reference ###
  AWS_S3_REGION: env("AWS_S3_REGION", "us-east-1")

  # The location of the deployment config file
  S3_DEPLOYMENT_BUCKET: env("S3_DEPLOYMENT_BUCKET")
  S3_DEPLOYMENT_KEY: env("S3_DEPLOYMENT_KEY", "auto-deploy-spec.json")
}