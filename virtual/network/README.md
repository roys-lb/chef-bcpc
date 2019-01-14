# bird-leaf-spine

## BGP Session and Network Map

### Switches

```
  S1:
    s1r1t1:
      local:
        asn: 4200858300
        ip: 172.16.1.0/31
      neigh:
        asn: 4200858211
        ip: 172.16.1.1/31
    s1r1t2:
      local:
        asn: 4200858300
        ip: 172.16.1.2/31
      neigh:
        asn: 4200858212
        ip: 172.16.1.3/31
    s1r2t1:
      local:
        asn: 4200858300
        ip: 172.16.1.4/31
      neigh:
        asn: 4200858221
        ip: 172.16.1.5/31
    s1r2t2:
      local:
        asn: 4200858300
        ip: 172.16.1.6/31
      neigh:
        asn: 4200858222
        ip: 172.16.1.7/31
    s1r3t1:
      local:
        asn: 4200858300
        ip: 172.16.1.8/31
      neigh:
        asn: 4200858231
        ip: 172.16.1.9/31
    s1r3t2:
      local:
        asn: 4200858300
        ip: 172.16.1.10/31
      neigh:
        asn: 4200858232
        ip: 172.16.1.11/31

  S2:
    s2r1t1:
      local:
        asn: 4200858300
        ip: 172.16.2.0/31
      neigh:
        asn: 4200858211
        ip: 172.16.2.1/31
    s2r1t2:
      local:
        asn: 4200858300
        ip: 172.16.2.2/31
      neigh:
        asn: 4200858212
        ip: 172.16.2.3/31
    s2r2t1:
      local:
        asn: 4200858300
        ip: 172.16.2.4/31
      neigh:
        asn: 4200858221
        ip: 172.16.2.5/31
    s2r2t2:
      local:
        asn: 4200858300
        ip: 172.16.2.6/31
      neigh:
        asn: 4200858222
        ip: 172.16.2.7/31
    s2r3t1:
      local:
        asn: 4200858300
        ip: 172.16.2.8/31
      neigh:
        asn: 4200858231
        ip: 172.16.2.9/31
    s2r3t2:
      local:
        asn: 4200858300
        ip: 172.16.2.10/31
      neigh:
        asn: 4200858232
        ip: 172.16.2.11/31
```

### Tors

```
  r1t1:
    s1r1t1
      local:
        asn: 4200858211
        ip: 172.16.1.1/31
      neigh:
        asn: 4200858300
        ip: 172.16.1.0/31
    s2r1t1:
      local:
        asn: 4200858211
        ip: 172.16.2.1/31
      neigh:
        asn: 4200858300
        ip: 172.16.2.0/31
    r1n1:
      local:
        asn: 4200858111
        ip: 10.129.1.1/28
      neigh:
        asn: 4200858000
        ip: 10.129.1.3/28

  r1t2:
    s1r1t2
      local:
        asn: 4200858212
        ip: 172.16.1.3/31
      neigh:
        asn: 4200858300
        ip: 172.16.1.2/31
    s2r1t2:
      local:
        asn: 4200858212
        ip: 172.16.2.3/31
      neigh:
        asn: 4200858300
        ip: 172.16.2.2/31
    r1n1:
      local:
        asn: 4200858112
        ip: 10.129.1.17/28
      neigh:
        asn: 4200858000
        ip: 10.129.1.19/28

  r2t1:
    s1r2t1
      local:
        asn: 4200858221
        ip: 172.16.1.5/31
      neigh:
        asn: 4200858300
        ip: 172.16.1.4/31
    s2r2t1:
      local:
        asn: 4200858221
        ip: 172.16.2.5/31
      neigh:
        asn: 4200858300
        ip: 172.16.2.4/31
    r2n1:
      local:
        asn: 4200858121
        ip: 10.129.2.1/28
      neigh:
        asn: 4200858000
        ip: 10.129.2.3/28

  r2t2:
    s1r2t2
      local:
        asn: 4200858222
        ip: 172.16.1.7/31
      neigh:
        asn: 4200858300
        ip: 172.16.1.6/31
    s2r2t2:
      local:
        asn: 4200858222
        ip: 172.16.2.7/31
      neigh:
        asn: 4200858300
        ip: 172.16.2.6/31
    r2n1:
      local:
        asn: 4200858122
        ip: 10.129.2.17/28
      neigh:
        asn: 4200858000
        ip: 10.129.2.19/28

  r3t1:
    s1r3t1
      local:
        asn: 4200858231
        ip: 172.16.1.9/31
      neigh:
        asn: 4200858300
        ip: 172.16.1.8/31
    s2r3t1:
      local:
        asn: 4200858231
        ip: 172.16.2.9/31
      neigh:
        asn: 4200858300
        ip: 172.16.2.8/31
    r3n1:
      local:
        asn: 4200858131
        ip: 10.129.3.1/28
      neigh:
        asn: 4200858000
        ip: 10.129.3.3/28

  r3t2:
    s1r3t2
      local:
        asn: 4200858232
        ip: 172.16.1.11/31
      neigh:
        asn: 4200858300
        ip: 172.16.1.10/31
    s2r3t2:
      local:
        asn: 4200858232
        ip: 172.16.2.11/31
      neigh:
        asn: 4200858300
        ip: 172.16.2.10/31
    r3n1:
      local:
        asn: 4200858132
        10.129.3.17/28
      neigh:
        asn: 4200858000
        10.129.3.19/28
```
