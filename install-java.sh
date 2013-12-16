echo Install java

wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F" http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-linux-x64.bin
chmod u+x jdk-6u45-linux-x64.bin
./jdk-6u45-linux-x64.bin
sudo -E mv jdk1.6.0_45 /opt
sudo -E update-alternatives --install "/usr/bin/java" "java" "/opt/jdk1.6.0_45/bin/java" 1
sudo -E update-alternatives --install "/usr/bin/javac" "javac" "/opt/jdk1.6.0_45/bin/javac" 1
sudo -E update-alternatives --install "/usr/lib/mozilla/plugins/libjavaplugin.so" "mozilla-javaplugin.so" "/opt/jdk1.6.0_45/jre/lib/amd64/libnpjp2.so" 1
sudo -E update-alternatives --install "/usr/bin/javaws" "javaws" "/opt/jdk1.6.0_45/bin/javaws" 1

sudo -E update-alternatives --config java
sudo -E update-alternatives --config javac

 
export JAVA_HOME=/opt/jdk1.6.0_45/
echo "export JAVA_HOME=/opt/jdk1.6.0_45" | sudo -E tee -a /etc/bash.bashrc
