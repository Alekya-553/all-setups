#!/bin/bash

# Update packages
dnf update -y

# Install Java 21
dnf install java-21-amazon-corretto -y

# Verify Java
java -version

# Create tomcat user
useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat

# Download Tomcat
cd /tmp
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.122/bin/apache-tomcat-9.0.122.tar.gz

# Extract Tomcat
mkdir -p /opt/tomcat
tar -xzf apache-tomcat-9.0.122.tar.gz -C /opt/tomcat --strip-components=1

# Permissions
chown -R tomcat:tomcat /opt/tomcat
chmod +x /opt/tomcat/bin/*.sh

# Configure Manager Users
cat > /opt/tomcat/conf/tomcat-users.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
    <role rolename="manager-gui"/>
    <role rolename="manager-script"/>
    <role rolename="admin-gui"/>
    <role rolename="admin-script"/>

    <user username="tomcat"
          password="Admin@123!"
          roles="manager-gui,manager-script,admin-gui,admin-script"/>
</tomcat-users>
EOF

# Allow access to Manager from any IP
cat > /opt/tomcat/webapps/manager/META-INF/context.xml <<'EOF'
<Context antiResourceLocking="false" privileged="true">
</Context>
EOF

cat > /opt/tomcat/webapps/host-manager/META-INF/context.xml <<'EOF'
<Context antiResourceLocking="false" privileged="true">
</Context>
EOF

# Create systemd service
cat > /etc/systemd/system/tomcat.service <<'EOF'
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment=JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Enable Tomcat
systemctl enable tomcat

# Start Tomcat
systemctl start tomcat

# Status
systemctl status tomcat --no-pager

# Open firewall if firewalld is running
systemctl is-active firewalld >/dev/null 2>&1 && firewall-cmd --permanent --add-port=8080/tcp
systemctl is-active firewalld >/dev/null 2>&1 && firewall-cmd --reload

echo "Tomcat Installation Completed"
echo "URL: http://SERVER-IP:8080"
echo "Manager: http://SERVER-IP:8080/manager/html"
echo "Username: tomcat"
echo "Password: Admin@123!"
