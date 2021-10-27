bind = ['0.0.0.0:5000']

# Logging
accesslog = "/var/log/sltech/gunicorn/access.log"
errorlog = "/var/log/sltech/gunicorn/error.log"
loglevel = "info"  # for error log

# Worker configuration
workers = 3
worker_class = 'sync'  # TODO: I'd like it to be gevent but something is not working right.
timeout = 30
keepalive = 5  # behind load balancer
