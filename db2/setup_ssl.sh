gsk8capicmd_64 -keydb -create -db "/keystore/server.kdb" -pw "ibm123" -stash
gsk8capicmd_64 -cert -create -db "/keystore/server.kdb" -pw "ibm123" -label "aurany" -dn "CN=aurany" -size 2048 -sigalg SHA256_WITH_RSA
gsk8capicmd_64 -cert -extract -db "/keystore/server.kdb" -pw "ibm123" -label "aurany" -target "/keystore/server.arm" -format ascii -fips
gsk8capicmd_64 -cert -details -db "/keystore/server.kdb" -pw "ibm123" -label "aurany"
db2 update dbm cfg using SSL_SVR_KEYDB /keystore/server.kdb
db2 update dbm cfg using SSL_SVR_STASH /keystore/server.sth
db2 update dbm cfg using SSL_SVCENAME 50002
db2 update dbm cfg using SSL_SVR_LABEL aurany
db2 update dbm cfg using ssl_versions TLSv12

db2set DB2COMM=SSL,TCPIP
db2stop force
db2start
