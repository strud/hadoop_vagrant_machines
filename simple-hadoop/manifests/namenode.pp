# -*- mode: ruby -*-

package { 'libnss-mdns':
	ensure  => present,
}

group { 'puppet':
	ensure => present,
}

package { 'curl':
	ensure => present,
}

exec { 'extract-jre': 
	command => '/bin/tar -C /opt -xzf /vagrant/jre-7*.tar.gz',
	path    => '/usr/local/bin/:/bin/:/usr/bin/',
}

exec { 'link-jre': 
	command => '/bin/ln -s /opt/jre1* /opt/jre7',
	path    => '/usr/local/bin/:/bin/:/usr/bin/',
	creates => '/opt/jre7',
	require => Exec['extract-jre']
}

exec { 'extract-jdk': 
	command => '/bin/tar -C /opt -xzf /vagrant/jdk-7*.tar.gz',
	path    => '/usr/local/bin/:/bin/:/usr/bin/',
}

exec { 'link-jdk': 
	command => '/bin/ln -s /opt/jdk1* /opt/jdk7',
	path    => '/usr/local/bin/:/bin/:/usr/bin/',
	creates => '/opt/jdk7',
	require => Exec['extract-jdk']
}

file { '/usr/lib/jvm':
	ensure  => directory,
	require => Exec['link-jdk']
}

exec { 'link-default-java': 
	command => 'ln -s /opt/jdk7 /usr/lib/jvm/default-java',
	path    => '/usr/local/bin/:/bin/:/usr/bin/',
	creates => '/usr/lib/jvm/default-java',
	require => File['/usr/lib/jvm']
}

file { '/etc/profile.d/java.sh':
	ensure  => present,
	mode    => '0755',
	source  => '/vagrant/manifests/java.sh',
	require => Exec['link-jdk']
}

file { '/etc/apt/sources.list.d/cloudera.list':
	ensure => present,
	source => '/vagrant/manifests/cloudera.list',
}

exec { 'add-clouderakey':
	command => 'curl -s http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh/archive.key | sudo apt-key add - && /usr/bin/apt-get update && touch /tmp/ckey-added',
	path    => '/usr/local/bin/:/bin/:/usr/bin/',
	creates => '/tmp/ckey-added',
	require => [ Package['curl'], File['/etc/apt/sources.list.d/cloudera.list'] ],
}

package { 'hadoop-hdfs-namenode':
        ensure  => present,
        require => Exec['add-clouderakey'],
}

package { 'hadoop-0.20-mapreduce-jobtracker':
        ensure  => present,
        require => Exec['add-clouderakey'],
}

package { 'hadoop-client':
        ensure  => present,
        require => Exec['add-clouderakey'],
}

file { '/etc/hosts':
	ensure => present,
	source => '/vagrant/manifests/hosts',
}

file { '/etc/hadoop/conf/core-site.xml':
	ensure  => present,
	source  => '/vagrant/manifests/core-site.xml',
	require => Package['hadoop-hdfs-namenode', 'hadoop-0.20-mapreduce-jobtracker'],
}

file { '/etc/hadoop/conf/mapred-site.xml':
	ensure  => present,
	source  => '/vagrant/manifests/mapred-site.xml',
	require => Package['hadoop-hdfs-namenode', 'hadoop-0.20-mapreduce-jobtracker'],
}

file { '/etc/hadoop/conf/hdfs-site.xml':
	ensure  => present,
	source  => '/vagrant/manifests/hdfs-site.xml',
	require => Package['hadoop-hdfs-namenode', 'hadoop-0.20-mapreduce-jobtracker'],
}

file { '/data':
	ensure => directory,
	owner  => 'hdfs',
	group  => 'hdfs',
	require => Package['hadoop-hdfs-namenode'],
}

file { '/data/hdfs':
	ensure => directory,
	owner  => 'hdfs',
	group  => 'hdfs',
	require => File['/data'],
}	

file { '/data/hdfs/namenode':
	ensure  => directory,
	owner  => 'hdfs',
	group  => 'hdfs',
	require => File['/data/hdfs'],
}	

file { '/data/hdfs/datanode':
	ensure  => directory,
	owner  => 'hdfs',
	group  => 'hdfs',
	require => File['/data/hdfs'],
}	

exec { 'format-namenode':
	command => '/usr/bin/hdfs namenode -format && touch /tmp/formatted',
	path    => '/usr/local/bin/:/bin/:/usr/bin/',
	creates => '/tmp/formatted',
	user    => 'hdfs',
	require => [ File['/etc/hosts', '/etc/hadoop/conf/core-site.xml', '/etc/hadoop/conf/mapred-site.xml', '/etc/hadoop/conf/hdfs-site.xml', '/data/hdfs/namenode'], Package['hadoop-hdfs-namenode'] ],
}

service { 'hadoop-hdfs-namenode':
	ensure  => running,
	require => Exec['format-namenode'],
}

service { 'hadoop-0.20-mapreduce-jobtracker':
	ensure  => running,
	require => [ Service['hadoop-hdfs-namenode'], Package['hadoop-hdfs-namenode', 'hadoop-0.20-mapreduce-jobtracker'] ],
}
