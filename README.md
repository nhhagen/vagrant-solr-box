# Vagrant Solr box

Box to get a Solr environment quickly up and running in a VM.

## Building and testing

1. Install [Vagrant](http://www.vagrantup.com/)
2. `vagarant up` (this will download prequisites and build manifoldcf in a VM)
3. `vagrant ssh`
4. `sudo service solr start`
5. Open http://localhost:8983 (on host)

Step 3 and 4 should be removed in the future.