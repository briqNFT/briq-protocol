bind = ['0.0.0.0:5000']

# Logging
# For k8s, log to stdout/stderr
accesslog = "-"
errorlog = "-"
loglevel = "info"  # for error log

# Worker configuration
workers = 2
worker_class = 'uvicorn.workers.UvicornWorker'
timeout = 60
keepalive = 5  # behind load balancer
