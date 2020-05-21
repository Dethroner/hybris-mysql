#!/usr/bin/env bash

HYBRISDIR="/opt/hybris" 
HYBRISDB=hybrisDB
HYBRISDBUSERNAME=adb
HYBRISDBPASSWORD=123

apt update -y

echo "Installing wget.."
apt install wget -y

echo "Installing Java 8.."
cd /opt/
wget http://enos.itcollege.ee/~jpoial/allalaadimised/jdk8/jdk-8u241-linux-x64.tar.gz
tar xzf jdk-8u241-linux-x64.tar.gz
cd /opt/jdk1.8.0_241/
update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_241/bin/java 2
update-alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_241/bin/jar 2
update-alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_241/bin/javac 2
update-alternatives --set jar /opt/jdk1.8.0_241/bin/jar
update-alternatives --set javac /opt/jdk1.8.0_241/bin/javac
echo "Java Version: "
java -version
echo "Setting JAVA_HOME Variable.."
export JAVA_HOME=/opt/jdk1.8.0_241
echo "Settting JRE_HOME Variable..."
export JRE_HOME=/opt/jdk1.8.0_241/jre
echo "Setting PATH Variable"..
export PATH=$PATH:/opt/jdk1.8.0_241/bin:/opt/jdk1.8.0_241/jre/bin

echo "Copying the Hybris installatiion from from host to guest machine.."
echo "Creating Hybris home directory..."
mkdir $HYBRISDIR
cd $HYBRISDIR
cp /vagrant/HYBRISCOMM6600P_25-70003031.ZIP $HYBRISDIR/
echo "Installing Unzip..."
apt -y install unzip

echo "Unzipping the Hybris Installation.."
unzip HYBRISCOMM6600P_25-70003031.ZIP

echo "Removing the Hybris Installation zip file.."
rm HYBRISCOMM6600P_25-70003031.ZIP
echo "Changing into the bin/platform directory.."
cd $HYBRISDIR/hybris/bin/platform


echo "Update the project.properties file to disable the default hsqldb database.."
sed -i '235s/db.url=jdbc:hsqldb:file/#db.url=jdbc:hsqldb:file/' project.properties
sed -i '236s/db.driver=org.hsqldb.jdbcDriver/#db.driver=org.hsqldb.jdbcDriver/' project.properties
sed -i '237s/db.username=sa/#db.username=sa/' project.properties
sed -i '238s/db.password=/#db.password=/' project.properties
sed -i '239s/db.tableprefix=/#db.tableprefix=/' project.properties
sed -i '240s/hsqldb.usecachedtables=true/#hsqldb.usecachedtables=true/' project.properties

echo "Update the project.properties file to use MySQL and specific database credentials.."
sed -i '268s/#db/db/' project.properties
sed -i '268s/localhost/10.50.10.100/' project.properties
sed -i "268s/<dbname>/$HYBRISDB/" project.properties
sed -i '269s/#db/db/' project.properties
sed -i '270s/#db/db/' project.properties 
sed -i "270s/<username>/$HYBRISDBUSERNAME/" project.properties 
sed -i '271s/#db/db/' project.properties
sed -i "271s/<password>/$HYBRISDBPASSWORD/" project.properties 
sed -i '272s/#db/db/' project.properties
sed -i '273s/#mysql/mysql/' project.properties
sed -i '274s/#mysql/mysql/' project.properties

echo "Downloading and installing the MySQL Driver.."
cd /tmp
wget https://dev.mysql.com/get/mysql-connector-java-8.0.20.tar.gz
tar xzf mysql-connector-java-8.0.20.tar.gz
cp /tmp/mysql-connector-java-8.0.20/mysql-connector-java-8.0.20.jar $HYBRISDIR/hybris/bin/platform/lib/dbdriver

cat <<EOF | tee /opt/hybrisstart.sh
cd $HYBRISDIR/hybris/bin/platform
. ./setantenv.sh
ant clean all -Dinput.template=develop && ant initialize
./hybrisserver.sh
EOF
chmod +x /opt/hybrisstart.sh
