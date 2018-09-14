# salt-formula-cis

## README will be improved soon

Sorry, no time to do much more with it just yet.

## Background Info

This is related to the SaltConf18 presentation available here,

https://github.com/colin-stubbs/saltconf18-presentation

## _modules/s3_custom.py

This custom hack on the standard modules/s3.py allows calls to s3.put to define custom headers.

This permits setting HTTP headers which in turn can be used to set S3 object metadata, including the HTTP Content-Type.

You want this if you want to say, set a HTML file sent to S3, as actually being Content-Type: text/HTML

The default is binary/octet-stream and this is what is currently set for any objects created using s3.put

Refer to: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectPUT.html

Issue: https://github.com/saltstack/salt/issues/49649
Pull request: https://github.com/saltstack/salt/pull/49656/commits
