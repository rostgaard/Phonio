Phonio
======

Framework for interfacing with SIP phones. This framework is developed to 
enabled us to run automated tests on the OpenReception software stack. 

We currently targets SNOM SIP-phones (firmware v8+) and our own softphone[1]
that uses the PJSUA[2] library. 

# Caveats
This code should be considered experimental, and is only used for offline
testing of our software stack. Most of the logic is implemented ad-hoc and this
framework has no intentions of ever becoming "complete".

If, however, you in some way can find it useful, feedback and pull requests
are very welcome.

# References
 * [1] https://github.com/Bitstackers/OpenReception-Integration-Tests/tree/master/support_tools
 * [2] http://pjsip.org