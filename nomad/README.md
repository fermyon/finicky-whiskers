# Nomad job for finicky-whiskers

The job will create two allocations executing spin http triggers and one
allocation for the morsel event queue backed by redis.

The redis instance runs on static port 6379.

```
nomad run finicky-whiskers.nomad
```

Access the website at [http://finicky-whiskers.local.fermyon.link:8088](http://finicky-whiskers.local.fermyon.link:8088).  Use the port that traefik is listening on.
